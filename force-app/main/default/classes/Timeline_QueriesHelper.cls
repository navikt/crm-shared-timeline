public with sharing class Timeline_QueriesHelper {
    private static final List<String> CHILD_FIELDS_TO_QUERY = new List<String>{
        'Timeline_Child__r.SObjectDateField__c',
        'Timeline_Child__r.SObjectTitle__c',
        'SObjectAssigneeId__c',
        'Timeline_Child__r.SObjectRelatedUserId__c',
        'Timeline_Child__r.SObjectTypeField__c'
    };

    // --------------------------------------------------- //
    // ----------------- getMetadataQuery ---------------- //
    // --------------------------------------------------- //

    public static String getMetadataQuery(Boolean isCreateable, String appName) {
        String query =
            'SELECT Id, ' +
            'SObjectAssigneeId__c, SObjectParent__c, SObjectRelationshipField__c, ' +
            'CreateableObject_NoOverride__c, ' +
            'Timeline_Child__r.SLDS_Timeline_Color__c, Timeline_Child__r.SLDS_Icon__c, Timeline_Child__r.SLDS_Dropdown_Icon__c,  ' +
            'Timeline_Child__r.CreateableObject_TextEnglish__c, Timeline_Child__r.CreateableObject_TextNorwegian__c, Timeline_Child__r.CreateableObject_RecordType__c,  ' +
            'Timeline_Child__r.SObjectDateField__c, Timeline_Child__r.SObjectDateFieldIsDate__c,  ' +
            'Timeline_Child__r.SObjectTypeField__c, Timeline_Child__r.SObjectTypeValue__c,  ' +
            'Timeline_Child__r.SObjectTitle__c, Timeline_Child__r.SObjectName__c,  ' +
            'Timeline_Child__r.ExpandedFieldsToDisplay__c, ' +
            'Timeline_Child__r.SObjectRelatedUserId__c, IsMacro__c, ' +
            'Timeline_Child__r.CreateableObject_Field1__c, Timeline_Child__r.CreateableObject_Value1__c,  ' +
            'Timeline_Child__r.CreateableObject_Field2__c, Timeline_Child__r.CreateableObject_Value2__c,  ' +
            'Timeline_Child__r.CreateableObject_Field3__c, Timeline_Child__r.CreateableObject_Value3__c,  ' +
            'Timeline_Child__r.SubtitlePastEnglish__c, Timeline_Child__r.SubtitlePastNorwegian__c,  ' +
            'Timeline_Child__r.SubtitleFutureEnglish__c, Timeline_Child__r.SubtitleFutureNorwegian__c,  ' +
            'Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c, Timeline_Child__r.SubtitleRelatedUserPrepositionNor__c, ' +
            'Timeline_Child__r.AutomaticRefresh__c, Timeline_Child__r.AutomaticRefresh_PushTopicName__c, ' +
            'Timeline_Child__r.AllowAutoOpen__c ' +
            'FROM TimelineParent__mdt ' +
            'WHERE SObjectParent__c = : parentSObjectType';

        if (isCreateable) {
            query += ' AND CreateableObject_Checkbox__c = true';
        } else {
            query += ' AND IsActive__c = true';
        }
        if (appName != '' && appName != null) {
            query += ' AND ConfigId__c = : appName';
        } else {
            query += ' AND ConfigId__c = null';
        }

        query += ' ORDER BY IsMacro__c, Timeline_Child__c';

        return query;
    }

    // --------------------------------------------------- //
    // --------------------- getQuery -------------------- //
    // --------------------------------------------------- //

    public static String getQuery(
        List<TimelineParent__mdt> sObjectsToQuery,
        TimelineParent__mdt mdt,
        String recordId,
        Integer amountOfMonths
    ) {
        String fields = getQueryFields(sObjectsToQuery, mdt);
        String parameters = getQueryParameters(mdt, recordId, amountOfMonths);

        // ! Vurder å bruk nested SOQL hvis det blir problemer med for mange soql spørringer (men burde ha nok)
        return buildSoqlQuery(
            fields,
            mdt.Timeline_Child__r.SObjectName__c,
            parameters,
            mdt.Timeline_Child__r.SObjectDateField__c
        );
    }

    // --------------------------------------------------- //
    // ------------------ getQueryFields ----------------- //
    // --------------------------------------------------- //

    public static String getQueryFields(List<TimelineParent__mdt> sObjectsToQuery, TimelineParent__mdt currentObject) {
        Set<String> fieldsToQuery = new Set<String>{ 'Id' };
        for (TimelineParent__mdt mdt : sObjectsToQuery) {
            if (mdt.Timeline_Child__r.SObjectName__c == currentObject.Timeline_Child__r.SObjectName__c) {
                for (String mdtField : CHILD_FIELDS_TO_QUERY) {
                    String field = '';
                    if (mdtField.contains('__r')) {
                        field = (String) mdt.getSObject(mdtField.split('\\.')[0]).get(mdtField.split('\\.')[1]);
                    } else {
                        field = (String) mdt.get(mdtField);
                    }
                    if (field != null) {
                        fieldsToQuery.add(field);
                    }
                }
            }
        }

        if (currentObject.Timeline_Child__r.SObjectName__c == 'Task') {
            fieldsToQuery.addAll(new List<String>{ 'Status', 'CreatedDate' });
        } else if (currentObject.Timeline_Child__r.SObjectName__c == 'Event') {
            fieldsToQuery.addAll(new List<String>{ 'ActivityDateTime', 'IsAllDayEvent', 'DurationInMinutes' });
        }

        List<String> res = new List<String>();
        res.addAll(fieldsToQuery);

        return string.join(res, ',');
    }

    // --------------------------------------------------- //
    // ---------------- getQueryParameters --------------- //
    // --------------------------------------------------- //

    public static String getQueryParameters(TimelineParent__mdt mdt, String recordId, Integer amountOfMonths) {
        String now = getTime(mdt.Timeline_Child__r.SObjectDateFieldIsDate__c);
        String dateField = mdt.Timeline_Child__r.SObjectDateField__c;

        String parameters = mdt.SObjectRelationshipField__c + ' = \'' + recordId + '\' AND ';

        // task specific parameter
        if (mdt.Timeline_Child__r.SObjectName__c == 'Task') {
            return parameters + addTaskParameters(mdt, amountOfMonths);
        }

        // general sobject parameter
        parameters +=
            '(' +
            dateField +
            ' = LAST_N_MONTHS:' +
            (amountOfMonths - 1) +
            ' OR ' +
            dateField +
            ' = THIS_MONTH OR ' +
            dateField +
            ' > ' +
            now +
            ')';

        return parameters;
    }

    // --------------------------------------------------- //
    // ------------------ buildSoqlQuery ----------------- //
    // --------------------------------------------------- //

    public static String buildSoqlQuery(String fields, String sObjectType, String parameters, String orderBy) {
        Boolean hasParameter = String.isNotBlank(parameters);
        Boolean hasOrderBy = String.isNotBlank(orderBy);

        String query =
            ' SELECT ' +
            fields +
            ' FROM ' +
            sObjectType +
            (hasParameter ? ' WHERE ' + parameters : '') +
            (hasOrderBy ? ' ORDER BY ' + orderBy : '');

        return query;
    }

    // --------------------------------------------------- //
    // ---------------- addTaskParameters ---------------- //
    // --------------------------------------------------- //

    public static String addTaskParameters(TimelineParent__mdt mdt, Integer amountOfMonths) {
        String parameters = '';
        parameters += 'TaskSubType != \'Email\'';

        String now = getTime(mdt.Timeline_Child__r.SObjectDateFieldIsDate__c);
        String date_time = getTime(false);
        String dateField = mdt.Timeline_Child__r.SObjectDateField__c;

        // datetime
        parameters +=
            ' AND ( (' +
            dateField +
            ' = LAST_N_MONTHS:' +
            (amountOfMonths - 1) +
            ' OR ' +
            dateField +
            ' = THIS_MONTH OR ' +
            dateField +
            ' > ' +
            now +
            ')';

        // if ActivityDate is used in the config, some tasks may be missing as the field is optional
        if (mdt.Timeline_Child__r.SObjectDateField__c == 'ActivityDate') {
            // query CreatedDate too (in addition to ActivityDate)
            parameters += ' OR ';
            parameters += '(CreatedDate <= TODAY' + ' AND ' + dateField + ' = null)';
        }

        return parameters + ' )';
    }

    // --------------------------------------------------- //
    // --------------------- getTime --------------------- //
    // --------------------------------------------------- //

    public static String getTime(Boolean isDateField) {
        // the metadata configuration checks whether the date field is date or datetime
        // however, dateless overrides the settings as CreatedDate is datetime
        if (isDateField) {
            return 'TODAY';
        } else {
            return ('' + System.now()).replaceAll(' ', 'T') + 'Z';
        }
    }
}
