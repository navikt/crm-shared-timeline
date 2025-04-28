import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import formFactorPropertyName from '@salesforce/client/formFactor';
import * as helper from './helper';
import getTimelineObjects from '@salesforce/apex/Timeline_Controller.getTimelineObjects';
import newObj from '@salesforce/label/c.Timeline_New';
import { publishToAmplitude } from 'c/amplitude';

export default class TimelineNewObject extends NavigationMixin(LightningElement) {
    @api recordId;
    @api configId;
    @api isGrouped;
    @api logEvent;

    @track sObjects;
    error = false;
    containsMacros;
    newObj = newObj;

    @wire(getTimelineObjects, { recordId: '$recordId', configId: '$configId' })
    deWire(result) {
        if (result.data) {
            this.sObjects = result.data;

            for (let i = 0; i < result.data.length; i++) {
                const elem = result.data[i];
                if (elem.IsMacro__c) {
                    this.containsMacros = true;
                }
            }
        } else if (result.error) {
            this.error = true;
        }
    }

    createRecord(event) {
        const row = this.sObjects[event.target.dataset.index];
        const override = this.sObjects[event.target.dataset.index].CreateableObject_NoOverride__c == false ? '0' : '1'; // == false to fallback to true if null
        this.publishAmplitudeEvent('Clicked "New" button');

        if (formFactorPropertyName !== 'Small') {
            // PC AND TABLET

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: row.Timeline_Child__r.SObjectName__c,
                    actionName: 'new'
                },
                state: {
                    nooverride: override,
                    recordTypeId: row.Timeline_Child__r.CreateableObject_RecordType__c,
                    navigationLocation: 'RELATED_LIST',
                    useRecordTypeCheck: 1,
                    defaultFieldValues: helper.getFieldValues(row, this.recordId)
                }
            });
        }
    }

    publishAmplitudeEvent(eventType) {
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: eventType });
        }
    }

    get buttonMenuStyle() {
        return this.isGrouped ? 'bttn-grouped' : 'slds-p-left_small';
    }
}
