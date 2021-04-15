@isTest
private class ObjectTimeline_ModelTest {
    @isTest
    private static void testSorting_history() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');

        Date t = Date.today().addMonths(-5);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta;

        t = t.addMonths(-1);
        Event ev = new Event(WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = t, Subject = 'test');
        insert ev;

        t = t.addMonths(-1);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta2;

        List<ObjectTimelineParent__mdt> sObjectsToQuery = ObjectTimeline_Queries.getSObjectsToQuery(
            'Account',
            true,
            null
        );
        List<String> query = ObjectTimeline_Queries.createSoqlQueries(sObjectsToQuery, acc.Id, 8);
        List<SObject> sObjects = ObjectTimeline_Queries.getSObjectsFromQueries(query);
        List<ObjectTimeline_Model> data = ObjectTimeline_Helper.createObjectTimelineData(sObjectsToQuery, sObjects);

        System.assertEquals(3, data.size(), 'Three records added to account');

        data = new ObjectTimeline_ModelList(Label.ObjectTimeline_Older, Label.ObjectTimeline_Older, data, true)
            .models;

        System.assertEquals(ta.Id, data[0].record.recordId, 'The ID for the task should be in 1st in the list');
        System.assertEquals(ev.Id, data[1].record.recordId, 'The ID for the event should be in 2nd in the list');
        System.assertEquals(ta2.Id, data[2].record.recordId, 'The ID for the task should be in 3rd in the list');
    }

    @isTest
    private static void testSorting_future() {
        Account acc = ObjectTimeline_TestDataFactory.createAccount('test');

        Date t = Date.today().addDays(1);
        Task ta = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta;

        t = t.addDays(1);
        Event ev = new Event(WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = t, Subject = 'test');
        insert ev;

        t = t.addDays(1);
        Task ta2 = new Task(WhatId = acc.Id, ActivityDate = t, Subject = 'test');
        insert ta2;

        List<ObjectTimelineParent__mdt> sObjectsToQuery = ObjectTimeline_Queries.getSObjectsToQuery(
            'Account',
            true,
            null
        );
        List<String> query = ObjectTimeline_Queries.createSoqlQueries(sObjectsToQuery, acc.Id, 5);
        List<SObject> sObjects = ObjectTimeline_Queries.getSObjectsFromQueries(query);
        List<ObjectTimeline_Model> data = ObjectTimeline_Helper.createObjectTimelineData(sObjectsToQuery, sObjects);

        System.assertEquals(3, data.size(), 'Three records added to account');

        data = new ObjectTimeline_ModelList(
                Label.ObjectTimeline_Upcoming,
                Label.ObjectTimeline_Upcoming,
                data,
                false
            )
            .models;

        System.assertEquals(ta.Id, data[0].record.recordId, 'The ID for the task should be in 1st in the list');
        System.assertEquals(ev.Id, data[1].record.recordId, 'The ID for the event should be in 2nd in the list');
        System.assertEquals(ta2.Id, data[2].record.recordId, 'The ID for the task should be in 3rd in the list');
    }
}
