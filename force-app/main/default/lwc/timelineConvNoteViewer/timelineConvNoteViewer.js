import { LightningElement, api, wire } from 'lwc';
import formatDate from 'c/formattedDate'
import getconvnote from '@salesforce/apex/Timeline_CNoteViewController.getConvNote';

export default class TimelineConvNoteViewer extends LightningElement {
    @api recordId;

    conversationNote;
    error = false;

    @wire(getconvnote, { recordId: '$recordId' }) //Calls apex and gets conversation note record
    wireNotes(result) {
        if (result.error) {
            this.error = true;
            console.log('Error: ' + JSON.stringify(result.error, null, 2));
        } else if (result.data) {
            this.conversationNote = result.data[0];
        }
    }

    get isLoading() {
        return !this.conversationNote && this.error === false;
    }

    get lest(){
        return conversationNote.CRM_Read_Date__c ?
         '<img border="0" style="height:24px; width:24px;" alt="Lest" src="/logos/Custom/Circle_Green/logo.png">' + ' Lest: ' + formatDate(conversationNote.CRM_Read_Date__c) :
         '<img border="0" style="height:24px; width:24px;" alt="Ulest" src="/logos/Custom/Circle_Green/logo.png">' + ' Ulest'
    }
}
