@isTest
private class ActivityTimeline_ModelTest {
    @isTest
    private static void testSorting_history() {
        Account acc = ActivityTimeline_TestDataFactory.createAccount('test');

        Date t = Date.today().addMonths(-5);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta;

        t = t.addMonths(-1);
        Event ev = new Event(WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = t, Subject = 'test');
        insert ev;

        t = t.addMonths(-1);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta2;

        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            'Account',
            true,
            null
        );
        List<String> query = ActivityTimeline_Queries.createSoqlQueries(sObjectsToQuery, acc.Id, 8);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);
        List<ActivityTimeline_Model> data = ActivityTimeline_Helper.createActivityTimelineData(sObjectsToQuery, sObjects);

        System.assertEquals(3, data.size(), 'Three records added to account');

        data = new ActivityTimeline_ModelList(Label.ActivityTimeline_Older, Label.ActivityTimeline_Older, data, true)
            .models;

        System.assertEquals(ta.Id, data[0].record.recordId, 'The ID for the task should be in 1st in the list');
        System.assertEquals(ev.Id, data[1].record.recordId, 'The ID for the event should be in 2nd in the list');
        System.assertEquals(ta2.Id, data[2].record.recordId, 'The ID for the task should be in 3rd in the list');
    }

    @isTest
    private static void testSorting_future() {
        Account acc = ActivityTimeline_TestDataFactory.createAccount('test');

        Date t = Date.today().addDays(1);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta;

        t = t.addDays(1);
        Event ev = new Event(WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = t, Subject = 'test');
        insert ev;

        t = t.addDays(1);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta2;

        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            'Account',
            true,
            null
        );
        List<String> query = ActivityTimeline_Queries.createSoqlQueries(sObjectsToQuery, acc.Id, 5);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);
        List<ActivityTimeline_Model> data = ActivityTimeline_Helper.createActivityTimelineData(sObjectsToQuery, sObjects);

        System.assertEquals(3, data.size(), 'Three records added to account');

        data = new ActivityTimeline_ModelList(
                Label.ActivityTimeline_Upcoming,
                Label.ActivityTimeline_Upcoming,
                data,
                false
            )
            .models;

        System.assertEquals(ta.Id, data[0].record.recordId, 'The ID for the task should be in 1st in the list');
        System.assertEquals(ev.Id, data[1].record.recordId, 'The ID for the event should be in 2nd in the list');
        System.assertEquals(ta2.Id, data[2].record.recordId, 'The ID for the task should be in 3rd in the list');
    }
}
