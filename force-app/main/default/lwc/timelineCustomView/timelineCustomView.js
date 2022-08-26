import { LightningElement, api} from 'lwc';


export default class TimelineCustomView extends LightningElement {
    @api recordId;
    @api recordType;

    get isThread(){
        return this.recordtype ==='Thread__c';
    }
    get isConversationNote(){
        return this.recordtype ==='Conversation_Note__c';
    }
    
}