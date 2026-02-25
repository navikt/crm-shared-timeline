@isTest
private class NKS_TimelineControllerTest {
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }

    @isTest
    static void testGetRecordsBlankId() {
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords('', 10);
        Assert.areEqual(0, result.size(), 'Expected empty list for blank recordId');
    }

    @isTest
    static void testGetRecordsNullId() {
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(null, 10);
        Assert.areEqual(0, result.size(), 'Expected empty list for null recordId');
    }

    @isTest
    static void testGetRecordsDefaultLimit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(acc.Id, null);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null with null limit');
    }

    @isTest
    static void testGetRecordsZeroLimit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(acc.Id, 0);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null with zero limit (uses default)');
    }

    @isTest
    static void testGetRecordsReturnsGroupedResults() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(acc.Id, 50);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');

        for (NKS_TimelineController.TimelineGroup grp : result) {
            Assert.isNotNull(grp.id, 'Group id should not be null');
            Assert.isNotNull(grp.name, 'Group name should not be null');
            Assert.isNotNull(grp.models, 'Group models should not be null');
            Assert.areEqual(grp.models.size(), grp.size, 'Group size should match models count');
        }
    }

    @isTest
    static void testGetRecordsModelsHaveCorrectStructure() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(acc.Id, 50);
        Test.stopTest();

        for (NKS_TimelineController.TimelineGroup grp : result) {
            for (NKS_TimelineController.TimelineModel model : grp.models) {
                Assert.isNotNull(model.record, 'Model record should not be null');
                Assert.isNotNull(model.theme, 'Model theme should not be null');
                Assert.isNotNull(model.filter, 'Model filter should not be null');
                Assert.isNotNull(model.record.recordId, 'RecordData recordId should not be null');
                Assert.isNotNull(model.record.dateValueDb, 'RecordData dateValueDb should not be null');
                Assert.isNotNull(model.theme.icon, 'Theme icon should not be null');
            }
        }
    }

    @isTest
    static void testTimelineRecordCompareTo() {
        NKS_TimelineController.TimelineRecord newer = new NKS_TimelineController.TimelineRecord();
        newer.dateValue = Datetime.now();

        NKS_TimelineController.TimelineRecord older = new NKS_TimelineController.TimelineRecord();
        older.dateValue = Datetime.now().addDays(-1);

        Assert.areEqual(-1, newer.compareTo(older), 'Newer record should sort first');
        Assert.areEqual(1, older.compareTo(newer), 'Older record should sort last');
        Assert.areEqual(0, newer.compareTo(newer), 'Same record should be equal');
    }

    @isTest
    static void testFilterDataThread() {
        NKS_TimelineController.FilterData fd = new NKS_TimelineController.FilterData('Thread__c', 'SomeThemeGroup');
        Assert.areEqual('SomeThemeGroup', fd.picklistValue1);
        Assert.isFalse(fd.shown);
    }

    @isTest
    static void testTheme() {
        NKS_TimelineController.Theme t = new NKS_TimelineController.Theme('standard:voice_call', '7D7D7D');
        Assert.areEqual('standard:voice_call', t.icon);
        Assert.areEqual('7D7D7D', t.sldsTimelineItemColor);
    }

    @isTest
    static void testTimelineModelAndRecordData() {
        NKS_TimelineController.TimelineRecord rec = new NKS_TimelineController.TimelineRecord();
        rec.recordId = UserInfo.getUserId();
        rec.dateValue = Datetime.now();
        rec.sObjectType = 'Thread__c';
        rec.sObjectLabel = 'Thread';
        rec.icon = 'standard:messaging_user';
        rec.color = '7D7D7D';
        rec.subtitleOverride = 'Summary';
        rec.customComponent = 'ThreadExpandedTimeline';
        rec.clampLines = 2;
        rec.themeGroupName = 'Group1';
        rec.slickBackgroundColor = null;
        rec.slickIconColor = null;
        rec.headers = new List<NKS_TimelineController.Header>{
            new NKS_TimelineController.Header('HeaderA', true),
            new NKS_TimelineController.Header(Datetime.now(), false)
        };

        NKS_TimelineController.TimelineModel model = new NKS_TimelineController.TimelineModel(rec);

        Assert.isNotNull(model.record);
        Assert.isNotNull(model.theme);
        Assert.isNotNull(model.filter);
        Assert.areEqual('standard:messaging_user', model.theme.icon);
        Assert.areEqual('7D7D7D', model.theme.sldsTimelineItemColor);
        Assert.areEqual('Group1', model.filter.picklistValue1);
        Assert.isNull(model.filter.picklistValue2);
        Assert.isNull(model.filter.checkBoxValue);
        Assert.isFalse(model.filter.shown);
        Assert.areEqual('Summary', model.record.subtitleOverride);
        Assert.areEqual('ThreadExpandedTimeline', model.record.customComponent);
        Assert.areEqual(2, model.record.clampLines);
        Assert.isFalse(model.record.isDate);
        Assert.isNull(model.record.slickBackgroundColor);
        Assert.isNull(model.record.slickIconColor);
        Assert.areEqual(2, model.record.headers.size());
    }
}
