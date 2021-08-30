import { LightningElement, track, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import LANG from '@salesforce/i18n/lang';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import { subscribe } from 'lightning/empApi';

import MOMENT_JS from '@salesforce/resourceUrl/moment';
import getTimelineData from '@salesforce/apex/Timeline_Controller.getTimelineData';
import getTotalRecords from '@salesforce/apex/Timeline_Controller.getTotalRecords';
import getTimelineObjects from '@salesforce/apex/Timeline_Controller.getTimelineObjects';

import labels from './labels';

export default class Timeline extends LightningElement {
    // config settings
    @api headerIcon = 'custom:custom18';
    @api headerTitleNorwegian;
    @api headerTitleEnglish;
    @api objectApiName;
    @api recordId;
    @api recordWireFields;
    @api parentRecordId;
    @api timelineParentField = 'Id'; //Determine which field to use ase the timeline parent record id

    @api amountOfMonths = 3;
    @api amountOfMonthsToLoad = 3;
    @api amountOfRecords = 3;
    @api amountOfRecordsToLoad = 3;
    @api configId = '';

    @api timestamp = ''; // ! deprecated but cannot be removed

    @track data;
    @track deWireResult;
    @track overdueData;

    @track recordsLoaded = 0;
    @track maxRecords = 0;

    header;
    error = false;
    errorMsg;
    empty = false;

    loading = true;
    finishedLoading = false;
    loadingStyle = 'height:5rem;width:24rem';

    @track openAccordionSections = [labels.overdue, labels.upcoming];
    accordionsAreSet = false;
    @track allSections = [];
    @track labels = labels;

    collapsed = false;
    collapseIcon = 'utility:justify_text';
    collapseText = labels.collapse;

    isRendered = false;

    connectedCallback() {
        //getRecord requires field in array
        this.recordWireFields = [this.objectApiName + '.' + this.timelineParentField];

        if (LANG === 'no' && this.headerTitleNorwegian !== undefined) {
            this.header = this.headerTitleNorwegian;
        } else if (LANG === 'en-US' && this.headerTitleEnglish !== undefined) {
            this.header = this.headerTitleEnglish;
        } else {
            this.header = this.labels.activities;
        }
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;

            loadScript(this, MOMENT_JS).then(() => {
                moment.locale(this.labels.MomentJsLanguage);
            });
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$recordWireFields'
    })
    deWireRecord({ data, error }) {
        if (data) {
            this.parentRecordId = getFieldValue(data, this.recordWireFields[0]);
        } else if (error) {
            //Something went terribly wrong
        }
    }

    @wire(getTimelineData, {
        recordId: '$parentRecordId',
        amountOfMonths: '$amountOfMonths',
        amountOfMonthsToLoad: '$amountOfMonthsToLoad',
        configId: '$configId'
    })
    deWire(result) {
        this.deWireResult = result;
        if (this.isRendered === true) {
            //Handling data refresh if wire is triggered by for example an update action that can result in new records in the timeline
            this.refreshData();
        }

        if (result.data) {
            //Moved get total records here as it is now dependent on the parentRecordId which is not set until above wire runs
            this.getTotalRecords();
            this.setData(result.data);
            this.setParams(this.data);
            this.setAccordions(this.data);
            this.countRecordsLoaded(this.data);
        } else if (result.error) {
            this.error = true;
            this.loading = false;
            this.setError(result.error);
        }
    }

    // ----------------------------------- //
    // ------------- HELPERS ------------- //
    // ----------------------------------- //

    setData(newData) {
        let newDataCopy = JSON.parse(JSON.stringify(newData));

        // try to process, fallbacks to original data which is always OK
        try {
            // first run, remove all that exceeds amountOfMonths
            if (!this.data) {
                let amount = 0;
                if (newDataCopy[0]) {
                    if (newDataCopy[0].id == this.labels.overdue || newDataCopy[0].id == this.labels.upcoming) {
                        amount++;
                    }
                }
                if (newDataCopy[1]) {
                    if (newDataCopy[1].id == this.labels.upcoming) {
                        amount++;
                    }
                }

                newDataCopy.splice(this.amountOfMonths + amount);
            }

            // loading using load more button, take the previous amount + amountOfMonthsToLoad, and remove all that exceeds the amount
            else {
                newDataCopy.splice(this.data.length + this.amountOfMonthsToLoad);
            }
        } catch (error) {}

        this.data = newDataCopy;
    }

    setParams(data) {
        this.loading = false;
        this.finishedLoading = true;
        this.loadingStyle = '';
        this.empty = data.length === 0;
    }

    setAccordions(data) {
        if (this.accordionsAreSet) {
            return;
        }

        for (let index = 0; index < 4; index++) {
            if (data[index] && this.openAccordionSections.length < 4) {
                const element = data[index];

                if (element.id != this.labels.overdue && element.id != this.labels.upcoming) {
                    this.openAccordionSections.push(element.id);
                }
            }
        }

        this.accordionsAreSet = true;
    }

    countRecordsLoaded(data) {
        let recordsLoaded = 0;

        for (let i = 0; i < data.length; i++) {
            const elem = data[i];
            this.allSections.push(elem.id);

            if (elem.id != this.labels.overdue && elem.models) {
                recordsLoaded += elem.models.length;
            }
        }

        this.recordsLoaded = recordsLoaded;
    }

    getTotalRecords() {
        getTotalRecords({
            recordId: this.parentRecordId,
            configId: this.configId
        }).then((result) => {
            this.maxRecords = result;
        });
    }

    getMonthsToLoad() {
        let today = new Date();
        let lastRecordDate = new Date(this.data[this.data.length - 1].models[0].record.dateValueDb);

        let months;
        months = (today.getFullYear() - lastRecordDate.getFullYear()) * 12;
        months -= lastRecordDate.getMonth();
        months += today.getMonth();

        return parseInt(months) + this.amountOfMonthsToLoad;
    }

    setError(error) {
        if (error.body && error.body.exceptionType && error.body.message) {
            this.errorMsg = `[ ${error.body.exceptionType} ] : ${error.body.message}`;
        } else if (error.body && error.body.message) {
            this.errorMsg = `${error.body.message}`;
        } else if (typeof error === String) {
            this.errorMsg = error;
        } else {
            this.errorMsg = JSON.stringify(error);
        }
    }

    // used to listen to new records, to automatically update timeline with new records
    // --------------------------------------------------------------------------------

    @wire(getTimelineObjects, { recordId: '$parentRecordId', configId: '$configId' })
    deWireObjects(result) {
        if (result.data) {
            result.data.forEach((obj) => {
                if (obj.Timeline_Child__r.AutomaticRefresh__c) {
                    this.initSubscription(obj.Timeline_Child__r.AutomaticRefresh_PushTopicName__c);
                }
            });
        }
    }

    initSubscription(topicName) {
        const messageCallback = function (response) {
            this.refreshData();
        };
        subscribe('/topic/' + topicName + '?CreatedBy=' + userId, -1, messageCallback.bind(this));
    }

    // ----------------------------------- //
    // ------------- BUTTONS ------------- //
    // ----------------------------------- //

    loadMore(event) {
        this.loading = true;
        this.amountOfMonths = this.getMonthsToLoad();
    }

    refreshData() {
        this.error = false;
        this.loading = true;
        this.getTotalRecords();

        return refreshApex(this.deWireResult).then(() => {
            this.loading = false;
        });
    }

    collapseAccordions() {
        this.openAccordionSections = this.collapsed ? this.allSections : [];
    }

    handleSectionToggle(event) {
        this.openAccordionSections = event.detail.openSections;

        if (this.openAccordionSections.length === 0) {
            this.collapseIcon = 'utility:filter';
            this.collapseText = this.labels.expand;
            this.collapsed = true;
        } else {
            this.collapseIcon = 'utility:justify_text';
            this.collapseText = this.labels.collapse;
            this.collapsed = false;
        }
    }

    // ----------------------------------- //
    // ------------- GETTERS ------------- //
    // ----------------------------------- //

    get hasMoreDataToLoad() {
        // recordsLoaded is less than maxRecords, means there's more records to load
        return this.recordsLoaded < this.maxRecords;
    }

    get showCreateRecords() {
        // return formFactorPropertyName !== 'Small';
        return true; // temp fix
    }
}
