public with sharing class OpportunityTableController {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(Id accountId) {
        return [
            SELECT Id, Name, StageName, Amount, CloseDate, Probability
            FROM Opportunity
            WHERE AccountId = :accountId
            ORDER BY CloseDate DESC
        ];
    }

    @AuraEnabled
    public static void updateCloseDate(Id opportunityId) {
        Opportunity opp = [
            SELECT Id, CloseDate FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE LIMIT 1
        ];
        opp.CloseDate = Date.today();

        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, new List<Opportunity>{ opp });
        update decision.getRecords();
    }
}
