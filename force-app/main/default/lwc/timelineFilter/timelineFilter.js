import { LightningElement, api } from 'lwc';
import userId from '@salesforce/user/Id';
import LANG from '@salesforce/i18n/lang';
import save from '@salesforce/label/c.Timeline_Save';
import reset from '@salesforce/label/c.Timeline_Reset';
import cancel from '@salesforce/label/c.Timeline_Cancel';
import { publishToAmplitude } from 'c/amplitude';

export default class TimelineFilter extends LightningElement {
    @api filterProperties;
    @api isGrouped;
    @api picklistFilter1Label;
    @api picklistFilter2Label;
    @api hideMyActivitiesFilter;
    @api logEvent;

    currentUser = userId;
    isActive = false;
    draftFilter = {};
    filter = {};

    toggle() {
        this.isActive ? (this.isActive = false) : (this.isActive = true);
        if (this.isActive && this.logEvent){
            publishToAmplitude('Timeline', { type: 'Click on filter button' });
        }
    }

    handleSave() {
        this.updateFilter();
        this.toggle();
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Save filter changes' });
        }
    }

    handleCancel() {
        this.draftFilter = {};
        this.toggle();
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Cancel filtering' });
        }
    }

    handleReset() {
        this.draftFilter = {};
        this.filter = {};
        this.updateFilter();
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Reset filtering' });
        }
    }

    handleChange(e) {
        this.draftFilter[e.target.dataset.id] = e.detail.value;
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Changing filters' });
        }
    }

    handleCheckboxChange(e) {
        this.draftFilter[e.target.dataset.id] = e.detail.checked ? true : undefined;
    }

    updateFilter() {
        this.filter = { ...this.filter, ...this.draftFilter };
        const event = new CustomEvent('filterchange', { detail: this.filter });
        this.dispatchEvent(event);
    }

    @api filterRecords(records) {
        if (Object.entries(this.filter).length < 1) return records;
        const dataCopy = [...records];

        for (let i = 0; i < dataCopy.length; i++) {
            for (let j = 0; j < dataCopy[i].models.length; j++) {
                let record = dataCopy[i].models[j].record;
                let filter = dataCopy[i].models[j].filter;

                if (this.isFilterable('this_user') && record.assigneeId !== this.currentUser) {
                    dataCopy[i].models.splice(j, 1);
                    j--;
                } else if (
                    this.isFilterable('checkBoxFilter') &&
                    !this.filter.checkBoxFilter.includes(filter.checkBoxValue)
                ) {
                    dataCopy[i].models.splice(j, 1);
                    j--;
                } else if (
                    this.isFilterable('picklistFilter1') &&
                    this.filter.picklistFilter1 !== filter.picklistValue1
                ) {
                    dataCopy[i].models.splice(j, 1);
                    j--;
                } else if (
                    this.isFilterable('picklistFilter2') &&
                    this.filter.picklistFilter2 !== filter.picklistValue2
                ) {
                    dataCopy[i].models.splice(j, 1);
                    j--;
                }
            }
            // remove if object not longer has any models
            if (dataCopy[i].models.length < 1) {
                dataCopy.splice(i, 1);
                i--;
            }
        }
        return dataCopy;
    }

    isFilterable(property) {
        if (this.filter[property] === undefined || this.filter[property].length < 1) {
            return false;
        }
        return true;
    }

    getValues(property) {
        if (this.filterProperties === undefined) return false;

        const values = [];
        this.filterProperties.forEach((value) => {
            if (value[property] === undefined) return;
            if (values.map((item) => item.value).includes(value[property]) === true) return;
            values.push({ label: value[property], value: value[property] });
        });
        if (values.length < 1) return false;
        values.sort((val1, val2) => {
            return val1.label.toLowerCase() > val2.label.toLowerCase() ? 1 : -1; //val1 and val2 should never be equal as they are uniquely mapped;
        });
        return values;
    }

    get picklistFilter1() {
        return this.getValues('picklistValue1');
    }

    get picklistFilter2() {
        return this.getValues('picklistValue2');
    }

    get checkBoxFilter() {
        return this.getValues('checkBoxValue');
    }

    get selectedCheckboxes() {
        if (this.filter.checkBoxFilter === undefined) return [];
        return this.filter.checkBoxFilter;
    }

    get selectedPicklistFilter1() {
        if (this.filter.picklistFilter1 === undefined) return null;
        return this.filter.picklistFilter1;
    }

    get selectedPicklistFilter2() {
        if (this.filter.picklistFilter2 === undefined) return null;
        return this.filter.picklistFilter2;
    }

    get myActivitiesFilter() {
        if (this.filter.this_user === undefined) return false;
        return this.filter.this_user;
    }

    get buttonStyle() {
        return this.isGrouped ? 'bttn-grouped slds-p-left_small' : 'slds-m-left_x-small';
    }

    get containerStyle() {
        return this.isGrouped ? 'container bttn-grouped-container' : 'container';
    }

    get saveLabel() {
        return save;
    }

    get resetLabel() {
        return reset;
    }

    get cancelLabel() {
        return cancel;
    }

    get myActivitiesLabel() {
        if (LANG === 'no') return 'Kun mine aktiviteter';
        return 'My activities';
    }

    get picklist1Label() {
        if (this.picklistFilter1Label === undefined) return ' ';
        return this.picklistFilter1Label;
    }

    get picklist2Label() {
        if (this.picklistFilter2Label === undefined) return ' ';
        return this.picklistFilter2Label;
    }
}
