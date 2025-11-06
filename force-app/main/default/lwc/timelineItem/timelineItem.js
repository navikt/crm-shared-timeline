import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { publishToAmplitude } from 'c/amplitude';
import slickLayout from './slick.html';
import defaultLayout from './timelineItem.html';
import sharedStyling from './sharedStyling.css';

export default class TimelineItem extends NavigationMixin(LightningElement) {
    static stylesheets = [sharedStyling];

    @api row;
    @api recordId;
    @api labels;
    @api amount;
    @api index;
    @api period;
    @api groupLevelExpandCheck;
    @api logEvent;
    @api design;
    @api isLast;

    expanded = false;
    loadingDetails = false;
    timelineColor = 'slds-timeline__item_expandable';

    connectedCallback() {
        this.itemLevelExpandCheck();
        if (this.row.theme.sldsTimelineItemColor != null) {
            this.timelineColor = '	background-color: #' + this.row.theme.sldsTimelineItemColor + ';';
        }        
    }

    render() {
        return this.design === 'Slick' ? slickLayout : defaultLayout;
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
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Navigate to record' });
        }
    }

    toggleExpand() {
        this.expanded = !this.expanded;
        this.loadingDetails = this.expanded;
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: 'Toggle expand section details' });
        }
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

    get dateFormat() {
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
        return this.expandedFieldsToDisplay.length > 0 || this.isCustom;
    }

    get assistiveSubtitle() {
        const ASSISTIVE_TEXT_LENGTH = 150;
        let tmp = new DOMParser().parseFromString(this.row.record.subtitleOverride, 'text/html');
        let textContent = tmp.body.textContent || '';

        return textContent.length > ASSISTIVE_TEXT_LENGTH
            ? textContent.slice(0, ASSISTIVE_TEXT_LENGTH) + '...'
            : textContent;
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
        return this.row.record.subtitleOverride != null;
    }

    get isOverrideAndNotExpanded() {
        return this.isOverride && !this.expanded;
    }

    get formattedSubtitleOverride() {
        if (this.row.record.subtitleOverride && this.row.record.sObjectKind === 'Thread__c') {
            return this.formatThreadDate(this.row.record.subtitleOverride);
        }
        return this.row.record.subtitleOverride;
    }

    get isCustom() {
        return this.row.record.customComponent != null && this.row.record.customComponent != '';
    }

    get clampOverride() {
        return this.row.record.clampLines != null ? `--lwc-lineClamp: ${this.row.record.clampLines}` : null;
    }

    get headers() {
        if (!this.row?.record?.headers) return null;
        const headers = this.row.record.headers;
        return headers.map((b, index) => {
            if (!b.isString) {
                return { ...b, isLast: index === headers.length - 1 };
            }
            let parser = new DOMParser();
            const doc = parser.parseFromString(b.header, 'text/html');
            let imgs = doc.getElementsByTagName('img');
            [...imgs].forEach((img) => {
                img.setAttribute('aria-hidden', 'true');
            });
            return { ...b, header: doc.body.innerHTML, isLast: index === headers.length - 1 };
        });
    }

    get slickMediaBodyStyle() {
        return this.row?.record?.slickBackgroundColor != null
            ? '--override-border-width: 0px; --override-background-color: #' + this.row.record.slickBackgroundColor
            : '';
    }

    get slickIconColor() {
        return this.row?.record?.slickIconColor != null
            ? '--slds-c-icon-color-background: #' + this.row.record.slickIconColor
            : '';
    }

    formatThreadDate(htmlContent) {
        try {
            // Parse the HTML content from CRM_Conversation_Summary__c field on Thread
            let parser = new DOMParser();
            const doc = parser.parseFromString(htmlContent, 'text/html');
            
            // Find the date in the <b> tag
            const dateElement = doc.querySelector('b');
            if (dateElement && dateElement.textContent) {
                const dateText = dateElement.textContent.trim();
                
                // Parse the date format ex: 2025-09-23 07:43:46
                const dateMatch = dateText.match(/(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})/);
                if (dateMatch) {
                    const dateValue = new Date(dateMatch[0]);
                    
                    let formattedDate;
                    if (typeof moment !== 'undefined' && this.labels) {
                        formattedDate = moment(dateValue)
                            .format('L [' + this.labels.timePrefix + '] HH:mm:ss')
                            .replaceAll('/', '.');
                    } else {
                        // Fallback to "kl." format
                        const [, year, month, day, hours, minutes, seconds] = dateMatch;
                        const timePrefix = this.labels?.timePrefix || 'kl.';
                        formattedDate = `${day}.${month}.${year} ${timePrefix} ${hours}:${minutes}:${seconds}`;
                    }
                    
                    dateElement.innerHTML = formattedDate;
                    return doc.body.innerHTML;
                }
            }
        } catch (error) {
            console.error('Error formatting thread date:', error);
        }
        return htmlContent;
    }
}
