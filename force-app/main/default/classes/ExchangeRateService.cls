public with sharing class ExchangeRateService {

    private static final String NAMED_CREDENTIAL = 'callout:Frankfurter_API';
    private static final String ENDPOINT_PATH = '/latest?from=USD';
    private static final String TARGET_CURRENCY = 'EUR';
    private static final Integer TIMEOUT_MS = 10000;

    public static Decimal getUsdToEurRate() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + ENDPOINT_PATH);
        req.setMethod('GET');
        req.setTimeout(TIMEOUT_MS);

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ExchangeRateService callout exception: ' + e.getMessage());
            return null;
        }

        if (res.getStatusCode() != 200) {
            System.debug(LoggingLevel.ERROR,
                'ExchangeRateService API error — Status: ' + res.getStatusCode()
                + ' Body: ' + res.getBody());
            return null;
        }

        return parseEurRate(res.getBody());
    }

    private static Decimal parseEurRate(String jsonBody) {
        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        Map<String, Object> rates =
            (Map<String, Object>) payload.get('rates');

        if (rates == null || !rates.containsKey(TARGET_CURRENCY)) {
            System.debug(LoggingLevel.ERROR,
                'ExchangeRateService: EUR rate not found in response');
            return null;
        }

        return (Decimal) rates.get(TARGET_CURRENCY);
    }
}
