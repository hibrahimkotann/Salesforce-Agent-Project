@IsTest
private class ExchangeRateServiceTest {

    private static final String MOCK_SUCCESS_BODY =
        '{"amount":1.0,"base":"USD","date":"2026-04-14","rates":{"EUR":0.9150,"GBP":0.7891,"TRY":38.45}}';

    private class MockHttpSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(MOCK_SUCCESS_BODY);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    private class MockHttpError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    private class MockHttpBadJson implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"amount":1.0,"base":"USD","rates":{}}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    @IsTest
    static void testGetUsdToEurRate_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();
        Decimal rate = ExchangeRateService.getUsdToEurRate();
        Test.stopTest();

        System.assertNotEquals(null, rate, 'Rate should not be null');
        System.assertEquals(0.9150, rate, 'EUR rate should match mock data');
    }

    @IsTest
    static void testGetUsdToEurRate_ApiError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpError());

        Test.startTest();
        Decimal rate = ExchangeRateService.getUsdToEurRate();
        Test.stopTest();

        System.assertEquals(null, rate, 'Rate should be null on non-200 response');
    }

    @IsTest
    static void testGetUsdToEurRate_MissingEurInResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpBadJson());

        Test.startTest();
        Decimal rate = ExchangeRateService.getUsdToEurRate();
        Test.stopTest();

        System.assertEquals(null, rate, 'Rate should be null when EUR key missing');
    }

    @IsTest
    static void testQueueable_Success() {
        Account acc = new Account(Name = 'EUR Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'EUR Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000,
            AccountId = acc.Id
        );
        insert opp;

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();
        System.enqueueJob(new ExchangeRateQueueable(new Set<Id>{ opp.Id }));
        Test.stopTest();

        Opportunity updated = [
            SELECT Amount_in_EUR__c FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertNotEquals(null, updated.Amount_in_EUR__c,
            'Amount_in_EUR__c should be populated');
        System.assertEquals(10000 * 0.9150, updated.Amount_in_EUR__c,
            'EUR amount should equal Amount * EUR rate');
    }

    @IsTest
    static void testQueueable_ApiError_NoUpdate() {
        Account acc = new Account(Name = 'EUR Error Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'EUR Error Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000,
            AccountId = acc.Id
        );
        insert opp;

        Test.setMock(HttpCalloutMock.class, new MockHttpError());

        Test.startTest();
        System.enqueueJob(new ExchangeRateQueueable(new Set<Id>{ opp.Id }));
        Test.stopTest();

        Opportunity updated = [
            SELECT Amount_in_EUR__c FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertEquals(null, updated.Amount_in_EUR__c,
            'Amount_in_EUR__c should remain null on API failure');
    }

    @IsTest
    static void testQueueable_BulkProcessing() {
        Account acc = new Account(Name = 'EUR Bulk Account');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 50; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 1000 * (i + 1),
                AccountId = acc.Id
            ));
        }
        insert opps;

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity o : opps) {
            oppIds.add(o.Id);
        }

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();
        System.enqueueJob(new ExchangeRateQueueable(oppIds));
        Test.stopTest();

        List<Opportunity> updated = [
            SELECT Amount, Amount_in_EUR__c FROM Opportunity
            WHERE Id IN :oppIds
            ORDER BY Amount
        ];
        for (Opportunity o : updated) {
            System.assertNotEquals(null, o.Amount_in_EUR__c,
                'All opportunities should have EUR amount');
            System.assertEquals(o.Amount * 0.9150, o.Amount_in_EUR__c,
                'EUR amount must equal Amount * rate for ' + o.Amount);
        }
    }

    @IsTest
    static void testQueueable_NullAmount_Skipped() {
        Account acc = new Account(Name = 'EUR Null Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Null Amount Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();
        System.enqueueJob(new ExchangeRateQueueable(new Set<Id>{ opp.Id }));
        Test.stopTest();

        Opportunity updated = [
            SELECT Amount_in_EUR__c FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertEquals(null, updated.Amount_in_EUR__c,
            'Null-amount opp should not get EUR conversion');
    }
}
