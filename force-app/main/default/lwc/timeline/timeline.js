import { LightningElement, api, wire } from 'lwc';
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
import { publishToAmplitude } from 'c/amplitude';
import originalTemplate from './timeline.html';
import newDesignTemplate from './timelineNewDesign.html';

export default class Timeline extends LightningElement {
    @api headerIcon = 'custom:custom18';
    @api headerTitleNorwegian;
    @api headerTitleEnglish;
    @api objectApiName;
    @api recordId;
    @api recordWireFields;
    @api parentRecordId;
    @api timelineParentField = 'Id'; // Field for parent record id
    @api amountOfMonths = 3;
    @api amountOfMonthsToLoad = 3;
    @api amountOfMonthsToOpen = 2;
    @api amountOfRecords = 3;
    @api amountOfRecordsToLoad = 3;
    @api amountOfRecordsToOpen;
    @api configId = '';
    @api buttonIsHidden = false;
    @api customEmptySubtitle = '';
    @api timestamp = ''; // Deprecated
    @api logEvent = false;

    /******** Filter ********/
    @api filterIsActive = false;
    @api picklistFilter1Label;
    @api picklistFilter2Label;
    @api hideMyActivitiesFilter = false;
    @api includeAmountInTitle = false;
    @api design = 'DEFAULT';

    data;
    deWireResult;
    overdueData;
    recordsLoaded = 0;
    maxRecords = 0;
    openAccordionSections = [labels.overdue, labels.upcoming];
    allSections = [];
    labels = labels;
    filterProperties;
    header;
    error = false;
    errorMsg;
    empty = false;
    loading = true;
    finishedLoading = false;
    loadingStyle = 'height:5rem;width:24rem';
    accordionsAreSet = false;
    collapsed = false;
    collapseIcon = 'utility:justify_text';
    collapseText = labels.collapse;
    isRendered = false;
    masterData;

    render() {
        return this.design === 'NKS' ? newDesignTemplate : originalTemplate;
    }

