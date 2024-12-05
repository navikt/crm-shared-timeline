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
        return this.isOpen ? 'slds-accordion__section slds-is-open' : 'slds-accordion__section slds-is-closed';
    }

    get isExpanded() {
        return this.expanded.toString();
    }

    get iconPath() {
        return this.expanded
            ? 'M20.6466 18.5233L16 13.1541L11.3534 18.5233C11.1688 18.7079 10.8611 18.7079 10.6765 18.5233L10 17.8464C9.81539 17.6618 9.81539 17.3541 10 17.1695L15.3236 11.8464C15.5082 11.6618 15.8159 11.6618 16.0005 11.8464L21.3241 17.1695C21.5088 17.3541 21.5088 17.6618 21.3241 17.8464L20.6466 18.5233Z'
            : 'M21.6466 16.4767L16.3389 21.8459C16.1543 22.0305 15.8466 22.0305 15.662 21.8459L10.3543 16.4767C10.1697 16.2921 10.1697 15.9844 10.3543 15.7998L11.0312 15.1228C11.2158 14.9382 11.5235 14.9382 11.7081 15.1228L15.662 19.1382C15.8466 19.3228 16.1543 19.3228 16.3389 19.1382L20.2927 15.1536C20.4774 14.969 20.7851 14.969 20.9697 15.1536L21.6466 15.8305C21.8004 16.0151 21.8004 16.2921 21.6466 16.4767Z';
    }
}
