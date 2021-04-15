public with sharing class ObjectTimeline_Controller {
    // ------------------------------------------------------------- //
    // ---------------------- getTotalRecords ---------------------- //
    // ------------------------------------------------------------- //

    @AuraEnabled(cacheable=true)
    public static List<ObjectTimeline_ModelList> getObjectTimelineData(
        String recordId,
        Integer amountOfMonths,
        Integer amountOfMonthsToLoad,
        String configId
    ) {
        System.debug(
            '\n' +
            '------------------------------------------\n' +
            '----------getObjectTimelineData---------\n' +
            '------------------------------------------'
        );

        if (recordId == null) {
            throw new AuraException('Error. Invalid record ID.');
        }

        String parentSObjectType = ObjectTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ObjectTimelineParent__mdt> sObjectsToQuery = ObjectTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            configId
        );
        Integer totalRecords = ObjectTimeline_Queries.getTotalRecords(sObjectsToQuery, recordId);

        List<ObjectTimeline_Model> activity = ObjectTimeline_Helper.getActivity(
            sObjectsToQuery,
            recordId,
            amountOfMonths
        );
        activity = ObjectTimeline_Helper.reloadUntilDataFetched(
            sObjectsToQuery,
            recordId,
            amountOfMonths,
            amountOfMonthsToLoad,
            2,
            totalRecords,
            activity
        );
        activity = ObjectTimeline_Helper.getOwnerAndContactNames(activity);
        activity.sort();

        List<ObjectTimeline_ModelList> activityDivided = ObjectTimeline_Helper.getRecordsDividedIntoMonths(activity);
        ObjectTimeline_ModelList upcoming = ObjectTimeline_Helper.getUpcomingActivity(activity);
        ObjectTimeline_ModelList overdue = ObjectTimeline_Helper.getOverdueActivity(
            recordId,
            parentSObjectType,
            sObjectsToQuery
        );

        List<ObjectTimeline_ModelList> data = ObjectTimeline_Helper.addAllActivities(
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
    public static List<ObjectTimelineParent__mdt> getTimelineObjects(String recordId, String configId) {
        System.debug(
            '\n' +
            '------------------------------------------\n' +
            '------------getTimelineObjects------------\n' +
            '------------------------------------------'
        );

        if (recordId == null) {
            throw new AuraException('Error. Invalid record ID.');
        }

        String parentSObjectType = ObjectTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ObjectTimelineParent__mdt> sObjectsToQuery = ObjectTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            true,
            configId
        );
        sObjectsToQuery = ObjectTimeline_Helper.translateTimelineObjects(sObjectsToQuery);

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

        String parentSObjectType = ObjectTimeline_Helper.getSOjectTypeFromRecordId(recordId);
        List<ObjectTimelineParent__mdt> sObjectsToQuery = ObjectTimeline_Queries.getSObjectsToQuery(
            parentSObjectType,
            false,
            configId
        );
        Integer totalRecords = ObjectTimeline_Queries.getTotalRecords(sObjectsToQuery, recordId);

        return totalRecords;
    }
}
