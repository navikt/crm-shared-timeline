@isTest
private without sharing class ObjectTimeline_ControllerTest {
    // ------------------------------------------------------------- //
    // ---------------------- getTotalRecords ---------------------- //
    // ------------------------------------------------------------- //

    @isTest
    private static void testGetObjectTimelineData_UpcomingTask() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today();
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        insert ta;

        Test.StartTest();
        List<ObjectTimeline_ModelList> wrapper = ObjectTimeline_Controller.getObjectTimelineData(
            acc.Id,
            5,
            3,
            null
        );
        Test.StopTest();

        System.assertEquals(1, wrapper.size(), 'one for upcoming');
        System.assertEquals(1, wrapper[0].models.size(), 'contains one in upcoming');
        System.assertEquals(Label.ObjectTimeline_Upcoming, wrapper[0].id, 'upcoming label as id');
        System.assertEquals(ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created task');
    }

    @isTest
    private static void testGetObjectTimelineData_retryUntilDataFound() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today().addMonths(-12);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Status = 'Completed', Subject = 'test', WhoId = con.Id);
        insert ta;

        Test.StartTest();
        List<ObjectTimeline_ModelList> wrapper = ObjectTimeline_Controller.getObjectTimelineData(
            acc.Id,
            3,
            3,
            null
        );
        Test.StopTest();

        System.assertEquals(1, wrapper.size(), 'one task');
        System.assertEquals(1, wrapper[0].models.size(), 'contains one tasks');
        System.assertEquals(d.month() + '-' + d.year(), wrapper[0].id, 'month-year as id');
        System.assertEquals(ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created task');
    }

    @isTest
    private static void testGetObjectTimelineData_UpcomingAllDayEvent() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today();
        Event ev = new Event(
            WhatId = acc.Id,
            DurationInMinutes = 1440,
            IsAllDayEvent = true,
            ActivityDate = Date.today(),
            Subject = 'Hele dagen',
            WhoId = con.Id
        );
        insert ev;

        Test.StartTest();
        List<ObjectTimeline_ModelList> wrapper = ObjectTimeline_Controller.getObjectTimelineData(
            acc.Id,
            5,
            3,
            null
        );
        Test.StopTest();

        System.assertEquals(1, wrapper.size(), 'One for upcoming');
        System.assertEquals(1, wrapper[0].models.size(), 'contains one in upcoming');
        System.assertEquals(Label.ObjectTimeline_Upcoming, wrapper[0].id, 'upcoming label as id');
        System.assertEquals(ev.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event');
    }

    @isTest
    private static void testGetObjectTimelineData_HistoricTask() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today().addDays(-2);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        insert ta;

        Test.StartTest();
        List<ObjectTimeline_ModelList> wrapper = ObjectTimeline_Controller.getObjectTimelineData(
            acc.Id,
            5,
            3,
            null
        );
        Test.StopTest();
        System.assertEquals(2, wrapper.size(), 'One for this month and one for overdue, same activity');

        System.assertEquals(1, wrapper[0].models.size(), 'One record in overdue view');
        System.assertEquals(1, wrapper[1].models.size(), 'One record in month view');

        System.assertEquals(Label.ObjectTimeline_Overdue, wrapper[0].id, 'overdue label as id');
        System.assertEquals(d.month() + '-' + d.year(), wrapper[1].id, 'month-year format as id');

        System.assertEquals(ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event');
        System.assertEquals(ta.Id, wrapper[1].models[0].record.recordId, 'The ID should be the created event');
    }

    @isTest
    private static void testGetObjectTimelineData_twoHistoricTasks() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today().addDays(-2);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        insert ta;
        insert ta2;

        Test.StartTest();
        List<ObjectTimeline_ModelList> wrapper = ObjectTimeline_Controller.getObjectTimelineData(
            acc.Id,
            5,
            3,
            null
        );
        Test.StopTest();
        System.assertEquals(2, wrapper.size(), 'One for this month and one for overdue, same activity');

        System.assertEquals(2, wrapper[0].models.size(), 'Two records in overdue view');
        System.assertEquals(2, wrapper[1].models.size(), 'Two records in month view');

        System.assertEquals(Label.ObjectTimeline_Overdue, wrapper[0].id, 'overdue label as id');
        System.assertEquals(d.month() + '-' + d.year(), wrapper[1].id, 'month-year format as id');

        System.assertEquals(ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event');
        System.assertEquals(ta.Id, wrapper[1].models[0].record.recordId, 'The ID should be the created event');
    }

    @isTest
    private static void testGetObjectTimelineData_HistoricEvent() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today().addDays(-1);
        Event ev = new Event(
            WhatId = acc.Id,
            DurationInMinutes = 1,
            ActivityDateTime = d,
            Subject = 'i går',
            WhoId = con.Id
        );
        insert ev;

        Test.StartTest();
        List<ObjectTimeline_ModelList> wrapper = ObjectTimeline_Controller.getObjectTimelineData(acc.Id, 5, 3, '');
        Test.StopTest();

        System.assertEquals(1, wrapper.size(), 'One for this month');
        System.assertEquals(1, wrapper[0].models.size(), 'One record in month view');
        System.assertEquals(d.month() + '-' + d.year(), wrapper[0].id, 'month-year format as id');
        System.assertEquals(ev.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event');
    }

    @isTest
    private static void testGetOverdueTasks() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
        Event ev = new Event(WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today(), Subject = 'test');
        insert ev;
        Task ta = new Task(WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test');
        insert ta;
        Date t = Date.today().addDays(-2);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta2;

        Test.StartTest();
        List<ObjectTimeline_ModelList> data = ObjectTimeline_Controller.getObjectTimelineData(acc.Id, 5, 3, null);
        Test.StopTest();

        System.assertEquals(3, data.size(), 'Only one wrapper, as it only contains overdue tasks');
        System.assertEquals(Label.ObjectTimeline_Overdue, data[0].id, 'overdue label as id');
        System.assertEquals(
            1,
            data[0].models.size(),
            'Only one records, as only one task created is overdue and events cannot be overdue (no completion or status)'
        );
    }

    @isTest
    private static void testGetTasks_datelessAndWithDate() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
        Date d = Date.today().addDays(-1);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test');
        insert ta;
        Task ta2 = new Task(WhatId = acc.Id, Subject = 'test');
        insert ta2;

        Test.StartTest();
        List<ObjectTimeline_ModelList> data = ObjectTimeline_Controller.getObjectTimelineData(acc.Id, 5, 3, null);
        Test.StopTest();

        System.assertEquals(3, data.size(), 'three categories, upcoming, overdue and month view');

        System.assertEquals(Label.ObjectTimeline_Overdue, data[0].id, 'overdue id');
        System.assertEquals(Label.ObjectTimeline_Upcoming, data[1].id, 'upcoming id');
        System.assertEquals(d.month() + '-' + d.year(), data[2].id, 'month id');

        System.assertEquals(
            1,
            data[0].models.size(),
            'Only one records, as only one task should be in the overdue category'
        );
        System.assertEquals(
            1,
            data[1].models.size(),
            'Only one records, as only one task should be in the upcoming category'
        );
        System.assertEquals(
            1,
            data[2].models.size(),
            'Only one records, as only one task should be in the month category'
        );

        System.assertEquals(ta.Id, data[0].models[0].record.recordId, 'first and only record should be "ta" Task');
        System.assertEquals(ta2.Id, data[1].models[0].record.recordId, 'first and only record should be "ta2" Task');
        System.assertEquals(ta.Id, data[2].models[0].record.recordId, 'first and only record should be "ta" Task');
    }

    // ------------------------------------------------------------- //
    // -------------------- getTimelineObjects --------------------- //
    // ------------------------------------------------------------- //

    @isTest
    private static void testGetTimelineObjects() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');

        Test.StartTest();
        List<ObjectTimelineParent__mdt> sObjectType = ObjectTimeline_Controller.getTimelineObjects(acc.Id, null);
        Test.StopTest();

        List<ObjectTimelineParent__mdt> sObjectsToQuery = ObjectTimeline_Queries.getSObjectsToQuery(
            'Account',
            true,
            null
        );

        System.assertEquals(sObjectsToQuery.size(), sObjectType.size(), 'Should be the same size of MDT objects');
    }

    @isTest
    private static void testGetTimelineObjects_changedLanguage() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');

        User u = ObjectTimeline_TestDataFactory.createStandardUser('Last UNIQUE NAME');

        System.runAs(u) {
            Test.StartTest();
            List<ObjectTimelineParent__mdt> sObjectType = ObjectTimeline_Controller.getTimelineObjects(acc.Id, null);
            Test.StopTest();

            for (ObjectTimelineParent__mdt mdt : sObjectType) {
                System.assertEquals(
                    mdt.Object_Timeline_Child__r.CreateableObject_TextNorwegian__c,
                    mdt.Object_Timeline_Child__r.CreateableObject_TextEnglish__c,
                    'The norwegian text should be moved to the english field, as this user is norwegian'
                );
            }
        }
    }

    // ------------------------------------------------------------- //
    // ---------------------- getTotalRecords ---------------------- //
    // ------------------------------------------------------------- //

    @isTest
    private static void testGetTotalRecords() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');
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
        String parentSObjectType = ObjectTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ObjectTimelineParent__mdt> sObjectsToQuery = ObjectTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            null
        );

        Test.StartTest();
        Integer results = ObjectTimeline_Controller.getTotalRecords(recordId, null);
        Test.StopTest();

        System.assertEquals(3, results, 'one event and two tasks should be fetched');
    }
}
