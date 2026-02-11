global with sharing class Timeline_Validator {
    // Check if current user can read the SObject (doesn't check access to data)
    public static Boolean sObjectIsAccessible(String sObjectTypeStr) {
        Schema.SObjectType sObjType = ((SObject) Type.forName(sObjectTypeStr).newInstance()).getSObjectType();
        return sObjType.getDescribe().isAccessible();
    }

    // Check if current user can create the SObject
    public static Boolean sObjectIsCreateable(String sObjectTypeStr) {
        Schema.SObjectType sObjType = ((SObject) Type.forName(sObjectTypeStr).newInstance()).getSObjectType();
        return sObjType.getDescribe().isCreateable();
    }

    // Check if current user can read the content in the field
    public static Boolean fieldIsAccessible(String sObjectTypeStr, String sObjectFieldStr) {
        Schema.SObjectType sObjType = ((SObject) Type.forName(sObjectTypeStr).newInstance()).getSObjectType();
        Schema.DescribeFieldResult sObjField = sObjType.getDescribe()
            .fields.getMap()
            .get(sObjectFieldStr)
            .getDescribe();

        return sObjField.isAccessible();
    }

    // Check if current user can write data to the field
    public static Boolean fieldIsCreateable(String sObjectTypeStr, String sObjectFieldStr) {
        Schema.SObjectType sObjType = ((SObject) Type.forName(sObjectTypeStr).newInstance()).getSObjectType();
        Schema.DescribeFieldResult sObjField = sObjType.getDescribe()
            .fields.getMap()
            .get(sObjectFieldStr)
            .getDescribe();

        return sObjField.isCreateable();
    }
}
