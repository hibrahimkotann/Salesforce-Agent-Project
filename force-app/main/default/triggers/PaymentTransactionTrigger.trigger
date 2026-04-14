trigger PaymentTransactionTrigger on Payment_Transaction__c (after insert, after update, after delete, after undelete) {

    if (Trigger.isAfter) {
        
        PaymentTransactionHandler.handlePaymentStatusUpdate(
            Trigger.new, 
            Trigger.old, 
            Trigger.isInsert || Trigger.isUndelete, 
            Trigger.isDelete
        );
    }
}