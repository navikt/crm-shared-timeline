@isTest
private without sharing class ActivityTimeline_HelperTest {
    @TestSetup
    static void makeData() {
        Account acc = ActivityTimeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today();
        insert new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        insert new Task(WhatId = acc.Id, ActivityDate = d.addMonths(-2), Subject = 'testOVERDUE', WhoId = con.Id);
        insert new Task(
            WhatId = acc.Id,
            ActivityDate = d.addMonths(-12),
            Status = 'Completed',
            Subject = 'old and completed',
            WhoId = con.Id
        );
    }

    // --------------------------------------------------------------------------------- //
    // ------------------------- ACTIVITY + OVERDUE + UPPCOMING ------------------------ //
    // --------------------------------------------------------------------------------- //

    @isTest
    private static void testGetActivity() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        Test.StartTest();
        List<ActivityTimeline_Model> actual = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 3);
        Test.StopTest();

        System.assertEquals(2, actual.size(), 'two tasks associated with account');
    }

    @isTest
    private static void testGetUpcomingActivity() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );
        List<ActivityTimeline_Model> models = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 3);

        Test.StartTest();
        ActivityTimeline_ModelList actual = ActivityTimeline_Helper.getUpcomingActivity(models);
        Test.StopTest();

        System.assertEquals(1, actual.models.size(), 'only one upcoming task associated with account');
    }

    @isTest
    private static void testGetOverdueActivity() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        Test.StartTest();
        ActivityTimeline_ModelList actual = ActivityTimeline_Helper.getOverdueActivity(
            recordId,
            'Account',
            sObjectsToQuery
        );
        Test.StopTest();

        System.assertEquals(1, actual.models.size(), 'only one overdue task associated with account');
    }

    // --------------------------------------------------------------------------------- //
    // ------------------------------- DATA MANAPULATION ------------------------------- //
    // --------------------------------------------------------------------------------- //

    @isTest
    private static void testCreateActivityTimelineData() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );
        List<String> query = ActivityTimeline_Queries.createSoqlQueries(sObjectsToQuery, recordId, 3);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);

        Test.StartTest();
        List<ActivityTimeline_Model> data = ActivityTimeline_Helper.createActivityTimelineData(sObjectsToQuery, sObjects);
        Test.StopTest();

        System.assertEquals(2, data.size(), 'two tasks associated with account');
    }

    @isTest
    private static void testReloadUntilDataFetched() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );
        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 5);
        Integer totalRecords = ActivityTimeline_Queries.getTotalRecords(sObjectsToQuery, recordId);

        System.assertEquals(2, activity.size(), 'should only have found 2 records before test');

        Test.StartTest();
        activity = ActivityTimeline_Helper.reloadUntilDataFetched(
            sObjectsToQuery,
            recordId,
            5,
            3,
            2,
            totalRecords,
            activity
        );
        Test.StopTest();

        System.assertEquals(3, activity.size(), 'should have found all three records after test');
    }

    @isTest
    private static void testReloadUntilDataFetched_stressTest() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;

        insert new Task(
            WhatId = recordId,
            ActivityDate = Date.today().addYears(-100),
            Status = 'Completed',
            Subject = 'reallyyyyy old task'
        );

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );
        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 5);
        Integer totalRecords = ActivityTimeline_Queries.getTotalRecords(sObjectsToQuery, recordId);

        System.assertEquals(2, activity.size(), 'should only have found 2 records before test');

        Test.StartTest();
        activity = ActivityTimeline_Helper.reloadUntilDataFetched(
            sObjectsToQuery,
            recordId,
            5,
            3,
            2,
            totalRecords,
            activity
        );
        Test.StopTest();

        System.assertEquals(
            4,
            activity.size(),
            'should have found all four records after test, because 5 years is not too far back to query'
        );
    }

    @isTest
    private static void testReloadUntilDataFetched_stressTest_tooOldRecords() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;

        insert new Task(
            WhatId = recordId,
            ActivityDate = Date.today().addYears(-183),
            Status = 'Completed',
            Subject = 'reallyyyyy old task'
        );

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );
        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 5);
        Integer totalRecords = ActivityTimeline_Queries.getTotalRecords(sObjectsToQuery, recordId);

        System.assertEquals(2, activity.size(), 'should only have found 2 records before test');

        Test.StartTest();
        activity = ActivityTimeline_Helper.reloadUntilDataFetched(
            sObjectsToQuery,
            recordId,
            5,
            3,
            2,
            totalRecords,
            activity
        );
        Test.StopTest();

        System.assertEquals(
            3,
            activity.size(),
            'should NOT have found all four records after test, because 10 years IS too far back to query'
        );
    }

    @isTest
    private static void testCountRecords() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 3);
        List<ActivityTimeline_ModelList> activityDivided = ActivityTimeline_Helper.getRecordsDividedIntoMonths(activity);

        Test.StartTest();
        Integer results = ActivityTimeline_Helper.countRecords(activityDivided);
        Test.StopTest();

        System.assertEquals(1, results, 'the counter should find all three records');
    }

    @isTest
    private static void testGetAmountToLoad() {
        System.assertEquals(9, ActivityTimeline_Helper.getAmountToLoad(3, 2), '3^2 = 9');
    }

    @isTest
    private static void testGetAmountToLoad_100years() {
        System.assertEquals(
            1024,
            ActivityTimeline_Helper.getAmountToLoad(32, 2),
            '32^2 = 1 024 months, which is under capp'
        );
    }

    @isTest
    private static void testGetAmountToLoad_cappedAt100years() {
        System.assertEquals(
            1212,
            ActivityTimeline_Helper.getAmountToLoad(12, 3),
            '12^3 = 1 728, but capped at 1212 months'
        );
    }

    @isTest
    private static void testGetRecordsDividedIntoMonths() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );
        List<String> query = ActivityTimeline_Queries.createSoqlQueries(sObjectsToQuery, recordId, 3);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);
        List<ActivityTimeline_Model> data = ActivityTimeline_Helper.createActivityTimelineData(sObjectsToQuery, sObjects);
        data.sort();

        System.assertEquals(2, sObjects.size(), 'should be two tasks');
        System.assertEquals(2, data.size(), 'should be two tasks');

        Test.StartTest();
        List<ActivityTimeline_ModelList> actual = ActivityTimeline_Helper.getRecordsDividedIntoMonths(data);
        Test.StopTest();

        System.assertEquals(
            1,
            actual.size(),
            'should be one month of tasks, because the one due today will be removed is it will not be duplicated in "Today and Upcoming" and in "Month X"'
        );
    }

    @isTest
    private static void testAddAllActivities() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 3);
        List<ActivityTimeline_ModelList> activityDivided = ActivityTimeline_Helper.getRecordsDividedIntoMonths(activity);
        ActivityTimeline_ModelList upcoming = ActivityTimeline_Helper.getUpcomingActivity(activity);
        ActivityTimeline_ModelList overdue = ActivityTimeline_Helper.getOverdueActivity(
            recordId,
            parentSObjectType,
            sObjectsToQuery
        );

        Test.StartTest();
        List<ActivityTimeline_ModelList> results = ActivityTimeline_Helper.addAllActivities(
            upcoming,
            overdue,
            activityDivided
        );
        Test.StopTest();

        System.assertEquals(3, results.size(), 'Should contain overdue, upcoming and month view');
    }

    @isTest
    private static void testAddAllActivities_doesNotAddEmptyOverdueAndUpcoming() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 3);
        List<ActivityTimeline_ModelList> activityDivided = ActivityTimeline_Helper.getRecordsDividedIntoMonths(activity);
        ActivityTimeline_ModelList upcoming = ActivityTimeline_Helper.getUpcomingActivity(activity);
        ActivityTimeline_ModelList overdue = ActivityTimeline_Helper.getOverdueActivity(
            recordId,
            parentSObjectType,
            sObjectsToQuery
        );

        upcoming.models = new List<ActivityTimeline_Model>();
        overdue.models = new List<ActivityTimeline_Model>();

        Test.StartTest();
        List<ActivityTimeline_ModelList> results = ActivityTimeline_Helper.addAllActivities(
            upcoming,
            overdue,
            activityDivided
        );
        Test.StopTest();

        System.assertEquals(1, results.size(), 'Should contain month view only');
    }

    @isTest
    private static void testAddAllActivities_doesNotAddOverdueIfNull() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 3);
        List<ActivityTimeline_ModelList> activityDivided = ActivityTimeline_Helper.getRecordsDividedIntoMonths(activity);
        ActivityTimeline_ModelList upcoming = ActivityTimeline_Helper.getUpcomingActivity(activity);
        ActivityTimeline_ModelList overdue = ActivityTimeline_Helper.getOverdueActivity(
            recordId,
            parentSObjectType,
            sObjectsToQuery
        );

        upcoming.models = new List<ActivityTimeline_Model>();
        overdue.models = new List<ActivityTimeline_Model>();

        Test.StartTest();
        List<ActivityTimeline_ModelList> results = ActivityTimeline_Helper.addAllActivities(
            upcoming,
            overdue,
            activityDivided
        );
        Test.StopTest();

        System.assertEquals(
            1,
            results.size(),
            'Should contain month view only as overdue is null and upcoming is empty'
        );
    }

    // --------------------------------------------------------------------------------- //
    // -------------------------- SOBJECT TYPE AND RECORD TYPE ------------------------- //
    // --------------------------------------------------------------------------------- //

    @isTest
    private static void testGetSOjectTypeFromRecordId() {
        Account acc = ActivityTimeline_TestDataFactory.createAccount('test');

        Test.StartTest();
        String sObjtype = ActivityTimeline_Helper.getSOjectTypeFromRecordId(acc.Id);
        Test.StopTest();

        System.assertEquals('Account', sObjtype, 'The returned value should be account based on the account ID');
    }

    @isTest
    private static void testGetRecordTypes() {
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            'Account',
            false,
            null
        );

        Test.StartTest();
        Map<String, Id> recordTypes = ActivityTimeline_Helper.getRecordTypes(sObjectsToQuery);
        Test.StopTest();

        System.assertEquals(0, recordTypes.size(), 'Currently zero mdt objects with record types');
    }

    // --------------------------------------------------------------------------------- //
    // ----------------------------- OWNER AND CONTACT NAME ---------------------------- //
    // --------------------------------------------------------------------------------- //

    @isTest
    private static void testGetOwnerAndContactNames_past_contactSet() {
        delete [SELECT Id FROM Task];

        Account acc = ActivityTimeline_TestDataFactory.createAccount('test2');
        Contact con = new Contact(LastName = 'Test2');
        insert con;

        Date d = Date.today();
        Task ta = new Task(
            WhatId = acc.Id,
            ActivityDate = d.addMonths(-2),
            Subject = 'test',
            Status = 'Completed',
            WhoId = con.Id
        );
        insert ta;

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(acc.Id);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        Map<String, ActivityTimelineParent__mdt> sObjectsToQueryMap = ActivityTimeline_Helper.getMapOfActivityTimelineConfig(
            sObjectsToQuery
        );
        sObjectsToQuery = new List<ActivityTimelineParent__mdt>{ sObjectsToQueryMap.get('Task') }; // get only tasks

        List<String> query = ActivityTimeline_Queries.createSoqlQueries(sObjectsToQuery, acc.Id, 5);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);
        List<ActivityTimeline_Model> data = ActivityTimeline_Helper.createActivityTimelineData(sObjectsToQuery, sObjects);

        System.assertEquals(1, sObjects.size(), 'size should be 1 record');
        System.assertEquals(1, data.size(), 'size should be 1 record');

        System.assertEquals(null, data[0].record.relatedUser, 'should be null before running function');
        System.assertEquals(null, data[0].record.subtitle, 'should be null before running function');
        System.assertEquals(
            UserInfo.getUserId(),
            data[0].record.assigneeId,
            'should be current user before running function'
        );

        Test.StartTest();
        List<ActivityTimeline_Model> actual = ActivityTimeline_Helper.getOwnerAndContactNames(data);
        Test.StopTest();

        String expected =
            data[0].config.Activity_Timeline_Child__r.SubtitlePastEnglish__c +
            ' ' +
            data[0].config.Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c;

        System.assertEquals('Test2', data[0].record.relatedUser, 'should have set name of contact');
        System.assertEquals(expected, data[0].record.subtitle, 'should have set subtitle');
        System.assertEquals(null, data[0].record.assigneeId, 'should be current user before running function');
    }

    @isTest
    private static void testGetOwnerAndContactNames_future_contactNOTSet() {
        delete [SELECT Id FROM Task];

        Account acc = ActivityTimeline_TestDataFactory.createAccount('test2');
        Contact con = new Contact(LastName = 'Test2');
        insert con;

        Date d = Date.today();
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d.addMonths(+2), Subject = 'test', Status = 'Completed');
        insert ta;

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(acc.Id);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        Map<String, ActivityTimelineParent__mdt> sObjectsToQueryMap = ActivityTimeline_Helper.getMapOfActivityTimelineConfig(
            sObjectsToQuery
        );
        sObjectsToQuery = new List<ActivityTimelineParent__mdt>{ sObjectsToQueryMap.get('Task') }; // get only tasks

        List<String> query = ActivityTimeline_Queries.createSoqlQueries(sObjectsToQuery, acc.Id, 5);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);
        List<ActivityTimeline_Model> data = ActivityTimeline_Helper.createActivityTimelineData(sObjectsToQuery, sObjects);

        System.assertEquals(1, sObjects.size(), 'size should be 1 record');
        System.assertEquals(1, data.size(), 'size should be 1 record');

        System.assertEquals(null, data[0].record.relatedUser, 'should be null before running function');
        System.assertEquals(null, data[0].record.subtitle, 'should be null before running function');
        System.assertEquals(
            UserInfo.getUserId(),
            data[0].record.assigneeId,
            'should be current user before running function'
        );

        Test.StartTest();
        List<ActivityTimeline_Model> actual = ActivityTimeline_Helper.getOwnerAndContactNames(data);
        Test.StopTest();

        String expected =
            data[0].config.Activity_Timeline_Child__r.SubtitleFutureEnglish__c +
            ' ' +
            data[0].config.Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c;

        System.assertEquals(null, data[0].record.relatedUser, 'should have set name of contact');
        System.assertEquals(
            data[0].config.Activity_Timeline_Child__r.SubtitleFutureEnglish__c,
            data[0].record.subtitle,
            'should have set subtitle'
        );
        System.assertEquals(null, data[0].record.assigneeId, 'should be current user before running function');
    }

    @isTest
    private static void testGetOwnerAndContactNames_future_contactNOTSet_call() {
        delete [SELECT Id FROM Task];

        Account acc = ActivityTimeline_TestDataFactory.createAccount('test2');
        Contact con = new Contact(LastName = 'Test2');
        insert con;

        Date d = Date.today();
        Task ta = new Task(
            WhatId = acc.Id,
            ActivityDate = d.addMonths(+2),
            Subject = 'test',
            TaskSubtype = 'Call',
            Status = 'Completed'
        );
        insert ta;

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(acc.Id);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        Map<String, ActivityTimelineParent__mdt> sObjectsToQueryMap = ActivityTimeline_Helper.getMapOfActivityTimelineConfig(
            sObjectsToQuery
        );
        sObjectsToQuery = new List<ActivityTimelineParent__mdt>{ sObjectsToQueryMap.get('Task') }; // get only tasks

        List<String> query = ActivityTimeline_Queries.createSoqlQueries(sObjectsToQuery, acc.Id, 5);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);
        List<ActivityTimeline_Model> data = ActivityTimeline_Helper.createActivityTimelineData(sObjectsToQuery, sObjects);

        data[0].record.type = 'Call';

        System.assertEquals(1, sObjects.size(), 'size should be 1 record');
        System.assertEquals(1, data.size(), 'size should be 1 record');

        System.assertEquals(null, data[0].record.relatedUser, 'should be null before running function');
        System.assertEquals(null, data[0].record.subtitle, 'should be null before running function');
        System.assertEquals(
            UserInfo.getUserId(),
            data[0].record.assigneeId,
            'should be current user before running function'
        );

        Test.StartTest();
        List<ActivityTimeline_Model> actual = ActivityTimeline_Helper.getOwnerAndContactNames(data);
        Test.StopTest();

        String expected =
            data[0].config.Activity_Timeline_Child__r.SubtitleFutureEnglish__c +
            ' ' +
            data[0].config.Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c;

        System.assertEquals('someone', data[0].record.relatedUser, 'should have set name of contact');
        System.assertEquals(
            data[0].config.Activity_Timeline_Child__r.SubtitleFutureEnglish__c,
            data[0].record.subtitle,
            'should have set subtitle'
        );
        System.assertEquals(null, data[0].record.assigneeId, 'should be current user before running function');
    }

    @isTest
    private static void testGetOwnerName_currentUser() {
        Test.StartTest();
        Map<Id, String> result = ActivityTimeline_Helper.getOwnerName(new Set<Id>{ UserInfo.getUserId() });
        Test.StopTest();

        System.assertEquals(1, result.size(), 'Only one ID added, one user returned');
        System.assert(result.containsKey(UserInfo.getUserId()), 'contains the user id');

        System.assertEquals('You', result.get(UserInfo.getUserId()), 'name should be "You"');
    }

    @isTest
    private static void testGetOwnerName_notCurrentUser() {
        Account acc = ActivityTimeline_TestDataFactory.createAccount('test');
        User u = ActivityTimeline_TestDataFactory.createStandardUser('Last UNIQUE NAME');

        Test.StartTest();
        Map<Id, String> result = ActivityTimeline_Helper.getOwnerName(new Set<Id>{ u.Id });
        Test.StopTest();

        System.assertEquals(1, result.size(), 'Only one ID added, one user returned');
        System.assert(result.containsKey(u.Id), 'contains the user id');
        System.assertEquals('First Last UNIQUE NAME', result.get(u.Id), 'name should be the the created user');
    }

    @isTest
    private static void testGetContactName() {
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Test.StartTest();
        Map<Id, String> result = ActivityTimeline_Helper.getContactName(new Set<Id>{ con.Id });
        Test.StopTest();

        System.assertEquals(1, result.size(), 'Only one ID added, one contact returned');
        System.assert(result.containsKey(con.Id), 'contains the contact id');
        System.assertEquals('Test', result.get(con.Id), 'should be test');
    }

    // --------------------------------------------------------------------------------- //
    // --------------------------- CUSTMOM METADATA FUNCTIONS -------------------------- //
    // --------------------------------------------------------------------------------- //

    @isTest
    private static void testRemoveConfig() {
        Id recordId = [SELECT Id FROM Account WHERE NAME = 'test' LIMIT 1].Id;
        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(sObjectsToQuery, recordId, 3);
        List<ActivityTimeline_ModelList> data = ActivityTimeline_Helper.getRecordsDividedIntoMonths(activity);

        for (ActivityTimeline_ModelList modelList : data) {
            for (ActivityTimeline_Model model : modelList.models) {
                System.assertNotEquals(null, model.config, 'all config should contain config');
            }
        }

        Test.StartTest();
        List<ActivityTimeline_ModelList> modelLists = ActivityTimeline_Helper.removeConfig(data);
        Test.StopTest();

        for (ActivityTimeline_ModelList modelList : modelLists) {
            for (ActivityTimeline_Model model : modelList.models) {
                System.assertEquals(null, model.config, 'all config should have been removed');
            }
        }
    }

    @isTest
    private static void testGetMapOfActivityTimelineConfig() {
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_QueriesHelperTest.queryMdt(
            new List<String>{ 'Event', 'Task' }
        );

        Test.StartTest();
        Map<String, ActivityTimelineParent__mdt> actual = ActivityTimeline_Helper.getMapOfActivityTimelineConfig(
            sObjectsToQuery
        );
        Test.StopTest();

        System.assert(actual.containsKey('Event'), 'Event should be a key for the map');
        System.assertEquals(
            sObjectsToQuery[0].Id,
            actual.get('Event').Id,
            'matching the sObjectsToQuery id with the map content id should be a match'
        );
        System.assert(actual.containsKey('Task'), 'Task should be a key for the map');
        System.assertEquals(
            sObjectsToQuery[1].Id,
            actual.get('Task').Id,
            'matching the sObjectsToQuery id with the map content id should be a match'
        );
    }

    // --------------------------------------------------------------------------------- //
    // ------------------------------------- OTHER ------------------------------------- //
    // --------------------------------------------------------------------------------- //

    @isTest
    private static void testReturnValueIfNotNull_isString() {
        Test.StartTest();
        String actual = ActivityTimeline_Helper.returnValueIfNotNull(null);
        Test.StopTest();

        System.assertEquals('', actual, 'null is null, thus empty string returned');
    }

    @isTest
    private static void testReturnValueIfNotNull_isNull() {
        Test.StartTest();
        String actual = ActivityTimeline_Helper.returnValueIfNotNull('test');
        Test.StopTest();

        System.assertEquals('test', actual, 'string "test" is not null, thus returned');
    }

    @isTest
    private static void testCheckObjectAccess_read() {
        List<ActivityTimelineParent__mdt> expected = ActivityTimeline_Queries.getSObjectsToQuery('Account', false, null);

        Test.StartTest();
        List<ActivityTimelineParent__mdt> actual = ActivityTimeline_Helper.checkObjectAccess(false, expected);
        Test.StopTest();

        System.assertEquals(2, actual.size(), 'should be the same list');
    }

    @isTest
    private static void testCheckObjectAccess_create() {
        List<ActivityTimelineParent__mdt> expected = ActivityTimeline_Queries.getSObjectsToQuery('Account', true, null);

        Test.StartTest();
        List<ActivityTimelineParent__mdt> actual = ActivityTimeline_Helper.checkObjectAccess(true, expected);
        Test.StopTest();

        System.assertEquals(2, actual.size(), 'should be the same list');
    }

    @isTest
    private static void testGetMonth_english() {
        Test.StartTest();
        String actual = ActivityTimeline_Helper.getMonth(1);
        Test.StopTest();

        System.assertEquals('January', actual, 'user is using english, thus January');
    }

    @isTest
    private static void testGetMonth_norwegian() {
        Account acc = ActivityTimeline_TestDataFactory.createAccount('test');
        User u = ActivityTimeline_TestDataFactory.createStandardUser('Last UNIQUE NAME');

        System.runAs(u) {
            Test.StartTest();
            String actual = ActivityTimeline_Helper.getMonth(1);
            Test.StopTest();

            System.assertEquals('Januar', actual, 'user is using english, thus January');
        }
    }

    @isTest
    private static void testTranslateTimelineObjects_english() {
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_QueriesHelperTest.queryMdt(
            new List<String>{ 'Event', 'Task' }
        );

        String expectedEvent = sObjectsToQuery[0].Activity_Timeline_Child__r.CreateableObject_TextEnglish__c;
        String expectedTask = sObjectsToQuery[1].Activity_Timeline_Child__r.CreateableObject_TextEnglish__c;

        Test.StartTest();
        List<ActivityTimelineParent__mdt> results = ActivityTimeline_Helper.translateTimelineObjects(sObjectsToQuery);
        Test.StopTest();

        System.assertEquals(
            expectedEvent,
            results[0].Activity_Timeline_Child__r.CreateableObject_TextEnglish__c,
            'the english text should NOT have been changed, as current user uses english language'
        );
        System.assertEquals(
            expectedTask,
            results[1].Activity_Timeline_Child__r.CreateableObject_TextEnglish__c,
            'the english text should NOT have been changed, as current user uses english language'
        );
    }

    @isTest
    private static void testTranslateTimelineObjects_norwegian() {
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_QueriesHelperTest.queryMdt(
            new List<String>{ 'Event', 'Task' }
        );

        String expectedEvent = sObjectsToQuery[0].Activity_Timeline_Child__r.CreateableObject_TextNorwegian__c;
        String expectedTask = sObjectsToQuery[1].Activity_Timeline_Child__r.CreateableObject_TextNorwegian__c;

        Account acc = ActivityTimeline_TestDataFactory.createAccount('test');
        User u = ActivityTimeline_TestDataFactory.createStandardUser('Last UNIQUE NAME');

        System.runAs(u) {
            Test.StartTest();
            List<ActivityTimelineParent__mdt> results = ActivityTimeline_Helper.translateTimelineObjects(
                sObjectsToQuery
            );
            Test.StopTest();

            System.assertEquals(
                expectedEvent,
                results[0].Activity_Timeline_Child__r.CreateableObject_TextEnglish__c,
                'the english text should NOT have been changed, as current user uses english language'
            );
            System.assertEquals(
                expectedTask,
                results[1].Activity_Timeline_Child__r.CreateableObject_TextEnglish__c,
                'the english text should NOT have been changed, as current user uses english language'
            );
        }
    }
}
