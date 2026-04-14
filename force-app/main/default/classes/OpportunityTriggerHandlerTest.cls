@isTest
private class OpportunityTriggerHandlerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Müşteri A.Ş.');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>();

        opps.add(new Opportunity(
            Name      = 'Filo Kiralama Anlaşması',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount    = 150000
        ));

        opps.add(new Opportunity(
            Name      = 'Tutarı Belirsiz Fırsat',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount    = null
        ));

        opps.add(new Opportunity(
            Name      = 'Account Olmayan Fırsat',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount    = 5000
        ));

        insert opps;
    }

    @isTest
    static void testClosedWonUpdatesAccountAndCreatesTask() {
        Opportunity opp = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Name = 'Filo Kiralama Anlaşması' LIMIT 1
        ];
        opp.StageName = 'Closed Won';

        Test.startTest();
        update opp;
        Test.stopTest();

        Account acc = [SELECT Description FROM Account WHERE Id = :opp.AccountId];
        System.assert(
            acc.Description.contains('Son Kazanılan Fırsat: Filo Kiralama Anlaşması'),
            'Account Description should contain opportunity name'
        );
        System.assert(
            acc.Description.contains('Miktar: 150000'),
            'Account Description should contain amount'
        );

        List<Task> tasks = [
            SELECT Subject, OwnerId, ActivityDate, WhatId
            FROM Task
            WHERE WhatId = :opp.AccountId AND Subject = 'Müşteriye Teşekkür Et'
        ];
        System.assertEquals(1, tasks.size(), 'Exactly one task should be created');
        System.assertEquals(Date.today().addDays(2), tasks[0].ActivityDate, 'Due date should be today + 2');
    }

    @isTest
    static void testNullAmountHandledGracefully() {
        Opportunity opp = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Name = 'Tutarı Belirsiz Fırsat' LIMIT 1
        ];
        opp.StageName = 'Closed Won';

        Test.startTest();
        update opp;
        Test.stopTest();

        Account acc = [SELECT Description FROM Account WHERE Id = :opp.AccountId];
        System.assert(
            acc.Description.contains('Belirtilmemiş'),
            'Null amount should show as Belirtilmemiş'
        );

        List<Task> tasks = [
            SELECT Id FROM Task
            WHERE WhatId = :opp.AccountId AND Subject = 'Müşteriye Teşekkür Et'
        ];
        System.assert(!tasks.isEmpty(), 'Task should still be created for null amount');
    }

    @isTest
    static void testNoAccountIdDoesNotFail() {
        Opportunity opp = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Name = 'Account Olmayan Fırsat' LIMIT 1
        ];
        opp.StageName = 'Closed Won';

        Test.startTest();
        update opp;
        Test.stopTest();

        List<Task> tasks = [
            SELECT Id FROM Task
            WHERE Subject = 'Müşteriye Teşekkür Et'
            AND CreatedDate = TODAY
        ];
        System.assertEquals(0, tasks.size(), 'No task should be created when AccountId is null');
    }

    @isTest
    static void testBulkClosedWon() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        List<Opportunity> bulkOpps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            bulkOpps.add(new Opportunity(
                Name      = 'Bulk Fırsat ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount    = 1000 + i
            ));
        }
        insert bulkOpps;

        for (Opportunity opp : bulkOpps) {
            opp.StageName = 'Closed Won';
        }

        Test.startTest();
        update bulkOpps;
        Test.stopTest();

        Account updatedAcc = [SELECT Description FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, updatedAcc.Description, 'Account description should be updated after bulk operation');

        List<Task> tasks = [
            SELECT Id FROM Task
            WHERE WhatId = :acc.Id AND Subject = 'Müşteriye Teşekkür Et'
        ];
        System.assertEquals(200, tasks.size(), 'One task per closed-won opportunity (200 total)');
    }

    @isTest
    static void testStageChangeToOtherDoesNotTrigger() {
        Opportunity opp = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Name = 'Filo Kiralama Anlaşması' LIMIT 1
        ];
        opp.StageName = 'Qualification';

        Test.startTest();
        update opp;
        Test.stopTest();

        Account acc = [SELECT Description FROM Account WHERE Id = :opp.AccountId];
        System.assertEquals(null, acc.Description, 'Description should remain null when stage is not Closed Won');

        List<Task> tasks = [
            SELECT Id FROM Task
            WHERE WhatId = :opp.AccountId AND Subject = 'Müşteriye Teşekkür Et'
        ];
        System.assertEquals(0, tasks.size(), 'No task should be created for non-Closed Won stage');
    }
}
