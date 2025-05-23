import { LightningElement, api } from 'lwc';
export default class TimelineCustomView extends LightningElement {
    @api recordId;
    @api customComponentName;
    @api logEvent;

    customComponent;

    connectedCallback() {
        import('c/' + this.customComponentName).then(({ default: ctor }) => (this.customComponent = ctor));
    }
}
