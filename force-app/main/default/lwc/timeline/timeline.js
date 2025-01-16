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
import defaultTemplate from './timeline.html';
import slickTemplate from './slick.html';

export default class Timeline extends LightningElement {
    @api headerIcon = 'custom:custom18';
    @api headerTitleNorwegian;
    @api headerTitleEnglish;
    @api objectApiName;
    @api recordId;
    @api recordWireFields;
    @api parentRecordId;
    @api timelineParentField = 'Id';
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
    @api design;
    @api filterIsActive = false;
    @api picklistFilter1Label;
    @api picklistFilter2Label;
    @api hideMyActivitiesFilter = false;
    @api includeAmountInTitle = false;

    data;
    deWireResult;
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
    isFiltered = false;

    render() {
        return this.design === 'Slick' ? slickTemplate : defaultTemplate;
    }

    connectedCallback() {
        this.initializeRecordWireFields();
        this.initializeHeader();
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            this.loadMomentJs();
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$recordWireFields' })
    handleRecordWire(result) {
        const { data, error } = result;
        if (data) {
            this.parentRecordId = getFieldValue(data, this.recordWireFields[0]);
        } else if (error) {
            this.handleError('Error fetching record data', error);
        }
    }

    @wire(getTimelineData, {
        recordId: '$parentRecordId',
        amountOfMonths: '$amountOfMonths',
        amountOfMonthsToLoad: '$amountOfMonthsToLoad',
        configId: '$configId',
        includeSize: '$includeAmountInTitle'
    })
    handleTimelineData(result) {
        this.deWireResult = result;
        const { data, error } = result;
        if (data) {
            this.processTimelineData(data);
        } else if (error) {
            this.handleError('Error fetching timeline data', error);
        }
    }

    @wire(getTimelineObjects, { recordId: '$parentRecordId', configId: '$configId' })
    handleTimelineObjects(result) {
        const { data, error } = result;
        if (data) {
            this.setupSubscriptions(data);
        } else if (error) {
            this.handleError('Error fetching timeline objects', error);
        }
    }

    // Initialization
    initializeRecordWireFields() {
        if (this.objectApiName && this.timelineParentField) {
            this.recordWireFields = [`${this.objectApiName}.${this.timelineParentField}`];
        }
    }

    initializeHeader() {
        this.header =
            LANG === 'no' && this.headerTitleNorwegian
                ? this.headerTitleNorwegian
                : LANG === 'en-US' && this.headerTitleEnglish
                  ? this.headerTitleEnglish
                  : this.labels.activities;
    }

    loadMomentJs() {
        loadScript(this, MOMENT_JS)
            .then(() => moment.locale(this.labels.MomentJsLanguage))
            .catch((error) => this.handleError('Error loading Moment.js', error));
    }

    initSubscription(topicName) {
        const messageCallback = function (response) {
            this.refreshData();
        };
        subscribe('/topic/' + topicName + '?CreatedBy=' + userId, -1, messageCallback.bind(this));
    }

    // Data Processing
    processTimelineData(data) {
        this.setParams(data);
        this.setData(data);
        this.setFilterProperties(data);
        this.setupAccordions(data);
        this.countRecordsLoaded(data);
        this.fetchTotalRecords();
    }

    setParams(data) {
        this.loading = false;
        this.finishedLoading = true;
        this.loadingStyle = '';
        this.empty = data.length === 0;
    }

    setData(newData) {
        let newDataCopy = JSON.parse(JSON.stringify(newData));
        this.masterData = newDataCopy;

        newDataCopy.forEach((group) => {
            group.size = group.models?.length || 0;
        });

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

    setFilterProperties(data) {
        this.filterProperties = data.flatMap(({ models }) => models.map(({ filter }) => filter));
    }

    setupAccordions(data) {
        if (this.accordionsAreSet) return;
        const maxSectionsToOpen = this.amountOfMonthsToOpen + 2;
        for (let index = 0; index < maxSectionsToOpen; index++) {
            const element = data[index];
            if (element && this.openAccordionSections.length < maxSectionsToOpen) {
                if (element.id !== this.labels.overdue && element.id !== this.labels.upcoming) {
                    this.openAccordionSections.push(element.id);
                }
            }
        }

        this.accordionsAreSet = true;
    }

    resetAccordions(data) {
        setTimeout(() => {
            this.openAccordionSections = [this.labels.overdue, this.labels.upcoming];
            this.accordionsAreSet = false;
            this.setupAccordions(data);
        });
    }

    countRecordsLoaded(data) {
        let recordsLoaded = 0;
        this.allSections = [];
        data.forEach((elem) => {
            this.allSections.push(elem.id);
            if (elem.id !== this.labels.overdue && elem.models) {
                recordsLoaded += elem.models.length;
            }
        });
        this.recordsLoaded = recordsLoaded;
    }

    fetchTotalRecords() {
        getTotalRecords({ recordId: this.parentRecordId, configId: this.configId })
            .then((result) => {
                this.maxRecords = result;
            })
            .catch((error) => this.handleError('Error fetching total records', error));
    }

    getMonthsToLoad() {
        let today = new Date();
        let lastRecordDate = new Date(this.data[this.data.length - 1].models[0].record.dateValueDb);

        let months = (today.getFullYear() - lastRecordDate.getFullYear()) * 12;
        months -= lastRecordDate.getMonth();
        months += today.getMonth();

        return months + this.amountOfMonthsToLoad;
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

    handleError(message, error) {
        console.error(message, error);
        this.errorMsg = error.body?.message || error.message || 'An unknown error occurred.';
        this.error = true;
    }

    loadMore() {
        this.loading = true;
        this.amountOfMonths = this.getMonthsToLoad();
        this.publishAmplitudeEvent('Load more (months)');
    }

    refreshData() {
        this.error = false;
        this.loading = true;
        return refreshApex(this.deWireResult)
            .then(() => {
                this.loading = false;
                if (this.deWireResult?.data) {
                    this.setData(this.deWireResult.data);
                    this.publishAmplitudeEvent('Refresh list');
                }
            })
            .catch((error) => this.handleError('Error refreshing timeline data', error));
    }

    collapseAccordions() {
        this.openAccordionSections = this.collapsed ? this.allSections : [];
        this.collapsed = !this.collapsed;
        this.publishAmplitudeEvent('Collapse/open accordions');
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
        this.publishAmplitudeEvent('Toggle expand section');
    }

    handleFilter(e) {
        this.refreshData()
            .then(() => {
                const filterTemplate = this.template.querySelector('c-timeline-filter');
                const filteredData = filterTemplate.filterRecords(this.masterData);
                this.data = filteredData;
                this.isFiltered = !filterTemplate.filterContainsAll();

                this.resetAccordions(this.data);
            })
            .catch((error) => {
                console.log('Error refreshing data: ', error);
            });
    }

    setupSubscriptions(objects) {
        objects.forEach((obj) => {
            if (obj.Timeline_Child__r.AutomaticRefresh__c) {
                this.initSubscription(obj.Timeline_Child__r.AutomaticRefresh_PushTopicName__c);
            }
        });
    }

    publishAmplitudeEvent(eventType) {
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: eventType });
        }
    }

    get hasMoreDataToLoad() {
        return this.recordsLoaded < this.maxRecords && !this.isFiltered;
    }

    get showCreateRecords() {
        return !this.buttonIsHidden;
    }

    get isGrouped() {
        return !this.buttonIsHidden && this.filterIsActive;
    }

    get emptySubtitle() {
        return this.customEmptySubtitle || this.labels.emptySubtitle;
    }

    get headerClass() {
        return `slds-grid custom-container${this.empty ? '' : ' border-bottom'}`;
    }
}
