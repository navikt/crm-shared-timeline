import { LightningElement, api } from 'lwc';
import Id from '@salesforce/user/Id';

export default class TimelineMessagingMessageContainer extends LightningElement {
    @api message;
    userid;

    connectedCallback() {
        this.userid = Id;
    }

    //Indicate if the message is inbound or outbound, i.e left or right hand of the screen. tea
    get isoutbound() {
        return !this.message.CRM_External_Message__c;
    }

    get isevent() {
        return this.message.CRM_Type__c === 'Event';
    }
}
