public with sharing class Timeline_Queries {
    // --------------------------------------------------- //
    // --------------- getSObjectsToQuery ---------------- //
    // --------------------------------------------------- //

    public static List<TimelineParent__mdt> getSObjectsToQuery(
        String parentSObjectType,
        Boolean isCreateable,
        String appName
    ) {
        String query = Timeline_QueriesHelper.getMetadataQuery(isCreateable, appName);
        List<TimelineParent__mdt> sObjectsToQuery = Database.query(query);

        // if appName is set, but couldn't find any results for it, try again without app name set
        if (sObjectsToQuery.isEmpty() && appName != null) {
            return getSObjectsToQuery(parentSObjectType, isCreateable, null);
        }

        // if empty, throw error
        if (sObjectsToQuery.isEmpty()) {
            throw new AuraException(Label.Timeline_NotConfugred);
        }

        // check if all fetched objects are accessible
        List<TimelineParent__mdt> sObjectsToUse = Timeline_Helper.checkObjectAccess(isCreateable, sObjectsToQuery);

        return sObjectsToUse;
    }

    // --------------------------------------------------- //
    // ---------------- createSoqlQueries ---------------- //
    // --------------------------------------------------- //

    public static List<String> createSoqlQueries(
        List<TimelineParent__mdt> sObjectsToQuery,
        String recordId,
        Integer amountOfMonths,
        Integer recordLimit
    ) {
        Set<String> queriedSobjects = new Set<String>();
        List<String> queries = new List<String>();
        Map<String, Id> recordTypesMap = Timeline_Helper.getRecordTypes(sObjectsToQuery);
        String recordTypeId = '';

        for (TimelineParent__mdt mdt : sObjectsToQuery) {
            // only query an sobject once
            if (!queriedSobjects.contains(mdt.Timeline_Child__r.SObjectName__c + mdt.SObjectRelationshipField__c + mdt.Timeline_Child__r.CreateableObject_RecordType__c)) {
                if (String.isNotBlank(mdt.Timeline_Child__r.CreateableObject_RecordType__c)) {
                    recordTypeId = recordTypesMap.get(mdt.Timeline_Child__r.SObjectName__c + mdt.Timeline_Child__r.CreateableObject_RecordType__c);
                }
                queries.add(Timeline_QueriesHelper.getQuery(sObjectsToQuery, mdt, recordId, amountOfMonths, recordTypeId, recordLimit));
                queriedSobjects.add(mdt.Timeline_Child__r.SObjectName__c + mdt.SObjectRelationshipField__c + mdt.Timeline_Child__r.CreateableObject_RecordType__c);
                recordTypeId = '';
            }
        }

        return queries;
    }

    // --------------------------------------------------- //
    // ------------- getSObjectsFromQueries -------------- //
    // --------------------------------------------------- //

    public static List<SObject> getSObjectsFromQueries(List<String> queries) {
        List<SObject> sObjects = new List<SObject>();
        Map<Id, SObject> uniqueSObjects = new Map<Id, SObject>();

        for (String query : queries) {
            List<SObject> sObjs = Database.query(query);
            sObjects.addAll(sObjs);
            for (SObject sObj : sObjs) {
                // Added to remove duplicates
                uniqueSObjects.put(sObj.Id, sObj);
            }
        }

        return uniqueSObjects.values();
    }

    // --------------------------------------------------- //
    // ----------------- getOverdueQuery ----------------- //
    // --------------------------------------------------- //

    public static List<String> getOverdueQuery(List<TimelineParent__mdt> sObjectsToQuery, String recordId) {
        TimelineParent__mdt mdt = sObjectsToQuery[0];

        String fields = Timeline_QueriesHelper.getQueryFields(sObjectsToQuery, mdt);
        String dateField = mdt.Timeline_Child__r.SObjectDateField__c;
        String now = Timeline_QueriesHelper.getTime(mdt.Timeline_Child__r.SObjectDateFieldIsDate__c);

        String query =
            ' SELECT ' +
            fields +
            ' FROM ' +
            mdt.Timeline_Child__r.SObjectName__c +
            ' WHERE ' +
            mdt.SObjectRelationshipField__c +
            ' = \'' +
            recordId +
            '\' AND ' +
            'TaskSubType != \'Email\'' +
            ' AND (' +
            dateField +
            ' < ' +
            now +
            ' AND Status != \'Completed\')' +
            ' ORDER BY ' +
            dateField;

        return new List<String>{ query };
    }

    // --------------------------------------------------- //
    // ----------------- getTotalRecords ----------------- //
    // --------------------------------------------------- //

    public static Integer getTotalRecords(List<TimelineParent__mdt> sObjectsToQuery, String recordId) {
        List<String> queries = new List<String>();
        Set<String> queriedSobjects = new Set<String>();
        Map<String, Id> recordTypesMap = Timeline_Helper.getRecordTypes(sObjectsToQuery);
        String recordTypeId = '';

        for (TimelineParent__mdt mdt : sObjectsToQuery) {
            if (!queriedSobjects.contains(mdt.Timeline_Child__r.SObjectName__c + mdt.SObjectRelationshipField__c + mdt.Timeline_Child__r.CreateableObject_RecordType__c)) {
                String fields = 'Id';
                String sObjectType = mdt.Timeline_Child__r.SObjectName__c;
                String parameter = mdt.SObjectRelationshipField__c + ' = \'' + recordId + '\'';

                if (mdt.Timeline_Child__r.SObjectName__c == 'Task') {
                    parameter += ' AND TaskSubType != \'Email\'';
                }
                if (String.isNotBlank(mdt.Timeline_Child__r.CreateableObject_RecordType__c)) {
                    recordTypeId = recordTypesMap.get(mdt.Timeline_Child__r.SObjectName__c + mdt.Timeline_Child__r.CreateableObject_RecordType__c);
                    parameter += ' AND RecordTypeId = \'' + recordTypeId + '\'';
                }
                parameter += ' GROUP BY Id';

                queries.add(Timeline_QueriesHelper.buildSoqlQuery(fields, sObjectType, parameter, null));
                queriedSobjects.add(mdt.Timeline_Child__r.SObjectName__c + mdt.SObjectRelationshipField__c + mdt.Timeline_Child__r.CreateableObject_RecordType__c);
                recordTypeId = '';
            }
        }

        Integer count = 0;

        for (String query : queries) {
            List<AggregateResult> results = Database.query(query);
            count += results.size();
        }

        return count;
    }
}
