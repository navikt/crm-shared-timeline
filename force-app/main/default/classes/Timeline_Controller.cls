public with sharing class Timeline_Controller {
    // ------------------------------------------------------------- //
    // ---------------------- getTotalRecords ---------------------- //
    // ------------------------------------------------------------- //

    @AuraEnabled(cacheable=true)
    public static List<Timeline_ModelList> getTimelineData(
        String recordId,
        Integer amountOfMonths,
        Integer amountOfMonthsToLoad,
        String configId
    ) {
        System.debug(
            '\n' +
            '------------------------------------------\n' +
            '----------getTimelineData---------\n' +
            '------------------------------------------'
        );

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

        List<Timeline_Model> activity = Timeline_Helper.getActivity(sObjectsToQuery, recordId, amountOfMonths);
        activity = Timeline_Helper.reloadUntilDataFetched(
            sObjectsToQuery,
            recordId,
            amountOfMonths,
            amountOfMonthsToLoad,
            2,
            totalRecords,
            activity
        );
        activity = Timeline_Helper.getOwnerAndContactNames(activity);
        activity.sort();

        List<Timeline_ModelList> activityDivided = Timeline_Helper.getRecordsDividedIntoMonths(activity);
        Timeline_ModelList upcoming = Timeline_Helper.getUpcomingActivity(activity);
        Timeline_ModelList overdue = Timeline_Helper.getOverdueActivity(recordId, parentSObjectType, sObjectsToQuery);

        List<Timeline_ModelList> data = Timeline_Helper.addAllActivities(upcoming, overdue, activityDivided);

        return data;
    }

    // ------------------------------------------------------------- //
    // -------------------- getTimelineObjects --------------------- //
    // ------------------------------------------------------------- //

    @AuraEnabled(cacheable=true)
    public static List<TimelineParent__mdt> getTimelineObjects(String recordId, String configId) {
        System.debug(
            '\n' +
            '------------------------------------------\n' +
            '------------getTimelineObjects------------\n' +
            '------------------------------------------'
        );

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
