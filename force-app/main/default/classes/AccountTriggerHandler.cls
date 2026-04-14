public with sharing class AccountTriggerHandler {

    public static Boolean skipExecution = false;

    public static void onBeforeUpdate(List<Account> newAccounts) {
        if (skipExecution) {
            return;
        }
        String currentUserName = UserInfo.getName();
        String formattedDate = Datetime.now().format('dd/MM/yyyy HH:mm');

        for (Account acc : newAccounts) {
            acc.Description = 'Son güncelleme: ' + formattedDate + ' - ' + currentUserName;
        }
    }
}
