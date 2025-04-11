import { LightningElement, api } from 'lwc';
import userId from '@salesforce/user/Id';
import LANG from '@salesforce/i18n/lang';
import SAVE_LABEL from '@salesforce/label/c.Timeline_Save';
import RESET_LABEL from '@salesforce/label/c.Timeline_Reset';
import CANCEL_LABEL from '@salesforce/label/c.Timeline_Cancel';
import { publishToAmplitude } from 'c/amplitude';
import defaultTemplate from './timelineFilter.html';
import slickTemplate from './slick.html';

export default class TimelineFilter extends LightningElement {
    @api filterProperties;
    @api isGrouped;
    @api picklistFilter1Label;
    @api picklistFilter2Label;
    @api showHideLabel;
    @api hideMyActivitiesFilter;
    @api logEvent;
    @api design;

    currentUser = userId;
    isActive = false;
    draftFilter = {};
    filter = {};
    labels = { SAVE_LABEL, RESET_LABEL, CANCEL_LABEL };

    render() {
        return this.design === 'Slick' ? slickTemplate : defaultTemplate;
    }

    toggle() {
        this.isActive = !this.isActive;
        if (this.isActive) this.publishAmplitudeEvent('Click on filter button');
    }

    handleSave() {
        this.updateFilter();
        this.toggle();
        this.publishAmplitudeEvent('Save filter changes');
    }

    handleCancel() {
        this.draftFilter = {};
        this.toggle();
        this.publishAmplitudeEvent('Cancel filtering');
    }

    handleReset() {
        this.draftFilter = {};
        this.filter = {};
        this.updateFilter();
        this.toggle();
        this.publishAmplitudeEvent('Reset filtering');
    }

    handleChange(e) {
        this.draftFilter[e.target.dataset.id] = e.detail.value;
        this.publishAmplitudeEvent('Changing filters');
        if (this.design === 'Slick') this.updateFilter();
    }

    handleCheckboxChange(e) {
        this.draftFilter[e.target.dataset.id] = e.detail.checked || undefined;
    }

    checkboxChange(event) {
        this.filter.shown = event.target.checked;
        this.updateFilter();
    }

    updateFilter() {
        this.filter = { ...this.filter, ...this.draftFilter };
        this.dispatchEvent(new CustomEvent('filterchange', { detail: this.filter }));
    }

    publishAmplitudeEvent(action) {
        if (this.logEvent) publishToAmplitude('Timeline', { type: action });
    }

    @api
    filterRecords(records) {
        return records.map(this.filterGroupModels.bind(this)).filter((group) => group !== null);
    }

    @api
    filterContainsAll() {
        return Object.values(this.filter).includes('Alle');
    }

    filterGroupModels(group) {
        const filteredModels = group.models.filter(this.isModelValid.bind(this));
        group.models = filteredModels;
        group.size = filteredModels.length;

        return group.models.length ? group : null;
    }

    isModelValid(model) {
        const { record, filter } = model;
        return (
            (!this.isFilterable('this_user') || record.assigneeId === this.currentUser) &&
            (!this.isFilterable('checkBoxFilter') || this.filter.checkBoxFilter.includes(filter.checkBoxValue)) &&
            (!this.isFilterable('picklistFilter1') ||
                this.filter.picklistFilter1 === filter.picklistValue1 ||
                this.filter.picklistFilter1 === 'Alle') &&
            (!this.isFilterable('picklistFilter2') ||
                this.filter.picklistFilter2 === filter.picklistValue2 ||
                this.filter.picklistFilter2 === 'Alle') &&
            (this.filter.shown || !filter.shown)
        );
    }

    isFilterable(property) {
        return Boolean(this.filter[property]?.length);
    }

    getValues(property) {
        const uniqueValues = this.filterProperties
            ?.map(({ [property]: value }) => value)
            .filter((value, index, self) => value !== undefined && self.indexOf(value) === index)
            .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

        return uniqueValues?.map((value) => ({ label: value, value })) || [];
    }

    enhanceValues(values) {
        return this.design === 'Slick' && values.length ? [{ label: 'Alle', value: 'Alle' }, ...values] : values;
    }

    get picklistFilter1() {
        const values = this.enhanceValues(this.getValues('picklistValue1'));
        return values.length ? values : null;
    }

    get picklistFilter2() {
        const values = this.getValues('picklistValue2');
        return values.length ? values : null;
    }

    get checkBoxFilter() {
        const values = this.getValues('checkBoxValue');
        return values.length ? values : null;
    }

    get selectedCheckboxes() {
        return this.getSelectedFilter('checkBoxFilter', []);
    }

    get selectedPicklistFilter1() {
        return this.getSelectedFilter('picklistFilter1');
    }

    get selectedPicklistFilter2() {
        return this.getSelectedFilter('picklistFilter2');
    }

    get myActivitiesFilter() {
        return this.getSelectedFilter('this_user', false);
    }

    get buttonStyle() {
        return this.isGrouped ? 'bttn-grouped slds-p-left_small' : 'slds-m-left_x-small';
    }

    get containerStyle() {
        return this.isGrouped ? 'container bttn-grouped-container' : 'container';
    }

    get myActivitiesLabel() {
        return LANG === 'no' ? 'Kun mine aktiviteter' : 'My activities';
    }

    get picklist1Label() {
        return this.getLabel('picklistFilter1Label');
    }

    get picklist2Label() {
        return this.getLabel('picklistFilter2Label');
    }

    get showHideCheckbox() {
        return this.filterProperties?.some((filter) => filter.shown);
    }

    getSelectedFilter(property, defaultValue = null) {
        return this.filter[property] === undefined ? defaultValue : this.filter[property];
    }

    getLabel(property, defaultValue = ' ') {
        return this[property] === undefined ? defaultValue : this[property];
    }
}
