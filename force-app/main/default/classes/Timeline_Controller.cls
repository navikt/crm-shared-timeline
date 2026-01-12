public with sharing class Timeline_Controller {
    @AuraEnabled(cacheable=true)
    public static List<Timeline_ModelList> getTimelineData(
        String recordId,
        Integer amountOfMonths,
        Integer amountOfMonthsToLoad,
        String configId,
        Boolean includeSize,
        Integer amountOfRecords
    ) {
        if (recordId == null) {
            throw new AuraException('Error. Invalid record ID.');
        }

        String parentSObjectType = Timeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<TimelineParent__mdt> sObjectsToQuery = Timeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            configId
        );
        // Only query total records if we're not using a record limit (expensive operation)
        Integer totalRecords = (amountOfRecords == null || amountOfRecords <= 0) 
            ? Timeline_Queries.getTotalRecords(sObjectsToQuery, recordId) 
            : amountOfRecords;
        Integer effectiveLimit = amountOfRecords != null && amountOfRecords > 0 ? amountOfRecords : null;

        List<Timeline_Model> activity = Timeline_Helper.getActivity(sObjectsToQuery, recordId, amountOfMonths, effectiveLimit);
        activity = Timeline_Helper.reloadUntilDataFetched(
            sObjectsToQuery,
            recordId,
            amountOfMonths,
            amountOfMonthsToLoad,
            2,
            totalRecords,
            activity,
            includeSize,
            effectiveLimit
        );
        activity = Timeline_Helper.getOwnerAndContactNames(activity);
        activity.sort();

        List<Timeline_ModelList> activityDivided = Timeline_Helper.getRecordsDividedIntoMonths(activity, includeSize);
        Timeline_ModelList upcoming = Timeline_Helper.getUpcomingActivity(activity);
        Timeline_ModelList overdue = Timeline_Helper.getOverdueActivity(recordId, parentSObjectType, sObjectsToQuery);

        List<Timeline_ModelList> data = Timeline_Helper.addAllActivities(upcoming, overdue, activityDivided);

        return data;
    }

    @AuraEnabled(cacheable=true)
    public static List<TimelineParent__mdt> getTimelineObjects(String recordId, String configId) {
        if (recordId == null) {
            throw new AuraException('Error. Invalid record ID.');
        }

        String parentSObjectType = Timeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<TimelineParent__mdt> sObjectsToQuery = Timeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            true,
            configId
        );
        sObjectsToQuery = Timeline_Helper.translateTimelineObjects(sObjectsToQuery);

        return sObjectsToQuery;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getTotalRecords(String recordId, String configId) {
        if (recordId == null) {
            throw new AuraException('Error. Invalid record ID.');
        }

        String parentSObjectType = Timeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<TimelineParent__mdt> sObjectsToQuery = Timeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            configId
        );
        Integer totalRecords = Timeline_Queries.getTotalRecords(sObjectsToQuery, recordId);

        return totalRecords;
    }
}
