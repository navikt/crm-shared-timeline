import { LightningElement, api } from 'lwc';
import Id from '@salesforce/user/Id';

export default class TimelineMessagingMessageContainer extends LightningElement {
    showpopover = false;
    isreply = false;
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

    //if there is a reply, hide it
    get showReplyButton() {
        return typeof this.message.Previous_Message__c !== 'undefined';
    }

    showdata() {
        this.showpopover = true;
    }
    hidedata() {
        this.showpopover = false;
    }
    replythreadPressed() {
        const selectedEvent = new CustomEvent('answerpressed', { detail: this.message.Id });
        this.dispatchEvent(selectedEvent);
    }
}
