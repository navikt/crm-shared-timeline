import { LightningElement, api, track, wire } from 'lwc';
import getmessages from '@salesforce/apex/Timeline_ThreadViewController.getMessagesFromThread';

export default class TimelineThreadViewer extends LightningElement {
    @api threadid;
    @track messages;
    hasMessages = false;
    error;

    @wire(getmessages, { threadId: '$threadid' }) //Calls apex and extracts messages related to this record
    wiremessages(result) {
        if (result.error) {
            this.error = result.error;
            console.log('Error: ' + JSON.stringify(error, null, 2));
        } else if (result.data) {
            this.messages = result.data;
            hasMessages = true;
            console.log(result.data);
        }
    }
}
