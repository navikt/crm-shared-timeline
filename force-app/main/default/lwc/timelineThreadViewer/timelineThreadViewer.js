import { LightningElement, api, track, wire } from 'lwc';
import getmessages from '@salesforce/apex/Timeline_ThreadViewController.getMessagesFromThread';

export default class TimelineThreadViewer extends LightningElement {
    @api threadid;
    @track messages;
    error;

    @wire(getmessages, { threadId: '$threadId' }) //Calls apex and extracts messages related to this record
    wiremessages(result) {
        if (result.error) {
            this.error = result.error;
            console.log('Error: ' + JSON.stringify(error, null, 2));
        } else if (result.data) {
            this.messages = result.data;
            console.log(result.data);
        }
    }
}
