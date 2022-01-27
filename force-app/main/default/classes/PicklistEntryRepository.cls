public with sharing class PicklistEntryRepository {
    private static Map<Schema.SObjectType, Map<String, List<Schema.PicklistEntry>>> cachedEntries = new Map<Schema.SObjectType, Map<String, List<Schema.PicklistEntry>>>();

    public static List<Schema.PicklistEntry> getEntries(SObject sObj, String fieldName) {
        Schema.SObjectType sObjectType = sObj.getSObjectType();

        if (!cachedEntries.containsKey(sObjectType) || !cachedEntries.get(sObjectType).containsKey(fieldName)) {
            populateEntries(sObjectType, fieldName);
        }

        return cachedEntries.get(sObjectType).get(fieldName);
    }

    public static String getLabel(SObject sObj, String fieldName, String value) {
        List<Schema.PicklistEntry> entries = getEntries(sObj, fieldName);

        for (Schema.PicklistEntry e : entries) {
            if (e.getValue() == value) {
                return e.getLabel();
            }
        }

        return value;
    }

    private static void populateEntries(Schema.SObjectType type, String fieldName) {
        Schema.DescribeSObjectResult sObjResult = type.getDescribe();
        Schema.DescribeFieldResult fieldResult = sObjResult.fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();

        if (!cachedEntries.containsKey(type)) {
            cachedEntries.put(type, new Map<String, List<Schema.PicklistEntry>>());
        }
        cachedEntries.get(type).put(fieldName, entries);
    }
}
