import { LightningElement, api } from 'lwc';
import defaultLayout from './timelineGroup.html';
import slickLayout from './slick.html';

export default class TimelineGroup extends LightningElement {
    @api group;
    @api labels;
    @api amountOfRecords;
    @api amountOfRecordsToLoad;
    @api openAccordionSections;
    @api expandCheck;
    @api groupIndex;
    @api logEvent;
    @api design;
    @api includeAmountInTitle;

    amount;
    expanded;

    render() {
        return this.design === 'Slick' ? slickLayout : defaultLayout;
    }

    connectedCallback() {
        this.amount = this.amountOfRecords || 0;
        this.expanded = this.isOpen;
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

    toggleButton() {
        this.expanded = !this.expanded;
    }

    get showViewMore() {
        return this.amount < (this.group?.models?.length || 0);
    }

    get total() {
        return this.group?.models?.length || 0;
    }

    get isOpen() {
        return this.openAccordionSections.includes(this.group.id);
    }

    get isClosed() {
        return !this.isOpen;
    }

    get hasModals() {
        return this.group.models.length;
    }

    get isEmpty() {
        return this.group?.models?.length <= 0;
    }

    get accordionSectionClass() {
        return `slds-accordion__section ${this.isOpen ? 'slds-is-open' : 'slds-is-closed'}`;
    }

    get isExpanded() {
        return this.expanded.toString();
    }

    get label() {
        return `${this.group.name} ${this.includeAmountInTitle ? `(${this.group.size})` : ''}`;
    }
}
