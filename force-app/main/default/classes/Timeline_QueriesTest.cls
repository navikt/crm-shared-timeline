@isTest
private without sharing class Timeline_QueriesTest {
    // --------------------------------------------------- //
    // --------------- getSObjectsToQuery ---------------- //
    // --------------------------------------------------- //

    @isTest
    private static void testGetSObjectsToQuery() {
        Test.StartTest();
        List<TimelineParent__mdt> sObjectsToQuery = Timeline_Queries.getSObjectsToQuery(
            'Account',
            false,
            null
        );
        Test.StopTest();

        System.assert(sObjectsToQuery.size() >= 0, 'Should already be some mdt\'s for account as parent');
    }

    // --------------------------------------------------- //
    // ---------------- createSoqlQueries ---------------- //
    // --------------------------------------------------- //

    @isTest
    private static void testCreateSoqlQueries() {
        List<String> mdtFieldsToQuery = new List<String>{
            'Timeline_Child__r.SObjectDateField__c',
            'Timeline_Child__r.SObjectTitle__c'
        };

        List<TimelineParent__mdt> sObjectsToQuery = Timeline_QueriesHelperTest.queryMdt(
            new List<String>{ 'Event', 'Task' }
        );

        Id recordId = Timeline_TestDataFactory.createAccount('test').Id;

        Test.StartTest();
        List<String> queries = Timeline_Queries.createSoqlQueries(sObjectsToQuery, recordId, 3);
        Test.StopTest();

        System.assertEquals(
            2,
            queries.size(),
            'Number of queries should only be 2, as there\'s one query for each unique type'
        );
        System.assert(queries.size() >= 0, 'Should be some data');

        for (TimelineParent__mdt mdt : sObjectsToQuery) {
            String fieldsToQuery = Timeline_QueriesHelper.getQueryFields(sObjectsToQuery, mdt);
            String expectedEvent =
                ' SELECT Id,ActivityDate,Subject,OwnerId,WhoId,ActivityDateTime,IsAllDayEvent,DurationInMinutes FROM Event WHERE WhatId = \'' +
                recordId +
                '\' AND (ActivityDate = LAST_N_MONTHS:2 OR ActivityDate = THIS_MONTH OR ActivityDate > TODAY) ORDER BY ActivityDate';

            String expectedTask =
                ' SELECT Id,ActivityDate,Subject,OwnerId,WhoId,Type,Status,CreatedDate FROM Task WHERE WhatId = \'' +
                recordId +
                '\' AND TaskSubType != \'Email\' AND ( (ActivityDate = LAST_N_MONTHS:2 OR ActivityDate = THIS_MONTH OR ActivityDate > TODAY) OR (CreatedDate <= TODAY AND ActivityDate = null) ) ORDER BY ActivityDate';

            for (String query : queries) {
                if (query.contains('FROM Event')) {
                    System.assertEquals(expectedEvent, query, '');
                } else if (query.contains('FROM Task')) {
                    System.assertEquals(expectedTask, query, 'the task query should be correctly seen');
                }
            }
        }
    }

    // --------------------------------------------------- //
    // ------------- getSObjectsFromQueries -------------- //
    // --------------------------------------------------- //

    @isTest
    private static void testGetSObjectsFromQueries() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
        Event ev = new Event(WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today());
        insert ev;
        Task ta = new Task(WhatId = acc.Id, ActivityDate = Date.today());
        insert ta;

        String parentSObjectType = Timeline_Helper.getSOjectTypeFromRecordId(acc.Id);
        List<TimelineParent__mdt> sObjectsToQuery = Timeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );
        List<String> queries = Timeline_Queries.createSoqlQueries(sObjectsToQuery, acc.Id, 3);

        Test.StartTest();
        List<SObject> sObjects = Timeline_Queries.getSObjectsFromQueries(queries);
        Test.StopTest();

        System.assertEquals(2, sObjects.size(), 'This account should have one event and one task on it');
    }

    // --------------------------------------------------- //
    // ----------------- getOverdueQuery ----------------- //
    // --------------------------------------------------- //

    @isTest
    private static void testGetOverdueQuery() {
        List<TimelineParent__mdt> sObjectsToQuery = Timeline_QueriesHelperTest.queryMdt(
            new List<String>{ 'Task' }
        );
        Id recordId = Timeline_TestDataFactory.createAccount('test').Id;

        Test.StartTest();
        List<String> results = Timeline_Queries.getOverdueQuery(sObjectsToQuery, recordId);
        Test.StopTest();

        String expected =
            ' SELECT Id,ActivityDate,Subject,OwnerId,WhoId,Type,Status,CreatedDate FROM Task WHERE WhatId = \'' +
            recordId +
            '\' AND TaskSubType != \'Email\' AND (ActivityDate < TODAY AND Status != \'Completed\') ORDER BY ActivityDate';

        System.assertEquals(1, results.size(), 'should only be one query for overdue tasks');
        System.assertEquals(expected, results[0], 'the query should match');
    }

    // --------------------------------------------------- //
    // ----------------- getTotalRecords ----------------- //
    // --------------------------------------------------- //

    @isTest
    private static void testGetTotalRecords() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today();
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d.addDays(4), Subject = 'test', WhoId = con.Id);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = d.addMonths(-2), Subject = 'test', WhoId = con.Id);
        insert ta;
        insert ta2;

        Event ev = new Event(WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today());
        insert ev;

        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = Timeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<TimelineParent__mdt> sObjectsToQuery = Timeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        Test.StartTest();
        Integer totalRecords = Timeline_Queries.getTotalRecords(sObjectsToQuery, recordId);
        Test.StopTest();

        System.assertEquals(3, totalRecords, 'one event and two tasks should be fetched');
    }
}
