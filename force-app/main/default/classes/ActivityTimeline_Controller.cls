public with sharing class ActivityTimeline_Controller {
    // ------------------------------------------------------------- //
    // ---------------------- getTotalRecords ---------------------- //
    // ------------------------------------------------------------- //

    @AuraEnabled(cacheable=true)
    public static List<ActivityTimeline_ModelList> getActivityTimelineData(
        String recordId,
        Integer amountOfMonths,
        Integer amountOfMonthsToLoad,
        String configId
    ) {
        System.debug(
            '\n' +
            '------------------------------------------\n' +
            '----------getActivityTimelineData---------\n' +
            '------------------------------------------'
        );

        if (recordId == null) {
            throw new AuraException('Error. Invalid record ID.');
        }

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            configId
        );
        Integer totalRecords = ActivityTimeline_Queries.getTotalRecords(sObjectsToQuery, recordId);

        List<ActivityTimeline_Model> activity = ActivityTimeline_Helper.getActivity(
            sObjectsToQuery,
            recordId,
            amountOfMonths
        );
        activity = ActivityTimeline_Helper.reloadUntilDataFetched(
            sObjectsToQuery,
            recordId,
            amountOfMonths,
            amountOfMonthsToLoad,
            2,
            totalRecords,
            activity
        );
        activity = ActivityTimeline_Helper.getOwnerAndContactNames(activity);
        activity.sort();

        List<ActivityTimeline_ModelList> activityDivided = ActivityTimeline_Helper.getRecordsDividedIntoMonths(activity);
        ActivityTimeline_ModelList upcoming = ActivityTimeline_Helper.getUpcomingActivity(activity);
        ActivityTimeline_ModelList overdue = ActivityTimeline_Helper.getOverdueActivity(
            recordId,
            parentSObjectType,
            sObjectsToQuery
        );

        List<ActivityTimeline_ModelList> data = ActivityTimeline_Helper.addAllActivities(
            upcoming,
            overdue,
            activityDivided
        );

        return data;
    }

    // ------------------------------------------------------------- //
    // -------------------- getTimelineObjects --------------------- //
    // ------------------------------------------------------------- //

    @AuraEnabled(cacheable=true)
    public static List<ActivityTimelineParent__mdt> getTimelineObjects(String recordId, String configId) {
        System.debug(
            '\n' +
            '------------------------------------------\n' +
            '------------getTimelineObjects------------\n' +
            '------------------------------------------'
        );

        if (recordId == null) {
            throw new AuraException('Error. Invalid record ID.');
        }

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            true,
            configId
        );
        sObjectsToQuery = ActivityTimeline_Helper.translateTimelineObjects(sObjectsToQuery);

        return sObjectsToQuery;
    }

    // ------------------------------------------------------------- //
    // ---------------------- getTotalRecords ---------------------- //
    // ------------------------------------------------------------- //

    @AuraEnabled(cacheable=true)
    public static Integer getTotalRecords(String recordId, String configId) {
        System.debug(
            '\n' +
            '------------------------------------------\n' +
            '--------------getTotalRecords-------------\n' +
            '------------------------------------------'
        );

        if (recordId == null) {
            throw new AuraException('Error. Invalid record ID.');
        }

        String parentSObjectType = ActivityTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ActivityTimelineParent__mdt> sObjectsToQuery = ActivityTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            configId
        );
        Integer totalRecords = ActivityTimeline_Queries.getTotalRecords(sObjectsToQuery, recordId);

        return totalRecords;
    }
}
