/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 01-03-2023
 * @last modified by  : mamikals
 **/
@isTest
private without sharing class Timeline_ControllerTest {
    // ------------------------------------------------------------- //
    // ---------------------- getTotalRecords ---------------------- //
    // ------------------------------------------------------------- //

    @isTest
    private static void testGetTimelineData_UpcomingTask() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today();
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        insert ta;

        Test.StartTest();
        List<Timeline_ModelList> wrapper = Timeline_Controller.getTimelineData(acc.Id, 5, 3, null, true, null);
        Test.StopTest();

        System.assertEquals(1, wrapper.size(), 'one for upcoming');
        System.assertEquals(1, wrapper[0].models.size(), 'contains one in upcoming');
        System.assertEquals(Label.Timeline_Upcoming, wrapper[0].id, 'upcoming label as id');
        System.assertEquals(ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created task');
    }

    @isTest
    private static void testGetTimelineData_NoRelatedRecords() {
        Account acc = Timeline_TestDataFactory.createAccount('test');

        Test.StartTest();
        List<Timeline_ModelList> wrapper = Timeline_Controller.getTimelineData(acc.Id, 5, 3, null, true, null);
        Test.StopTest();

        System.assertEquals(0, wrapper.size(), 'zero for upcoming');
    }

    @isTest
    private static void testGetTimelineData_retryUntilDataFound() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today().addMonths(-12);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Status = 'Completed', Subject = 'test', WhoId = con.Id);
        insert ta;

        Test.StartTest();
        List<Timeline_ModelList> wrapper = Timeline_Controller.getTimelineData(acc.Id, 3, 3, null, true, null);
        Test.StopTest();

        System.assertEquals(1, wrapper.size(), 'one task');
        System.assertEquals(1, wrapper[0].models.size(), 'contains one tasks');
        System.assertEquals(d.month() + '-' + d.year(), wrapper[0].id, 'month-year as id');
        System.assertEquals(ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created task');
    }

    @isTest
    private static void testGetTimelineData_UpcomingAllDayEvent() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
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
        List<Timeline_ModelList> wrapper = Timeline_Controller.getTimelineData(acc.Id, 5, 3, null, true, null);
        Test.StopTest();

        System.assertEquals(1, wrapper.size(), 'One for upcoming');
        System.assertEquals(1, wrapper[0].models.size(), 'contains one in upcoming');
        System.assertEquals(Label.Timeline_Upcoming, wrapper[0].id, 'upcoming label as id');
        System.assertEquals(ev.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event');
    }

    @isTest
    private static void testGetTimelineData_HistoricTask() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today().addDays(-2);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        insert ta;

        Test.StartTest();
        List<Timeline_ModelList> wrapper = Timeline_Controller.getTimelineData(acc.Id, 5, 3, null, true, null);
        Test.StopTest();
        System.assertEquals(2, wrapper.size(), 'One for this month and one for overdue, same activity');

        System.assertEquals(1, wrapper[0].models.size(), 'One record in overdue view');
        System.assertEquals(1, wrapper[1].models.size(), 'One record in month view');

        System.assertEquals(Label.Timeline_Overdue, wrapper[0].id, 'overdue label as id');
        System.assertEquals(d.month() + '-' + d.year(), wrapper[1].id, 'month-year format as id');

        System.assertEquals(ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event');
        System.assertEquals(ta.Id, wrapper[1].models[0].record.recordId, 'The ID should be the created event');
    }

    @isTest
    private static void testGetTimelineData_twoHistoricTasks() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
        Contact con = new Contact(LastName = 'Test');
        insert con;

        Date d = Date.today().addDays(-2);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id);
        insert ta;
        insert ta2;

        Test.StartTest();
        List<Timeline_ModelList> wrapper = Timeline_Controller.getTimelineData(acc.Id, 5, 3, null, true, null);
        Test.StopTest();
        System.assertEquals(2, wrapper.size(), 'One for this month and one for overdue, same activity');

        System.assertEquals(2, wrapper[0].models.size(), 'Two records in overdue view');
        System.assertEquals(2, wrapper[1].models.size(), 'Two records in month view');

        System.assertEquals(Label.Timeline_Overdue, wrapper[0].id, 'overdue label as id');
        System.assertEquals(d.month() + '-' + d.year(), wrapper[1].id, 'month-year format as id');

        System.assertEquals(ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event');
        System.assertEquals(ta.Id, wrapper[1].models[0].record.recordId, 'The ID should be the created event');
    }

    @isTest
    private static void testGetTimelineData_HistoricEvent() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
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
        List<Timeline_ModelList> wrapper = Timeline_Controller.getTimelineData(acc.Id, 5, 3, '', true, null);
        Test.StopTest();

        System.assertEquals(1, wrapper.size(), 'One for this month');
        System.assertEquals(1, wrapper[0].models.size(), 'One record in month view');
        System.assertEquals(d.month() + '-' + d.year(), wrapper[0].id, 'month-year format as id');
        System.assertEquals(ev.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event');
    }

    @isTest
    private static void testGetOverdueTasks() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
        Event ev = new Event(WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today(), Subject = 'test');
        insert ev;
        Task ta = new Task(WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test');
        insert ta;
        Date t = Date.today().addDays(-2);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta2;

        Test.StartTest();
        List<Timeline_ModelList> data = Timeline_Controller.getTimelineData(acc.Id, 5, 3, null, true, null);
        Test.StopTest();

        System.assertEquals(3, data.size(), 'Only one wrapper, as it only contains overdue tasks');
        System.assertEquals(Label.Timeline_Overdue, data[0].id, 'overdue label as id');
        System.assertEquals(
            1,
            data[0].models.size(),
            'Only one records, as only one task created is overdue and events cannot be overdue (no completion or status)'
        );
    }

    @isTest
    private static void testGetTasks_datelessAndWithDate() {
        Account acc = Timeline_TestDataFactory.createAccount('test');
        Date d = Date.today().addDays(-1);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = d, Subject = 'test');
        insert ta;
        Task ta2 = new Task(WhatId = acc.Id, Subject = 'test');
        insert ta2;

        Test.StartTest();
        List<Timeline_ModelList> data = Timeline_Controller.getTimelineData(acc.Id, 5, 3, null, true, null);
        Test.StopTest();

        System.assertEquals(3, data.size(), 'three categories, upcoming, overdue and month view');

        System.assertEquals(Label.Timeline_Overdue, data[0].id, 'overdue id');
        System.assertEquals(Label.Timeline_Upcoming, data[1].id, 'upcoming id');
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
        Account acc = Timeline_TestDataFactory.createAccount('test');

        Test.StartTest();
        List<TimelineParent__mdt> sObjectType = Timeline_Controller.getTimelineObjects(acc.Id, null);
        Test.StopTest();

        List<TimelineParent__mdt> sObjectsToQuery = Timeline_Queries.getSObjectsToQuery('Account', true, null);

        System.assertEquals(sObjectsToQuery.size(), sObjectType.size(), 'Should be the same size of MDT objects');
    }

    @isTest
    private static void testGetTimelineObjects_changedLanguage() {
        Account acc = Timeline_TestDataFactory.createAccount('test');

        User u = Timeline_TestDataFactory.createStandardUser('Last UNIQUE NAME');

        System.runAs(u) {
            Test.StartTest();
            List<TimelineParent__mdt> sObjectType = Timeline_Controller.getTimelineObjects(acc.Id, null);
            Test.StopTest();

            for (TimelineParent__mdt mdt : sObjectType) {
                System.assertEquals(
                    mdt.Timeline_Child__r.CreateableObject_TextNorwegian__c,
                    mdt.Timeline_Child__r.CreateableObject_TextEnglish__c,
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
        List<TimelineParent__mdt> sObjectsToQuery = Timeline_Queries.getSObjectsToQuery(parentSObjectType, false, null);

        Test.StartTest();
        Integer results = Timeline_Controller.getTotalRecords(recordId, null);
        Test.StopTest();

        System.assertEquals(3, results, 'one event and two tasks should be fetched');
    }
}
