public with sharing class ExchangeRateQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> opportunityIds;

    public ExchangeRateQueueable(Set<Id> oppIds) {
        this.opportunityIds = oppIds;
    }

    public void execute(QueueableContext ctx) {
        Decimal eurRate = ExchangeRateService.getUsdToEurRate();
        if (eurRate == null) {
            System.debug(LoggingLevel.WARN,
                'ExchangeRateQueueable: EUR rate unavailable, skipping update.');
            return;
        }

        List<Opportunity> opps = [
            SELECT Id, Amount
            FROM Opportunity
            WHERE Id IN :opportunityIds AND Amount != null
            WITH USER_MODE
        ];

        if (opps.isEmpty()) {
            return;
        }

        List<Opportunity> toUpdate = new List<Opportunity>();
        for (Opportunity opp : opps) {
            toUpdate.add(new Opportunity(
                Id = opp.Id,
                Amount_in_EUR__c = opp.Amount * eurRate
            ));
        }

        OpportunityTriggerHandler.skipEurConversion = true;
        List<Database.SaveResult> results = Database.update(toUpdate, false);
        OpportunityTriggerHandler.skipEurConversion = false;

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'ExchangeRateQueueable update failed for ' + toUpdate[i].Id
                        + ': ' + err.getMessage());
                }
            }
        }
    }
}
