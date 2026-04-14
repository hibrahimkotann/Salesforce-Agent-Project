@isTest
private class AccountTriggerHandlerTest {

    @TestSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
    }

    @isTest
    static void testDescriptionUpdatedOnSingleRecord() {
        Account acc = [SELECT Id, Name, Description FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        acc.Name = 'Updated Account';

        Test.startTest();
        update acc;
        Test.stopTest();

        Account result = [SELECT Description FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, result.Description, 'Description should not be null after update');
        System.assert(result.Description.contains('Son güncelleme:'), 'Description should contain update prefix');
        System.assert(result.Description.contains(UserInfo.getName()), 'Description should contain current user name');
    }

    @isTest
    static void testDescriptionUpdatedOnBulkRecords() {
        List<Account> accounts = [SELECT Id, Name FROM Account];
        for (Account acc : accounts) {
            acc.Name = acc.Name + ' - Bulk Updated';
        }

        Test.startTest();
        update accounts;
        Test.stopTest();

        List<Account> results = [SELECT Id, Description FROM Account];
        for (Account acc : results) {
            System.assertNotEquals(null, acc.Description, 'Description should not be null for bulk updated records');
            System.assert(acc.Description.contains('Son güncelleme:'), 'Each record should have the update stamp');
        }
    }

    @isTest
    static void testDescriptionFormatContainsDateAndUser() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        acc.Phone = '555-0000';

        Test.startTest();
        update acc;
        Test.stopTest();

        Account result = [SELECT Description FROM Account WHERE Id = :acc.Id];
        String expectedUserName = UserInfo.getName();
        String todayStr = Datetime.now().format('dd/MM/yyyy');

        System.assert(result.Description.contains(todayStr), 'Description should contain today\'s date');
        System.assert(result.Description.contains(expectedUserName), 'Description should contain user name');
    }
}
