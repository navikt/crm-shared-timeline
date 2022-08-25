public with sharing class Timeline_ThreadViewController {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getMessagesFromThread(Id threadId) {
        try {
            return mapMessageText(
            Database.query(
                Timeline_QueriesHelper.buildSoqlQuery(
                    //fields
                    'Id,' +
                    'CRM_Message_Content__r.CRM_Message_Text__c,' +
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
                    'CRM_Sent_date__c ASC'
                )
            )
        );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static List<SObject> mapMessageText(List<SObject> msgs){
        for(SObject msg : msgs){
            msg.put(
                'CRM_Message_Text__c',
                String.isBlank((String) msg.getSObject('CRM_Message_Content__r').get('CRM_Message_Text__c'))
                    ? Label.Timeline_Message_No_Access
                    : (String) msg.getSObject('CRM_Message_Content__r').get('CRM_Message_Text__c')
            );
        }
        return msgs;
    }
}
