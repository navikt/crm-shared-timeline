public with sharing class ActivityTimeline_Helper {
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

    public static List<ActivityTimeline_Model> getActivity(
        List<ActivityTimelineParent__mdt> sObjectsToQuery,
        String recordId,
        Integer amountOfMonths
    ) {
        List<String> query = ActivityTimeline_Queries.createSoqlQueries(sObjectsToQuery, recordId, amountOfMonths);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);
        List<ActivityTimeline_Model> data = createActivityTimelineData(sObjectsToQuery, sObjects);

        return data;
    }

    public static ActivityTimeline_ModelList getUpcomingActivity(List<ActivityTimeline_Model> models) {
        List<ActivityTimeline_Model> data = new List<ActivityTimeline_Model>();
        for (ActivityTimeline_Model model : models) {
            Datetime d = model.config.Activity_Timeline_Child__r.SObjectDateFieldIsDate__c
                ? System.today()
                : System.now();
            if (model.record.dateValueDb >= d) {
                data.add(model);
            }
        }

        return new ActivityTimeline_ModelList(
            Label.ActivityTimeline_Upcoming,
            Label.ActivityTimeline_Upcoming,
            data,
            false
        );
    }

    public static ActivityTimeline_ModelList getOverdueActivity(
        String recordId,
        String parentSObjectType,
        List<ActivityTimelineParent__mdt> sObjectsToQuery
    ) {
        Map<String, ActivityTimelineParent__mdt> sObjectsToQueryMap = getMapOfActivityTimelineConfig(sObjectsToQuery);
        if (!sObjectsToQueryMap.containsKey('Task')) {
            return null;
        } // return if tasks not configured
        sObjectsToQuery = new List<ActivityTimelineParent__mdt>{ sObjectsToQueryMap.get('Task') }; // get only tasks

        List<String> query = ActivityTimeline_Queries.getOverdueQuery(sObjectsToQuery, recordId);
        List<SObject> sObjects = ActivityTimeline_Queries.getSObjectsFromQueries(query);
        List<ActivityTimeline_Model> data = createActivityTimelineData(sObjectsToQuery, sObjects);
        data = getOwnerAndContactNames(data);
        data.sort();

        return new ActivityTimeline_ModelList(
            Label.ActivityTimeline_Overdue,
            Label.ActivityTimeline_Overdue,
            data,
            true
        );
    }

    // --------------------------------------------------------------------------------- //
    // ------------------------------- DATA MANAPULATION ------------------------------- //
    // --------------------------------------------------------------------------------- //

    public static List<ActivityTimeline_Model> createActivityTimelineData(
        List<ActivityTimelineParent__mdt> sObjectsToQuery,
        List<SObject> sObjects
    ) {
        List<ActivityTimeline_Model> data = new List<ActivityTimeline_Model>();
        Map<String, ActivityTimelineParent__mdt> sObjectsToQueryMap = getMapOfActivityTimelineConfig(sObjectsToQuery);

        for (SObject sObj : sObjects) {
            String childSObjectKind = getSOjectTypeFromRecordId((Id) sObj.get('Id'));
            String childSObjectType = '';
            for (ActivityTimelineParent__mdt mdt : sObjectsToQueryMap.values()) {
                if (mdt.Activity_Timeline_Child__r.SObjectName__c == childSObjectKind) {
                    if (mdt.Activity_Timeline_Child__r.SObjectTypeField__c != null) {
                        String type = (String) sObj.get(mdt.Activity_Timeline_Child__r.SObjectTypeField__c);
                        if (type != null) {
                            childSObjectType = type;
                            break;
                        }
                    }
                }
            }

            ActivityTimelineParent__mdt mdt = sObjectsToQueryMap.get(childSObjectKind + childSObjectType);
            if (mdt == null) {
                mdt = sObjectsToQueryMap.get(childSObjectKind);
            }
            if (mdt != null) {
                data.add(new ActivityTimeline_Model(mdt, sObj));
            }
        }

        return data;
    }

    public static List<ActivityTimeline_Model> reloadUntilDataFetched(
        List<ActivityTimelineParent__mdt> sObjectsToQuery,
        String recordId,
        Integer amountOfMonths,
        Integer amountOfMonthsToLoad,
        Integer iteration,
        Integer totalRecords,
        List<ActivityTimeline_Model> activity
    ) {
        activity.sort();

        List<ActivityTimeline_ModelList> activityDivided = ActivityTimeline_Helper.getRecordsDividedIntoMonths(activity);
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

            List<ActivityTimeline_Model> newActivities = ActivityTimeline_Helper.getActivity(
                sObjectsToQuery,
                recordId,
                newAmount
            );

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

    public static Integer countRecords(List<ActivityTimeline_ModelList> activityDivided) {
        Integer totalRecords = 0;

        for (ActivityTimeline_ModelList activity : activityDivided) {
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

    public static List<ActivityTimeline_ModelList> getRecordsDividedIntoMonths(List<ActivityTimeline_Model> data) {
        Map<String, List<ActivityTimeline_Model>> modelsSeparatedByMonth = new Map<String, List<ActivityTimeline_Model>>();

        for (ActivityTimeline_Model model : data) {
            Datetime d = model.config.Activity_Timeline_Child__r.SObjectDateFieldIsDate__c
                ? System.today()
                : System.now();

            if (model.record.dateValueDb < d) {
                String key = model.record.dateValueDb.month() + '-' + model.record.dateValueDb.year();
                if (modelsSeparatedByMonth.containsKey(key)) {
                    modelsSeparatedByMonth.get(key).add(model);
                } else {
                    modelsSeparatedByMonth.put(key, new List<ActivityTimeline_Model>{ model });
                }
            }
        }

        List<ActivityTimeline_ModelList> results = new List<ActivityTimeline_ModelList>();

        for (String key : modelsSeparatedByMonth.keySet()) {
            Datetime d = modelsSeparatedByMonth.get(key)[0].record.dateValueDb;
            String name = getMonth(d.month()) + ' ' + d.year();
            results.add(new ActivityTimeline_ModelList(key, name, modelsSeparatedByMonth.get(key), true));
        }

        return results;
    }

    public static List<ActivityTimeline_ModelList> addAllActivities(
        ActivityTimeline_ModelList upcoming,
        ActivityTimeline_ModelList overdue,
        List<ActivityTimeline_ModelList> activityDivided
    ) {
        List<ActivityTimeline_ModelList> data = new List<ActivityTimeline_ModelList>();

        if (overdue.models != null) {
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

    public static List<ActivityTimeline_Model> getOwnerAndContactNames(List<ActivityTimeline_Model> models) {
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for (ActivityTimeline_Model model : models) {
            if (model.record.assigneeId != null) {
                ownerIds.add(model.record.assigneeId);
            }
            if (model.record.relatedUserId != null) {
                contactIds.add(model.record.relatedUserId);
            }
        }

        Map<Id, String> ownerNames = getOwnerName(ownerIds);
        Map<Id, String> contactNames = getContactName(contactIds);

        for (ActivityTimeline_Model model : models) {
            if (model.record.dateValueDb < DateTime.now() && !model.record.overdue) {
                model.record.subtitle = IS_NORWEGIAN
                    ? model.config.Activity_Timeline_Child__r.SubtitlePastNorwegian__c
                    : model.config.Activity_Timeline_Child__r.SubtitlePastEnglish__c;
            } else {
                model.record.subtitle = IS_NORWEGIAN
                    ? model.config.Activity_Timeline_Child__r.SubtitleFutureNorwegian__c
                    : model.config.Activity_Timeline_Child__r.SubtitleFutureEnglish__c;
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
                              returnValueIfNotNull(
                                  model.config.Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionNor__c
                              )
                            : ' ' +
                              returnValueIfNotNull(
                                  model.config.Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c
                              );
                    }
                }
            } else if (model.record.sObjectKind == 'Task' && model.record.type == 'Call') {
                model.record.relatedUser = Label.ActivityTimeline_Unknown.toLowerCase();
            }
        }

        return models;
    }

    public static Map<Id, String> getOwnerName(Set<Id> ownerIds) {
        Map<Id, String> results = new Map<Id, String>();
        Map<Id, User> users = new Map<Id, User>([SELECT Name FROM User WHERE Id IN :ownerIds]);

        for (Id ownerId : ownerIds) {
            if (ownerId == UserInfo.getUserId()) {
                results.put(ownerId, Label.ActivityTimeline_You);
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

    public static List<ActivityTimeline_ModelList> removeConfig(List<ActivityTimeline_ModelList> data) {
        for (ActivityTimeline_ModelList d : data) {
            for (ActivityTimeline_Model model : d.models) {
                model.config = null;
            }
        }

        return data;
    }

    public static Map<String, ActivityTimelineParent__mdt> getMapOfActivityTimelineConfig(
        List<ActivityTimelineParent__mdt> sObjectsToQuery
    ) {
        Map<String, ActivityTimelineParent__mdt> sObjectsToQueryMap = new Map<String, ActivityTimelineParent__mdt>();

        for (ActivityTimelineParent__mdt mdt : sObjectsToQuery) {
            String mdtType = mdt.Activity_Timeline_Child__r.SObjectTypeValue__c != null &&
                mdt.Activity_Timeline_Child__r.SObjectTypeValue__c != 'null'
                ? mdt.Activity_Timeline_Child__r.SObjectTypeValue__c
                : '';
            if (mdtType.contains(';')) {
                List<String> typeList = mdtType.split(';');
                for (String type : typeList) {
                    sObjectsToQueryMap.put(mdt.Activity_Timeline_Child__r.SObjectName__c + type, mdt);
                }
            } else {
                sObjectsToQueryMap.put(mdt.Activity_Timeline_Child__r.SObjectName__c + mdtType, mdt);
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

    public static List<ActivityTimelineParent__mdt> checkObjectAccess(
        Boolean isCreateable,
        List<ActivityTimelineParent__mdt> sObjectsToQuery
    ) {
        List<ActivityTimelineParent__mdt> sObjectsToUse = new List<ActivityTimelineParent__mdt>();

        for (ActivityTimelineParent__mdt mdt : sObjectsToQuery) {
            if (
                isCreateable &&
                ActivityTimeline_Validator.sObjectIsCreateable(mdt.Activity_Timeline_Child__r.SObjectName__c)
            ) {
                sObjectsToUse.add(mdt);
            } else if (
                !isCreateable &&
                ActivityTimeline_Validator.sObjectIsAccessible(mdt.Activity_Timeline_Child__r.SObjectName__c)
            ) {
                sObjectsToUse.add(mdt);
            }
        }

        return sObjectsToUse;
    }

    public static String getMonth(Integer monthNo) {
        return IS_NORWEGIAN ? MONTH_NAME[monthNo] : MONTH_NAME_EN[monthNo];
    }

    public static List<ActivityTimelineParent__mdt> translateTimelineObjects(List<ActivityTimelineParent__mdt> data) {
        Map<String, Id> recordTypes = getRecordTypes(data);

        for (ActivityTimelineParent__mdt mdt : data) {
            mdt.Activity_Timeline_Child__r.CreateableObject_RecordType__c = recordTypes.get(
                mdt.Activity_Timeline_Child__r.SObjectName__c +
                mdt.Activity_Timeline_Child__r.CreateableObject_RecordType__c
            );
            if (IS_NORWEGIAN) {
                mdt.Activity_Timeline_Child__r.CreateableObject_TextEnglish__c = mdt.Activity_Timeline_Child__r.CreateableObject_TextNorwegian__c;
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

    public static Map<String, Id> getRecordTypes(List<ActivityTimelineParent__mdt> data) {
        Set<String> recordTypeNames = new Set<String>();

        for (ActivityTimelineParent__mdt mdt : data) {
            if (mdt.Activity_Timeline_Child__r.CreateableObject_RecordType__c != null) {
                recordTypeNames.add(mdt.Activity_Timeline_Child__r.CreateableObject_RecordType__c);
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
