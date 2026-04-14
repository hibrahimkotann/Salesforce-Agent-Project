try {
    Decimal rate = ExchangeRateService.getUsdToEurRate();
    System.debug('>>> EUR Rate: ' + rate);
} catch (Exception e) {
    System.debug('>>> EXCEPTION: ' + e.getTypeName() + ' - ' + e.getMessage());
    System.debug('>>> STACKTRACE: ' + e.getStackTraceString());
}
