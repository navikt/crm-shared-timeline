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
/*
    public static List<Message> mapSObjectsToMessage(List<SObject> sObjs){
        List<Message> msgs = new List<Message>();
        for(SObject sObj : sObjs){
            Message msg = new Message();
            
            msg.Id = sObj.Id;
            msg.CRM_Message_Text__c = (String) Timeline_Model.get(sObj,'CRM_Message_Text__c');
            msg.CRM_Type__c = (String) Timeline_Model.get(sObj,'CRM_Type__c');
            msg.CRM_Event_Type__c = (String) Timeline_Model.get(sObj,'CRM_Event_Type__c');
            msg.CRM_Sent_date__c = (Datetime) Timeline_Model.get(sObj,'CRM_Sent_date__c');
            msg.CRM_From_User__c = (Id) Timeline_Model.get(sObj,'CRM_From_User__c');
            msg.CRM_From_Contact__c = (Id) Timeline_Model.get(sObj,'CRM_From_Contact__c');
            msg.CRM_From_First_Name__c = (String) Timeline_Model.get(sObj,'CRM_From_First_Name__c');
            msg.CRM_External_Message__c = (Boolean) Timeline_Model.get(sObj,'CRM_External_Message__c');
            msg.CRM_From_Label__c = (String) Timeline_Model.get(sObj,'CRM_From_Label__c');

            msgs.add(msg);
        }
    return msgs;
    

    }

    public class Message {
        @AuraEnabled
        public Id Id;
        @AuraEnabled
        public String CRM_Message_Content_Text;
        @AuraEnabled
        public String CRM_Type;
        @AuraEnabled
        public String CRM_Event_Type;
        @AuraEnabled
        public Datetime CRM_Sent_date;
        @AuraEnabled
        public Id CRM_From_User;
        @AuraEnabled
        public Id CRM_From_Contact;
        @AuraEnabled
        public String CRM_From_First_Name;
        @AuraEnabled
        public Boolean CRM_External_Message;
        @AuraEnabled
        public String CRM_From_Label;
    }
    */
}
