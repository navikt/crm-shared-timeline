import { LightningElement, api, wire } from 'lwc';
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
}
