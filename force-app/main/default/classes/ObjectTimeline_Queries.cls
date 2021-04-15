public with sharing class ObjectTimeline_Queries {
    // --------------------------------------------------- //
    // --------------- getSObjectsToQuery ---------------- //
    // --------------------------------------------------- //

    public static List<ObjectTimelineParent__mdt> getSObjectsToQuery(
        String parentSObjectType,
        Boolean isCreateable,
        String appName
    ) {
        String query = ObjectTimeline_QueriesHelper.getMetadataQuery(isCreateable, appName);
        List<ObjectTimelineParent__mdt> sObjectsToQuery = Database.query(query);

        // if appName is set, but couldn't find any results for it, try again without app name set
        if (sObjectsToQuery.isEmpty() && appName != null) {
            return getSObjectsToQuery(parentSObjectType, isCreateable, null);
        }

        // if empty, throw error
        if (sObjectsToQuery.isEmpty()) {
            throw new AuraException(Label.ObjectTimeline_NotConfugred);
        }

        // check if all fetched objects are accessible
        List<ObjectTimelineParent__mdt> sObjectsToUse = ObjectTimeline_Helper.checkObjectAccess(
            isCreateable,
            sObjectsToQuery
        );

        return sObjectsToUse;
    }

    // --------------------------------------------------- //
    // ---------------- createSoqlQueries ---------------- //
    // --------------------------------------------------- //

    public static List<String> createSoqlQueries(
        List<ObjectTimelineParent__mdt> sObjectsToQuery,
        String recordId,
        Integer amountOfMonths
    ) {
        Set<String> queriedSobjects = new Set<String>();
        List<String> queries = new List<String>();

        for (ObjectTimelineParent__mdt mdt : sObjectsToQuery) {
            // only query an sobject once
            if (!queriedSobjects.contains(mdt.Object_Timeline_Child__r.SObjectName__c)) {
                queries.add(ObjectTimeline_QueriesHelper.getQuery(sObjectsToQuery, mdt, recordId, amountOfMonths));
                queriedSobjects.add(mdt.Object_Timeline_Child__r.SObjectName__c);
            }
        }

        return queries;
    }

    // --------------------------------------------------- //
    // ------------- getSObjectsFromQueries -------------- //
    // --------------------------------------------------- //

    public static List<SObject> getSObjectsFromQueries(List<String> queries) {
        List<SObject> sObjects = new List<SObject>();

        for (String query : queries) {
            System.debug('query: ' + query);
            List<SObject> sObjs = Database.query(query);
            sObjects.addAll(sObjs);
        }

        return sObjects;
    }

    // --------------------------------------------------- //
    // ----------------- getOverdueQuery ----------------- //
    // --------------------------------------------------- //

    public static List<String> getOverdueQuery(List<ObjectTimelineParent__mdt> sObjectsToQuery, String recordId) {
        ObjectTimelineParent__mdt mdt = sObjectsToQuery[0];

        String fields = ObjectTimeline_QueriesHelper.getQueryFields(sObjectsToQuery, mdt);
        String dateField = mdt.Object_Timeline_Child__r.SObjectDateField__c;
        String now = ObjectTimeline_QueriesHelper.getTime(mdt.Object_Timeline_Child__r.SObjectDateFieldIsDate__c);

        String query =
            ' SELECT ' +
            fields +
            ' FROM ' +
            mdt.Object_Timeline_Child__r.SObjectName__c +
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

    public static Integer getTotalRecords(List<ObjectTimelineParent__mdt> sObjectsToQuery, String recordId) {
        List<String> queries = new List<String>();
        Set<String> queriedSobjects = new Set<String>();

        for (ObjectTimelineParent__mdt mdt : sObjectsToQuery) {
            if (!queriedSobjects.contains(mdt.Object_Timeline_Child__r.SObjectName__c)) {
                String fields = 'Count()';
                String sObjectType = mdt.Object_Timeline_Child__r.SObjectName__c;
                String parameter = mdt.SObjectRelationshipField__c + ' = \'' + recordId + '\'';

                if (mdt.Object_Timeline_Child__r.SObjectName__c == 'Task') {
                    parameter += ' AND TaskSubType != \'Email\'';
                }

                queries.add(ObjectTimeline_QueriesHelper.buildSoqlQuery(fields, sObjectType, parameter, null));
                queriedSobjects.add(mdt.Object_Timeline_Child__r.SObjectName__c);
            }
        }

        Integer count = 0;

        for (String query : queries) {
            count += Database.countQuery(query);
        }

        return count;
    }
}
