import { LightningElement, api} from 'lwc';
export default class TimelineCustomView extends LightningElement {
    @api recordId;
    @api recordType;

    get isThread(){
        return this.recordType ==='Thread__c';
    }

    get isConversationNote(){
        return this.recordType ==='Conversation_Note__c';
    } 
}