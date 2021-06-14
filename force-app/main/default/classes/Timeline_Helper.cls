public with sharing class Timeline_Helper {
    private static final Boolean IS_NORWEGIAN = UserInfo.getLanguage() == 'no';
    private static final List<String> MONTH_NAME = new List<String>{
        null,
        'Januar',
        'Februar',
        'Mars',
        'April',
        'Mai',
        'Juni',
        'Juli',
        'August',
        'September',
        'Oktober',
        'November',
        'Desember'
    };
    private static final List<String> MONTH_NAME_EN = new List<String>{
        null,
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
    };
    private static final Integer MONTH_CAP = 1212;

    // --------------------------------------------------------------------------------- //
    // ------------------------- ACTIVITY + OVERDUE + UPPCOMING ------------------------ //
    // --------------------------------------------------------------------------------- //

    public static List<Timeline_Model> getActivity(
        List<TimelineParent__mdt> sObjectsToQuery,
        String recordId,
        Integer amountOfMonths
    ) {
        List<String> query = Timeline_Queries.createSoqlQueries(sObjectsToQuery, recordId, amountOfMonths);
        List<SObject> sObjects = Timeline_Queries.getSObjectsFromQueries(query);
        List<Timeline_Model> data = createTimelineData(sObjectsToQuery, sObjects);

        return data;
    }

    public static Timeline_ModelList getUpcomingActivity(List<Timeline_Model> models) {
        List<Timeline_Model> data = new List<Timeline_Model>();
        for (Timeline_Model model : models) {
            Datetime d = model.config.Timeline_Child__r.SObjectDateFieldIsDate__c ? System.today() : System.now();
            if (model.record.dateValueDb >= d) {
                data.add(model);
            }
        }

        return new Timeline_ModelList(Label.Timeline_Upcoming, Label.Timeline_Upcoming, data, false);
    }

    public static Timeline_ModelList getOverdueActivity(
        String recordId,
        String parentSObjectType,
        List<TimelineParent__mdt> sObjectsToQuery
    ) {
        Map<String, TimelineParent__mdt> sObjectsToQueryMap = getMapOfTimelineConfig(sObjectsToQuery);
        if (!sObjectsToQueryMap.containsKey('Task')) {
            return null;
        } // return if tasks not configured
        sObjectsToQuery = new List<TimelineParent__mdt>{ sObjectsToQueryMap.get('Task') }; // get only tasks

        List<String> query = Timeline_Queries.getOverdueQuery(sObjectsToQuery, recordId);
        List<SObject> sObjects = Timeline_Queries.getSObjectsFromQueries(query);
        List<Timeline_Model> data = createTimelineData(sObjectsToQuery, sObjects);
        data = getOwnerAndContactNames(data);
        data.sort();

        return new Timeline_ModelList(Label.Timeline_Overdue, Label.Timeline_Overdue, data, true);
    }

    // --------------------------------------------------------------------------------- //
    // ------------------------------- DATA MANAPULATION ------------------------------- //
    // --------------------------------------------------------------------------------- //

    public static List<Timeline_Model> createTimelineData(
        List<TimelineParent__mdt> sObjectsToQuery,
        List<SObject> sObjects
    ) {
        List<Timeline_Model> data = new List<Timeline_Model>();
        Map<String, TimelineParent__mdt> sObjectsToQueryMap = getMapOfTimelineConfig(sObjectsToQuery);

        for (SObject sObj : sObjects) {
            String childSObjectKind = getSOjectTypeFromRecordId((Id) sObj.get('Id'));
            String childSObjectType = '';
            for (TimelineParent__mdt mdt : sObjectsToQueryMap.values()) {
                if (mdt.Timeline_Child__r.SObjectName__c == childSObjectKind) {
                    if (mdt.Timeline_Child__r.SObjectTypeField__c != null) {
                        String type = (String) sObj.get(mdt.Timeline_Child__r.SObjectTypeField__c);
                        if (type != null) {
                            childSObjectType = type;
                            break;
                        }
                    }
                }
            }

            TimelineParent__mdt mdt = sObjectsToQueryMap.get(childSObjectKind + childSObjectType);
            if (mdt == null) {
                mdt = sObjectsToQueryMap.get(childSObjectKind);
            }
            if (mdt != null) {
                data.add(new Timeline_Model(mdt, sObj));
            }
        }

        return data;
    }

    public static List<Timeline_Model> reloadUntilDataFetched(
        List<TimelineParent__mdt> sObjectsToQuery,
        String recordId,
        Integer amountOfMonths,
        Integer amountOfMonthsToLoad,
        Integer iteration,
        Integer totalRecords,
        List<Timeline_Model> activity
    ) {
        activity.sort();

        List<Timeline_ModelList> activityDivided = Timeline_Helper.getRecordsDividedIntoMonths(activity);
        Integer currentAmount = countRecords(activityDivided);
        Integer amountOfSObjectsToQuery = sObjectsToQuery.size();
        Integer queriesScheduled = amountOfSObjectsToQuery + 4; // getting the overdue records later + fetching owners (1 query) and contacts (1 query) for all records, twice (4 queries)
        Integer totalQueryAmount = Limits.getQueries() + queriesScheduled;
        Integer maxQueriesLeft = 100 - amountOfSObjectsToQuery - 4; // 100 is max queries per transaction, removing the remaining queries needed and an extra buffer of four queries

        Boolean allRecordsLoaded = currentAmount >= totalRecords;
        Boolean moreRecordsToQuery = activityDivided.size() <= amountOfMonths;
        Boolean queryLimitsWillNotExceed = totalQueryAmount < maxQueriesLeft;

        // 2^6 = 5,33 years, which is probably not needed to query, but allowed
        // 2^7 = 10,66 years, which is NOT needed to query, thus, return
        if (iteration >= 8) {
            return activity;
        }

        // if all records found, return
        if (allRecordsLoaded) {
            return activity;
        }

        // if there are more months to query, and query limits will not be exceeded
        if (moreRecordsToQuery && queryLimitsWillNotExceed) {
            Integer newAmount = getAmountToLoad(amountOfMonthsToLoad, iteration);

            List<Timeline_Model> newActivities = Timeline_Helper.getActivity(sObjectsToQuery, recordId, newAmount);

            return reloadUntilDataFetched(
                sObjectsToQuery,
                recordId,
                amountOfMonths,
                amountOfMonthsToLoad,
                iteration + 1,
                totalRecords,
                newActivities
            );
        }

        // else return original list, either due to query limits exceeded or enough months were loaded
        return activity;
    }

    public static Integer countRecords(List<Timeline_ModelList> activityDivided) {
        Integer totalRecords = 0;

        for (Timeline_ModelList activity : activityDivided) {
            if (activity.models != null) {
                totalRecords += activity.models.size();
            }
        }

        return totalRecords;
    }

    public static Integer getAmountToLoad(Integer amountOfMonthsToLoad, Integer iteration) {
        Integer newAmount = Integer.valueOf(Math.pow(amountOfMonthsToLoad, iteration));

        newAmount = newAmount <= MONTH_CAP ? newAmount : MONTH_CAP;

        return newAmount;
    }

    public static List<Timeline_ModelList> getRecordsDividedIntoMonths(List<Timeline_Model> data) {
        Map<String, List<Timeline_Model>> modelsSeparatedByMonth = new Map<String, List<Timeline_Model>>();

        for (Timeline_Model model : data) {
            Datetime d = model.config.Timeline_Child__r.SObjectDateFieldIsDate__c ? System.today() : System.now();

            if (model.record.dateValueDb < d) {
                String key = model.record.dateValueDb.month() + '-' + model.record.dateValueDb.year();
                if (modelsSeparatedByMonth.containsKey(key)) {
                    modelsSeparatedByMonth.get(key).add(model);
                } else {
                    modelsSeparatedByMonth.put(key, new List<Timeline_Model>{ model });
                }
            }
        }

        List<Timeline_ModelList> results = new List<Timeline_ModelList>();

        for (String key : modelsSeparatedByMonth.keySet()) {
            Datetime d = modelsSeparatedByMonth.get(key)[0].record.dateValueDb;
            String name = getMonth(d.month()) + ' ' + d.year();
            results.add(new Timeline_ModelList(key, name, modelsSeparatedByMonth.get(key), true));
        }

        return results;
    }

    public static List<Timeline_ModelList> addAllActivities(
        Timeline_ModelList upcoming,
        Timeline_ModelList overdue,
        List<Timeline_ModelList> activityDivided
    ) {
        List<Timeline_ModelList> data = new List<Timeline_ModelList>();

        if (overdue != null && overdue.models != null) {
            if (overdue.models.size() > 0) {
                data.add(overdue);
            }
        }
        if (upcoming.models != null) {
            if (upcoming.models.size() > 0) {
                data.add(upcoming);
            }
        }

        data.addAll(activityDivided);

        data = removeConfig(data);

        return data;
    }

    // --------------------------------------------------------------------------------- //
    // ----------------------------- OWNER AND CONTACT NAME ---------------------------- //
    // --------------------------------------------------------------------------------- //

    public static List<Timeline_Model> getOwnerAndContactNames(List<Timeline_Model> models) {
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for (Timeline_Model model : models) {
            if (model.record.assigneeId != null) {
                ownerIds.add(model.record.assigneeId);
            }
            if (model.record.relatedUserId != null) {
                contactIds.add(model.record.relatedUserId);
            }
        }

        Map<Id, String> ownerNames = getOwnerName(ownerIds);
        Map<Id, String> contactNames = getContactName(contactIds);

        for (Timeline_Model model : models) {
            if (model.record.dateValueDb < DateTime.now() && !model.record.overdue) {
                model.record.subtitle = IS_NORWEGIAN
                    ? model.config.Timeline_Child__r.SubtitlePastNorwegian__c
                    : model.config.Timeline_Child__r.SubtitlePastEnglish__c;
            } else {
                model.record.subtitle = IS_NORWEGIAN
                    ? model.config.Timeline_Child__r.SubtitleFutureNorwegian__c
                    : model.config.Timeline_Child__r.SubtitleFutureEnglish__c;
            }

            if (model.record.assigneeId != null) {
                if (ownerNames.containsKey(model.record.assigneeId)) {
                    model.record.assignee = ownerNames.get(model.record.assigneeId);
                    if (model.record.assigneeId == UserInfo.getUserId()) {
                        model.record.assigneeId = null;
                    }
                }
            }

            if (model.record.relatedUserId != null) {
                if (contactNames.containsKey(model.record.relatedUserId)) {
                    model.record.relatedUser = contactNames.get(model.record.relatedUserId);
                    if (model.record.relatedUser != null) {
                        model.record.subtitle += IS_NORWEGIAN
                            ? ' ' +
                              returnValueIfNotNull(model.config.Timeline_Child__r.SubtitleRelatedUserPrepositionNor__c)
                            : ' ' +
                              returnValueIfNotNull(model.config.Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c);
                    }
                }
            } else if (model.record.sObjectKind == 'Task' && model.record.type == 'Call') {
                model.record.relatedUser = Label.Timeline_Unknown.toLowerCase();
            }
        }

        return models;
    }

    public static Map<Id, String> getOwnerName(Set<Id> ownerIds) {
        Map<Id, String> results = new Map<Id, String>();
        Map<Id, User> users = new Map<Id, User>([SELECT Name FROM User WHERE Id IN :ownerIds]);

        for (Id ownerId : ownerIds) {
            if (ownerId == UserInfo.getUserId()) {
                results.put(ownerId, Label.Timeline_You);
            } else if (users.containsKey(ownerId)) {
                results.put(ownerId, users.get(ownerId).Name);
            }
        }

        return results;
    }

    public static Map<Id, String> getContactName(Set<Id> contactIds) {
        Map<Id, String> results = new Map<Id, String>();
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Name FROM Contact WHERE Id IN :contactIds]);

        for (Id contactId : contactIds) {
            if (contacts.containsKey(contactId)) {
                results.put(contactId, contacts.get(contactId).Name);
            }
        }

        return results;
    }

    // --------------------------------------------------------------------------------- //
    // --------------------------- CUSTMOM METADATA FUNCTIONS -------------------------- //
    // --------------------------------------------------------------------------------- //

    public static List<Timeline_ModelList> removeConfig(List<Timeline_ModelList> data) {
        for (Timeline_ModelList d : data) {
            for (Timeline_Model model : d.models) {
                model.config = null;
            }
        }

        return data;
    }

    public static Map<String, TimelineParent__mdt> getMapOfTimelineConfig(List<TimelineParent__mdt> sObjectsToQuery) {
        Map<String, TimelineParent__mdt> sObjectsToQueryMap = new Map<String, TimelineParent__mdt>();

        for (TimelineParent__mdt mdt : sObjectsToQuery) {
            String mdtType = mdt.Timeline_Child__r.SObjectTypeValue__c != null &&
                mdt.Timeline_Child__r.SObjectTypeValue__c != 'null'
                ? mdt.Timeline_Child__r.SObjectTypeValue__c
                : '';
            if (mdtType.contains(';')) {
                List<String> typeList = mdtType.split(';');
                for (String type : typeList) {
                    sObjectsToQueryMap.put(mdt.Timeline_Child__r.SObjectName__c + type, mdt);
                }
            } else {
                sObjectsToQueryMap.put(mdt.Timeline_Child__r.SObjectName__c + mdtType, mdt);
            }
        }

        return sObjectsToQueryMap;
    }

    // --------------------------------------------------------------------------------- //
    // ------------------------------------- OTHER ------------------------------------- //
    // --------------------------------------------------------------------------------- //

    public static String returnValueIfNotNull(String input) {
        return input != null ? input : '';
    }

    public static List<TimelineParent__mdt> checkObjectAccess(
        Boolean isCreateable,
        List<TimelineParent__mdt> sObjectsToQuery
    ) {
        List<TimelineParent__mdt> sObjectsToUse = new List<TimelineParent__mdt>();

        for (TimelineParent__mdt mdt : sObjectsToQuery) {
            if (isCreateable && Timeline_Validator.sObjectIsCreateable(mdt.Timeline_Child__r.SObjectName__c)) {
                sObjectsToUse.add(mdt);
            } else if (!isCreateable && Timeline_Validator.sObjectIsAccessible(mdt.Timeline_Child__r.SObjectName__c)) {
                sObjectsToUse.add(mdt);
            }
        }

        return sObjectsToUse;
    }

    public static String getMonth(Integer monthNo) {
        return IS_NORWEGIAN ? MONTH_NAME[monthNo] : MONTH_NAME_EN[monthNo];
    }

    public static List<TimelineParent__mdt> translateTimelineObjects(List<TimelineParent__mdt> data) {
        Map<String, Id> recordTypes = getRecordTypes(data);

        for (TimelineParent__mdt mdt : data) {
            mdt.Timeline_Child__r.CreateableObject_RecordType__c = recordTypes.get(
                mdt.Timeline_Child__r.SObjectName__c + mdt.Timeline_Child__r.CreateableObject_RecordType__c
            );
            if (IS_NORWEGIAN) {
                mdt.Timeline_Child__r.CreateableObject_TextEnglish__c = mdt.Timeline_Child__r.CreateableObject_TextNorwegian__c;
            }
        }

        return data;
    }

    // --------------------------------------------------------------------------------- //
    // -------------------------- SOBJECT TYPE AND RECORD TYPE ------------------------- //
    // --------------------------------------------------------------------------------- //

    public static String getSOjectTypeFromRecordId(String recordId) {
        Id i = (Id) recordId;

        return String.valueOf(i.getSobjectType());
    }

    public static Map<String, Id> getRecordTypes(List<TimelineParent__mdt> data) {
        Set<String> recordTypeNames = new Set<String>();

        for (TimelineParent__mdt mdt : data) {
            if (mdt.Timeline_Child__r.CreateableObject_RecordType__c != null) {
                recordTypeNames.add(mdt.Timeline_Child__r.CreateableObject_RecordType__c);
            }
        }

        List<RecordType> recordTypes = [
            SELECT Id, Name, SobjectType
            FROM RecordType
            WHERE DeveloperName IN :recordTypeNames
        ];
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : recordTypes) {
            recordTypeMap.put(rt.SobjectType + rt.Name, rt.Id);
        }

        return recordTypeMap;
    }
}
