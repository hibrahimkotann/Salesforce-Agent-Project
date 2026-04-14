@isTest
private class OpportunityTableControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'LWC Test Account');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name      = 'Test Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30 + i),
                Amount    = 10000 * (i + 1)
            ));
        }
        insert opps;
    }

    @isTest
    static void testGetOpportunities() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Opportunity> results = OpportunityTableController.getOpportunities(acc.Id);
        Test.stopTest();

        System.assertEquals(5, results.size(), 'Should return 5 opportunities');
        System.assert(results[0].CloseDate >= results[1].CloseDate, 'Should be ordered by CloseDate DESC');
    }

    @isTest
    static void testGetOpportunitiesNoResults() {
        Account emptyAcc = new Account(Name = 'Empty Account');
        insert emptyAcc;

        Test.startTest();
        List<Opportunity> results = OpportunityTableController.getOpportunities(emptyAcc.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for account with no opps');
    }

    @isTest
    static void testUpdateCloseDate() {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity WHERE Name = 'Test Opp 0' LIMIT 1];
        System.assertNotEquals(Date.today(), opp.CloseDate, 'CloseDate should not be today before update');

        Test.startTest();
        OpportunityTableController.updateCloseDate(opp.Id);
        Test.stopTest();

        Opportunity updated = [SELECT CloseDate FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(Date.today(), updated.CloseDate, 'CloseDate should be updated to today');
    }

    @isTest
    static void testUpdateCloseDateBulk() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity];

        Test.startTest();
        for (Opportunity opp : opps) {
            OpportunityTableController.updateCloseDate(opp.Id);
        }
        Test.stopTest();

        List<Opportunity> updated = [SELECT CloseDate FROM Opportunity];
        for (Opportunity opp : updated) {
            System.assertEquals(Date.today(), opp.CloseDate, 'All CloseDates should be today');
        }
    }
}
