public with sharing class OpportunityTriggerHandler {

    private static final String CLOSED_WON = 'Closed Won';
    public static Boolean skipEurConversion = false;

    public static void onAfterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        handleClosedWonLogic(newOpps, oldMap);
        handleEurConversion(newOpps, oldMap);
    }

    private static void handleClosedWonLogic(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        List<Opportunity> closedWonOpps = filterClosedWonOpps(newOpps, oldMap);
        if (closedWonOpps.isEmpty()) {
            return;
        }

        Set<Id> accountIds = collectAccountIds(closedWonOpps);
        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds
        ]);

        List<Account> accountsToUpdate = buildAccountUpdates(closedWonOpps, accountMap);
        List<Task> tasksToInsert = buildTasks(closedWonOpps, accountMap);

        if (!accountsToUpdate.isEmpty()) {
            AccountTriggerHandler.skipExecution = true;
            update accountsToUpdate;
            AccountTriggerHandler.skipExecution = false;
        }
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    private static void handleEurConversion(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        if (skipEurConversion) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.Amount != oldOpp.Amount && opp.Amount != null) {
                oppIds.add(opp.Id);
            }
        }

        if (!oppIds.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new ExchangeRateQueueable(oppIds));
        }
    }

    private static List<Opportunity> filterClosedWonOpps(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        List<Opportunity> result = new List<Opportunity>();
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.StageName == CLOSED_WON && oldOpp.StageName != CLOSED_WON) {
                result.add(opp);
            }
        }
        return result;
    }

    private static Set<Id> collectAccountIds(List<Opportunity> opps) {
        Set<Id> ids = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.AccountId != null) {
                ids.add(opp.AccountId);
            }
        }
        return ids;
    }

    private static List<Account> buildAccountUpdates(List<Opportunity> opps, Map<Id, Account> accountMap) {
        Map<Id, Account> updatedAccounts = new Map<Id, Account>();
        for (Opportunity opp : opps) {
            if (opp.AccountId == null || !accountMap.containsKey(opp.AccountId)) {
                continue;
            }
            String amountStr = opp.Amount != null
                ? String.valueOf(opp.Amount)
                : 'Belirtilmemiş';

            Account acc = updatedAccounts.containsKey(opp.AccountId)
                ? updatedAccounts.get(opp.AccountId)
                : new Account(Id = opp.AccountId);

            acc.Description = 'Son Kazanılan Fırsat: ' + opp.Name + ' - Miktar: ' + amountStr;
            updatedAccounts.put(opp.AccountId, acc);
        }
        return updatedAccounts.values();
    }

    private static List<Task> buildTasks(List<Opportunity> opps, Map<Id, Account> accountMap) {
        List<Task> tasks = new List<Task>();
        for (Opportunity opp : opps) {
            if (opp.AccountId == null || !accountMap.containsKey(opp.AccountId)) {
                continue;
            }
            Account acc = accountMap.get(opp.AccountId);
            tasks.add(new Task(
                Subject     = 'Müşteriye Teşekkür Et',
                WhatId      = opp.AccountId,
                OwnerId     = acc.OwnerId,
                ActivityDate = Date.today().addDays(2),
                Status      = 'Not Started',
                Priority    = 'Normal',
                Description = opp.Name + ' fırsatı kazanıldı. Müşteriyle iletişime geç.'
            ));
        }
        return tasks;
    }
}
