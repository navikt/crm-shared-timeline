import { LightningElement, api, track } from 'lwc';

export default class TimelineGroup extends LightningElement {
    @api group;
    @api labels;
    @api amountOfRecords;
    @api amountOfRecordsToLoad;
    @api openAccordionSections;
    @api expandCheck;
    @api groupIndex;

    amount;
    empty = false;

    connectedCallback() {
        this.amount = this.amountOfRecords;
    }

    renderedCallback() {
        this.empty = this.group.models.length === 0;
    }

    get showViewMore() {
        return this.amount < this.group.models.length;
    }

    viewMore() {
        this.amount += this.amountOfRecordsToLoad;
    }

    viewAll() {
        this.amount = this.group.models.length;
    }

    groupLevelExpandCheck = (itemIndex) => {
        return this.expandCheck(this.groupIndex, itemIndex);
    };

    get total() {
        return this.group.models.length;
    }

    get isOpen() {
        return this.openAccordionSections.includes(this.group.id);
    }

    get isClosed() {
        return !this.isOpen;
    }
}
