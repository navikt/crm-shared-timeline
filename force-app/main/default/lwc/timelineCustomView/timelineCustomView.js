import { LightningElement, api} from 'lwc';


export default class TimelineCustomView extends LightningElement {
    @api recordid;
    @api recordtype;

    get isThread(){
        return recordType ==='Thread__c';
    }
    
}