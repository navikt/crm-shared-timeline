import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {trackAmplitudeEvent} from 'c/amplitude';
export default class TimelineItem extends NavigationMixin(LightningElement) {
    @api row;
    @api recordId;
    @api labels;
    @api amount;
    @api index;
    @api period;
    @api groupLevelExpandCheck;

    expanded = false;
    loadingDetails = false;
    timelineColor = 'slds-timeline__item_expandable';

    connectedCallback() {
        this.itemLevelExpandCheck();
        if (this.row.theme.sldsTimelineItemColor != null) {
            this.timelineColor = '	background-color: #' + this.row.theme.sldsTimelineItemColor + ';';
        }
    }

    get expandedFieldsToDisplay() {
        let fieldArray = [];
        let fieldCounter = 0;
        if (this.row && this.row.record.expandedFields && !this.row.record.expandedFields.length !== 0) {
            this.row.record.expandedFields.forEach((field) => {
                fieldArray.push({ id: fieldCounter, apiName: field });
                fieldCounter++;
            });
        }
        return fieldArray;
    }

    get getDateFormat() {
        // TODO mouseover to get relative fromNow()

        try {
            if (this.period === this.labels.upcoming || this.period === this.labels.overdue) {
                var settings = this.row.record.isDate
                    ? {
                          sameDay: '[' + this.labels.today + ']',
                          nextDay: '[' + this.labels.tomorrow + ']',
                          nextWeek: 'dddd',
                          lastDay: '[' + this.labels.yesterday + ']',
                          lastWeek: '[' + this.labels.last + '] dddd',
                          sameElse: 'DD.MM.YYYY'
                      }
                    : {
                          sameDay: '[' + this.labels.today + ' ' + this.labels.timePrefix + '] HH:mm',
                          nextDay: '[' + this.labels.tomorrow + ' ' + this.labels.timePrefix + '] HH:mm',
                          nextWeek: 'DD.MM.YYYY [' + this.labels.timePrefix + '] HH:mm',
                          lastDay: '[' + this.labels.yesterday + ' ' + this.labels.timePrefix + '] HH:mm',
                          lastWeek: 'DD.MM.YYYY [' + this.labels.timePrefix + '] HH:mm',
                          sameElse: 'DD.MM.YYYY [' + this.labels.timePrefix + '] HH:mm'
                      };
                return moment(this.row.record.dateValueDb).calendar(null, settings);
            } else {
                return moment(this.row.record.dateValueDb)
                    .format(this.row.record.isDate ? 'L' : 'L [' + this.labels.timePrefix + '] HH:mm')
                    .replaceAll('/', '.');
            }
        } catch (error) {
            console.log('error: ' + error);
            return this.row.record.dateValueDb;
        }
    }

    get showRow() {
        return this.index < this.amount;
    }

    get isTask() {
        return this.row.record.sObjectKind === 'Task';
    }

    get isExpandable() {
        return this.expandedFieldsToDisplay.length > 0 || this.isCustom ? true : false;
    }

    get assistiveSubtitle(){
        const ASSISTIVE_TEXT_LENGTH = 150;
        let tmp = new DOMParser().parseFromString(this.row.record.subtitleOverride, 'text/html');
        let textContent = tmp.body.textContent || "";
        
        return textContent.length > ASSISTIVE_TEXT_LENGTH ? textContent.slice(0, ASSISTIVE_TEXT_LENGTH) + '...': textContent;
    }

    itemLevelExpandCheck() {
        if (this.isExpandable && this.row.record.allowAutoOpen && this.groupLevelExpandCheck(this.index)) {
            this.toggleExpand();
        }
    }

    openRecord(event) {
        event.stopPropagation(); //Prevent this click from propagating into
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.row.record.recordId,
                objectApiName: this.row.record.sObjectType,
                actionName: 'view'
            }
        });
        trackAmplitudeEvent('Timeline Event', {type: 'Navigate to record'});
    }

    toggleExpand() {
        this.expanded = !this.expanded;
        this.loadingDetails = this.expanded;
        trackAmplitudeEvent('Timeline Event', {type: 'Toggle expand section details'});
    }

    detailsLoaded() {
        this.loadingDetails = false;
    }

    toggleDetailSection() {
        this.expanded = !this.expanded;
    }

    openUser(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                objectApiName: 'User',
                actionName: 'view'
            }
        });
    }

    get expandIcon() {
        return this.expanded === true ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get isAssigneeAUser() {
        return 'assigneeId' in this.row.record;
    }

    get isRelatedUserAUser() {
        return 'relatedUserId' in this.row.record;
    }

    get isOverride() {
        return this.row.record.subtitleOverride != null ? (this.expanded === true ? false : true) : false;
    }
    get isCustom() {
        return this.row.record.useCustomView;
    }
}
