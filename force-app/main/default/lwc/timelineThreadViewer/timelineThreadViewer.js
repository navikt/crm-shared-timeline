import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getmessages from '@salesforce/apex/Timeline_ThreadViewController.getMessagesFromThread';

const FIELDS = [ 'Thread__c.CRM_Journal_Status_Formula__c' ];

export default class TimelineThreadViewer extends LightningElement {
    @api recordId;
    @track messages;
    journalforing;
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
    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$FIELDS'
    })
    deWireRecord({ data, error }) {
        if (data) {
            this.journalforing = getFieldValue(data, FIELDS[0]);
        } else if (error) {
            //Something went terribly wrong
        }
    }
}
