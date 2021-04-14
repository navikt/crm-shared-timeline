@isTest
private without sharing class ActivityTimeline_ValidatorTest {
    // #################################################
    // ############## SObjectIsAccessible ##############
    // #################################################

    @isTest
    private static void testSObjectIsAccessible_emptyUser() {
        User u = ActivityTimeline_TestDataFactory.createStandardUser('ARBEIDSGIVER USER');
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = ActivityTimeline_Validator.sObjectIsAccessible('NavTask__c');
        }
        Test.StopTest();

        System.assert(!result, 'Empty user user should NOT have access');
    }

    @isTest
    private static void testSObjectIsAccessible_emptyUserWithPermset() {
        Test.StartTest();
        Boolean result = ActivityTimeline_Validator.sObjectIsAccessible('NavTask__c');
        Test.StopTest();

        System.assert(result, 'Current user should have access (is admin)');
    }

    // #################################################
    // ############## SObjectIsCreateable ##############
    // #################################################

    @isTest
    private static void testSObjectIsCreateable_emptyUser() {
        User u = ActivityTimeline_TestDataFactory.createStandardUser('ARBEIDSGIVER USER');
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = ActivityTimeline_Validator.sObjectIsCreateable('NavTask__c');
        }
        Test.StopTest();

        System.assert(!result, 'Empty user user should NOT have access');
    }

    @isTest
    private static void testSObjectIsCreateable_emptyUserWithPermset() {
        Test.StartTest();
        Boolean result = ActivityTimeline_Validator.sObjectIsCreateable('NavTask__c');
        Test.StopTest();

        System.assert(result, 'Current user should have access (is admin)');
    }

    // #################################################
    // ############### FieldIsAccessible ###############
    // #################################################

    @isTest
    private static void testFieldIsAccessible_emptyUser() {
        User u = ActivityTimeline_TestDataFactory.createStandardUser('ARBEIDSGIVER USER');
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = ActivityTimeline_Validator.fieldIsAccessible('NavTask__c', 'CRM_Account__c');
        }
        Test.StopTest();

        System.assert(!result, 'Empty user user should NOT have access');
    }

    // #################################################
    // ############### FieldIsCreateable ###############
    // #################################################

    @isTest
    private static void testFieldIsCreateable_emptyUser() {
        User u = ActivityTimeline_TestDataFactory.createStandardUser('ARBEIDSGIVER USER');
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = ActivityTimeline_Validator.fieldIsCreateable('NavTask__c', 'CRM_Account__c');
        }
        Test.StopTest();

        System.assert(!result, 'Empty user user should NOT have access');
    }
}
