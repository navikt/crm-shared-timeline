import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getmessages from '@salesforce/apex/Timeline_ThreadViewController.getMessagesFromThread';

export default class TimelineThreadViewer extends LightningElement {
    @api recordId;
    @track messages;
    recordWireFields;
    journalforing;
    hasMessages = false;
    error;

    connectedCallback() {
        //getRecord requires field in array
        this.recordWireFields = ['Thread__c.CRM_Journal_Status_Formula__c'];
    }

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
        fields: '$recordWireFields'
    })
    deWireRecord(result) {
        if (result.data) {
            this.setJournalForing(getFieldValue(result.data, this.recordWireFields[0]));
        } else if (result.error) {
            //Something went terribly wrong
        }
    }

    setJournalForing(text) {
        let parser = new DOMParser();
        const doc = parser.parseFromString(text, 'text/html');
        let imgs = doc.getElementsByTagName('img');
        [...imgs].forEach((img) => {
            img.setAttribute('aria-hidden', 'true');
        });
        this.journalforing = doc.body.innerHTML;
    }
}