    connectedCallback() {
        if (this.objectApiName && this.timelineParentField) {
            this.recordWireFields = [`${this.objectApiName}.${this.timelineParentField}`];
        }
        this.header =
            LANG === 'no' && this.headerTitleNorwegian
                ? this.headerTitleNorwegian
                : LANG === 'en-US' && this.headerTitleEnglish
                ? this.headerTitleEnglish
                : this.labels.activities;
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            loadScript(this, MOMENT_JS)
                .then(() => {
                    moment.locale(this.labels.MomentJsLanguage); // Global setting
                })
                .catch((error) => {
                    console.error('Error loading script: ', error);
                });
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$recordWireFields' })
    deWireRecord(result) {
        const { data, error } = result;
        if (data) {
            this.parentRecordId = getFieldValue(data, this.recordWireFields[0]);
        } else if (error) {
            console.error('Error getting parent Id: ', error);
        }
    }

    @wire(getTimelineData, {
        recordId: '$parentRecordId',
        amountOfMonths: '$amountOfMonths',
        amountOfMonthsToLoad: '$amountOfMonthsToLoad',
        configId: '$configId',
        includeSize: '$includeAmountInTitle'
    })
    deWire(result) {
        this.deWireResult = result;
        if (this.isRendered === true) {
            this.refreshData();
        }
        const { data, error } = result;
        if (data) {
            this.getTotalRecords();
            this.setData(result.data);
            this.setParams(this.data);
            this.setAccordions(this.data);
            this.countRecordsLoaded(this.data);
            this.setFilterProperties(this.data);
        } else if (error) {
            this.error = true;
            this.loading = false;
            this.setError(result.error);
        }
    }

    @wire(getTimelineObjects, { recordId: '$parentRecordId', configId: '$configId' })
    deWireObjects(result) {
        const { data, error } = result;
        if (data) {
            result.data.forEach((obj) => {
                if (obj.Timeline_Child__r.AutomaticRefresh__c) {
                    this.initSubscription(obj.Timeline_Child__r.AutomaticRefresh_PushTopicName__c);
                }
            });
        } else if (error) {
            console.error('Error getting timeline objects: ', error);
        }
    }

    setData(newData) {
        const newDataCopy = JSON.parse(JSON.stringify(newData));
        this.masterData = newDataCopy;

        try {
            if (!this.data) {
                const extraAmount =
                    newDataCopy[0]?.id === this.labels.overdue || newDataCopy[0]?.id === this.labels.upcoming ? 1 : 0;
                newDataCopy.slice(0, this.amountOfMonths + extraAmount);
            } else {
                newDataCopy.slice(0, this.data.length + this.amountOfMonthsToLoad);
            }
        } catch (error) {
            console.error('Error in setData:', error);
        }
        this.data = newDataCopy;
    }

    setParams(data) {
        this.loading = false;
        this.finishedLoading = true;
        this.loadingStyle = '';
        this.empty = data.length === 0;
    }

    setFilterProperties(data) {
        const filter = data
            .map(({ models }) => models)
            .flat(Infinity)
            .map(({ filter }) => filter);
        this.filterProperties = filter;
    }

    setAccordions(data) {
        if (this.accordionsAreSet) {
            return;
        }

        for (let index = 0; index < this.amountOfMonthsToOpen + 2; index++) {
            if (data[index] && this.openAccordionSections.length < this.amountOfMonthsToOpen + 2) {
                const element = data[index];
                if (element.id !== this.labels.overdue && element.id !== this.labels.upcoming) {
                    this.openAccordionSections.push(element.id);
                }
            }
        }
        this.accordionsAreSet = true;
    }

    resetAccordions(data) {
        setTimeout(() => {
            this.openAccordionSections = [labels.overdue, labels.upcoming];
            this.accordionsAreSet = false;
            this.setAccordions(data);
        });
    }

    countRecordsLoaded(data) {
        let recordsLoaded = 0;
        data.forEach((elem) => {
            this.allSections.push(elem.id);
            if (elem.id !== this.labels.overdue && elem.models) {
                recordsLoaded += elem.models.length;
            }
        });
        this.recordsLoaded = recordsLoaded;
    }

    getTotalRecords() {
        getTotalRecords({ recordId: this.parentRecordId, configId: this.configId })
            .then((result) => {
                this.maxRecords = result;
            })
            .catch((error) => {
                console.error('Error getting total records: ', error);
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

    expandCheck = (groupIndex, itemIndex) => {
        const totalModelsBeforeGroup = this.data
            .slice(0, groupIndex)
            .reduce((total, group) => total + group.models.length, 0);

        return (
            totalModelsBeforeGroup <= this.amountOfRecordsToLoad &&
            totalModelsBeforeGroup + itemIndex < this.amountOfRecordsToOpen
        );
    };

    setError(error) {
        if (error?.body?.exceptionType && error?.body?.message) {
            this.errorMsg = `[ ${error.body.exceptionType} ] : ${error.body.message}`;
        } else if (error?.body?.message) {
            this.errorMsg = `${error.body.message}`;
        } else if (typeof error === 'string') {
            this.errorMsg = error;
        } else {
            this.errorMsg = JSON.stringify(error);
        }
    }

    initSubscription(topicName) {
        const messageCallback = function (response) {
            this.refreshData();
        };
        subscribe('/topic/' + topicName + '?CreatedBy=' + userId, -1, messageCallback.bind(this));
    }

    loadMore() {
        this.loading = true;
        this.amountOfMonths = this.getMonthsToLoad();
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Load more (months)' });
        }
    }

    refreshData() {
        this.error = false;
        this.loading = true;
        this.getTotalRecords();

        return refreshApex(this.deWireResult)
            .then(() => {
                this.loading = false;
                if (this.logEvent) {
                    publishToAmplitude('Timeline', { type: 'Refresh list' });
                }

                if (this.deWireResult.data) {
                    this.setData(this.deWireResult.data);
                }
            })
            .catch((error) => {
                this.loading = false;
                console.error('Error refreshing data: ', error);
            });
    }

    collapseAccordions() {
        this.openAccordionSections = this.collapsed ? this.allSections : [];
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Collapse/open accordions' });
        }
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
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Toggle expand section' });
        }
    }

    handleFilter(e) {
        this.refreshData()
            .then(() => {
                const filteredData = this.template.querySelector('c-timeline-filter').filterRecords(this.masterData);
                this.data = filteredData;

                this.resetAccordions(this.data);
            })
            .catch((error) => {
                console.log('Error refreshing data: ', error);
            });
    }

    get hasMoreDataToLoad() {
        return this.recordsLoaded < this.maxRecords;
    }

    get showCreateRecords() {
        return !this.buttonIsHidden;
    }

    get isGrouped() {
        return !this.buttonIsHidden && this.filterIsActive;
    }

    get emptySubtitle() {
        return this.customEmptySubtitle?.length > 0 ? this.customEmptySubtitle : this.labels.emptySubtitle;
    }
}
