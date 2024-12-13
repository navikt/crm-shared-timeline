global with sharing class Timeline_Model implements Comparable {
    @AuraEnabled
    public TimelineParent__mdt config { get; set; }

    @AuraEnabled
    public Theme theme { get; set; }
    @AuraEnabled
    public Record record { get; set; }
    @AuraEnabled
    public Filter filter { get; set; }

    public Boolean descending = true;

    public class Theme {
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String sldsTimelineItemColor;
    }

    public class Record {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public String sObjectKind;
        @AuraEnabled
        public String sObjectLabel;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public List<String> expandedFields;

        @AuraEnabled
        public Datetime dateValueDb;
        @AuraEnabled
        public String dateValue;
        @AuraEnabled
        public Boolean isDate;
        @AuraEnabled
        public Integer durationInMinute;

        @AuraEnabled
        public String assignee;
        @AuraEnabled
        public Id assigneeId;
        @AuraEnabled
        public String relatedUser;
        @AuraEnabled
        public Id relatedUserId;
        @AuraEnabled
        public String subtitle;

        @AuraEnabled
        public Boolean overdue;
        @AuraEnabled
        public Boolean lastElement;

        @AuraEnabled
        public Boolean allowAutoOpen;

        @AuraEnabled
        public String subtitleOverride;

        @AuraEnabled
        public String customComponent;

        @AuraEnabled
        public List<Header> headers;
    }

    public class Header {
        @AuraEnabled
        public Object header;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public boolean isString;
        @AuraEnabled
        public boolean isDatetime;
        @AuraEnabled
        public boolean isDate;

        public Header(String header, sObject sObj) {
            this.header = get(sObj, header);
            Schema.DescribeFieldResult fi = sObj.getSObjectType()
                .getDescribe()
                .fields.getMap()
                .get(header)
                .getDescribe();
            this.type = fi.getType().name();
            this.isString = this.type == 'STRING';
            this.isDatetime = this.type == 'DATETIME';
            this.isDate = this.type == 'DATE';
        }
    }

    public class Filter {
        @AuraEnabled
        public String picklistValue1;
        @AuraEnabled
        public String picklistValue2;
        @AuraEnabled
        public String checkBoxValue;
    }

    // sorting algorithm
    global Integer compareTo(Object compareTo) {
        Timeline_Model compare = (Timeline_Model) compareTo;
        if (record.dateValueDb == compare.record.dateValueDb) {
            return 0;
        }
        if (descending && record.dateValueDb < compare.record.dateValueDb) {
            return 1;
        } // sort descending, newest first
        if (!descending && record.dateValueDb > compare.record.dateValueDb) {
            return 1;
        } // sort ascending, oldest first (technically, record in 2 days is "older" than one in 4 days)

        return -1;
    }

    public Timeline_Model(TimelineParent__mdt config, SObject sObj) {
        this.config = config;
        Record record = new Record();
        Theme theme = new Theme();

        record.expandedFields = String.isNotBlank(config.Timeline_Child__r.ExpandedFieldsToDisplay__c)
            ? config.Timeline_Child__r.ExpandedFieldsToDisplay__c.deleteWhiteSpace().split(',')
            : new List<String>();
        record.relatedUserId = config.Timeline_Child__r.SObjectRelatedUserId__c != null
            ? (Id) get(sObj, config.Timeline_Child__r.SObjectRelatedUserId__c)
            : null;
        record.assigneeId = config.SObjectAssigneeId__c != null ? (Id) get(sObj, config.SObjectAssigneeId__c) : null;
        record.title = (String) get(sObj, config.Timeline_Child__r.SObjectTitle__c.split(',')[0]);
        record.durationInMinute = (Integer) get(sObj, 'DurationInMinutes');
        record.allowAutoOpen = config.Timeline_Child__r.AllowAutoOpen__c;
        record.sObjectKind = config.Timeline_Child__r.SObjectName__c;
        record.sObjectLabel = sObj.getSObjectType().getDescribe().getLabel();
        record.type = config.Timeline_Child__r.SObjectTypeValue__c;
        record.recordId = sObj.Id;
        record.isDate = getIsDate(config, sObj, record);
        record.overdue = getIsOverdue(config, sObj, record);
        record.dateValueDb = getDateValue(config, sObj, record);
        record.subtitleOverride = (String) get(sObj, config.Timeline_Child__r.SObjectSubtitle__c); // To add subtitle for samtale
        record.customComponent = config.Timeline_Child__r.CustomComponent__c;

        record.headers = new List<Header>();
        for (String headerField : config.Timeline_Child__r.SObjectTitle__c.split(',')) {
            record.headers.add(new Header(headerField, sObj));
        }

        theme.sldsTimelineItemColor = config.Timeline_Child__r.SLDS_Timeline_Color__c;
        theme.icon = getIconValue(config, sObj);

        this.filter = getFilter(sObj);
        this.record = record;
        this.theme = theme;
    }

    public static Datetime getDateValue(TimelineParent__mdt config, SObject sObj, Record record) {
        Datetime dateValueDb = (Datetime) get(sObj, config.Timeline_Child__r.SObjectDateField__c);

        if (dateValueDb == null && record.sObjectKind == 'Task') {
            dateValueDb = (Datetime) Date.valueOf(get(sObj, 'CreatedDate'));
        } else if (config.Timeline_Child__r.SObjectName__c == 'Event' && !record.isDate) {
            dateValueDb = (Datetime) get(sObj, 'ActivityDateTime');
        }

        return dateValueDb;
    }

    public static Boolean getIsDate(TimelineParent__mdt config, SObject sObj, Record record) {
        Boolean isDate = config.Timeline_Child__r.SObjectDateFieldIsDate__c;
        if (config.Timeline_Child__r.SObjectName__c == 'Event') {
            isDate = (Boolean) get(sObj, 'IsAllDayEvent');
        }
        // else if ( config.Timeline_Child__r.SObjectName__c == 'Task' && (Datetime) get( sObj, config.Timeline_Child__r.SObjectDateField__c ) == null ) { isDate = false; }

        return isDate;
    }

    public static Boolean getIsOverdue(TimelineParent__mdt config, SObject sObj, Record record) {
        Boolean isOVerdue = false;

        if (record.sObjectKind == 'Task' && record.isDate) {
            if (get(sObj, 'Status') != 'Completed' && record.dateValueDb < Date.today()) {
                isOverdue = true;
            }
        } else if (record.sObjectKind == 'Task' && !record.isDate) {
            if (get(sObj, 'Status') != 'Completed' && record.dateValueDb < System.now()) {
                isOverdue = true;
            }
        }

        return isOverdue;
    }

    public static String getIconValue(TimelineParent__mdt config, SObject sObj) {
        if (config.Timeline_Child__r.SLDS_Icon__c.contains(':')) {
            return config.Timeline_Child__r.SLDS_Icon__c;
        }
        return (String) get(sObj, config.Timeline_Child__r.SLDS_Icon__c);
    }

    public static Object get(SObject sObj, String field) {
        try {
            return sObj.get(field);
        } catch (Exception e) {
            return null;
        }
    }

    private Filter getFilter(SObject sObj) {
        Filter filter = new Filter();

        filter.checkBoxValue = getFilterProperty(sObj, config.Timeline_Child__r.FilterableCheckbox__c);
        filter.picklistValue1 = getFilterProperty(sObj, config.Timeline_Child__r.FilterablePicklist1__c);
        filter.picklistValue2 = getFilterProperty(sObj, config.Timeline_Child__r.FilterablePicklist2__c);

        return filter;
    }

    private String getFilterProperty(SObject sObj, String fieldName) {
        if (fieldName == null) {
            return null;
        }
        String value = (String) sObj.get(fieldName);
        return PicklistEntryRepository.getLabel(sObj, fieldName, value);
    }
}
