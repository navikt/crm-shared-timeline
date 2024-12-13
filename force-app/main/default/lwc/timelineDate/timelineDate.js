import { LightningElement, api } from 'lwc';

export default class TimelineDate extends LightningElement {
    @api dateValueDb;
    @api overdue;
    @api isDate;
    @api period;
    @api labels;

    get getDateFormat() {
        try {
            if (this.period === this.labels.upcoming || this.period === this.labels.overdue) {
                var settings = this.isDate
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
                return moment(this.dateValueDb).calendar(null, settings);
            } else {
                return moment(this.dateValueDb)
                    .format(this.isDate ? 'L' : 'L [' + this.labels.timePrefix + '] HH:mm')
                    .replaceAll('/', '.');
            }
        } catch (error) {
            console.log('Geir');
            return this.dateValueDb;
        }
    }
}
