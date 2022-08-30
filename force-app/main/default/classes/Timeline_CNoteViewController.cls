public with sharing class Timeline_CNoteViewController {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getConvNote(Id recordId){
        try {
            return Database.query(
                Timeline_QueriesHelper.buildSoqlQuery(
                    //fields
                    'Id,' +
                    'CRM_Message_Text__c,' +
                    'CRM_Date_Time_Registered__c,' +
                    'CRM_Created_By_Ident__c,' +
                    'CRM_Created_By_NAV_Unit__c,' +
                    'DIA_Theme_Name__c,' +
                    'CRM_Journal_Status_Formula__c,' +
                    'CRM_Read_Date__c,' +
                    'CreatedById',
                    //SObject
                    'Conversation_Note__c',
                    //Params
                    'Id = :recordId',
                    //Order
                    null
                )
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
