public with sharing class Timeline_ThreadViewController {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getMessagesFromThread(Id threadId) {
        try {
            return Database.query(
                Timeline_QueriesHelper.buildSoqlQuery(
                    //fields
                    'Id,' +
                    'CRM_Message_Text__c,' +
                    'CRM_Type__c,' +
                    'CRM_Event_Type__c,' +
                    'CRM_Sent_date__c,' +
                    'CRM_From_User__c,' +
                    'CRM_From_Contact__c,' +
                    'CRM_From_First_Name__c,' +
                    'CRM_External_Message__c,' +
                    'CRM_From_Label__c',
                    //SObject
                    'Message__c',
                    //Params
                    'CRM_Thread__c = :threadId',
                    //Order
                    'CRM_Sent_date__c ASC',
                    //RecordLimit
                    null
                )
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
