@isTest
public with sharing class PicklistEntryRepositoryTest {
    @isTest
    static void getEntriesPicklist() {
        SObject sObj = (SObject) new Account();
        String fieldName = 'AccountSource';

        Schema.SObjectType sObjectType = sObj.getSObjectType();
        Schema.DescribeSObjectResult sObjResult = sObjectType.getDescribe();
        Schema.DescribeFieldResult fieldResult = sObjResult.fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> expectedEntries = fieldResult.getPicklistValues();

        List<Schema.PicklistEntry> entries = PicklistEntryRepository.getEntries(sObj, fieldName);

        System.assertEquals(expectedEntries, entries, 'Expected entries returned');
    }

    @isTest
    static void getLabelPicklist() {
        SObject sObj = (SObject) new Account();
        String fieldName = 'AccountSource';

        Schema.SObjectType sObjectType = sObj.getSObjectType();
        Schema.DescribeSObjectResult sObjResult = sObjectType.getDescribe();
        Schema.DescribeFieldResult fieldResult = sObjResult.fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> expectedEntries = fieldResult.getPicklistValues();

        String label = PicklistEntryRepository.getLabel(sObj, fieldName, expectedEntries[0].getValue());

        System.assertEquals(expectedEntries[0].getLabel(), label, 'Correct label returned');
    }

    @isTest
    static void getEntriesNonPicklist() {
        SObject sObj = (SObject) new Account();
        String fieldName = 'Name';

        List<Schema.PicklistEntry> entries = PicklistEntryRepository.getEntries(sObj, fieldName);

        System.assertEquals(0, entries.size(), 'Not a picklist, no entries returned');
    }

    @isTest
    static void getLabelNonPicklist() {
        SObject sObj = (SObject) new Account();
        String fieldName = 'Name';

        String label = PicklistEntryRepository.getLabel(sObj, fieldName, 'test');

        System.assertEquals('test', label, 'Not a picklist, field value returned');
    }
}
