@IsTest
public with sharing class Timeline_TestDataFactory {
    public static Account createAccount(String accountName) {
        Account accountRecord = new Account();
        accountRecord.put('Name', accountName);
        insert accountRecord;

        return accountRecord;
    }

    public static User createStandardUser(String lastName) {
        User user = new User();
        String d =
            String.valueOf(DateTime.now().millisecond()) +
            String.valueOf(DateTime.now().second()) +
            String.valueOf(DateTime.now().minute());
        user.Username = d + 'test@nav.no';
        user.Email = d + 'test@nav.no';
        user.Alias = 'tsamp';
        user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1].Id;
        user.isActive = true;
        user.FirstName = 'First';
        user.LastName = lastName;
        user.TimeZoneSidKey = 'Europe/Paris';
        user.LocaleSidKey = 'no_NO';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'no';
        user.CommunityNickname = 'testUser' + d;
        insert user;

        return user;
    }
}
