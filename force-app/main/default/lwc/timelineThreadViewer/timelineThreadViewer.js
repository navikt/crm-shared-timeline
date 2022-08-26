import { LightningElement, api, track, wire } from 'lwc';
import getmessages from '@salesforce/apex/Timeline_ThreadViewController.getMessagesFromThread';

export default class TimelineThreadViewer extends LightningElement {
    @api recordId;
    @track messages;
    hasMessages = false;
    error;

    @wire(getmessages, { threadId: '$recordId' }) //Calls apex and extracts messages related to this record
    wiremessages(result) {
        if (result.error) {
            this.error = result.error;
            console.log('Error: ' + JSON.stringify(result.error, null, 2));
        } else if (result.data) {
            this.messages = result.data;
            this.hasMessages = true;
        }
    }
}
