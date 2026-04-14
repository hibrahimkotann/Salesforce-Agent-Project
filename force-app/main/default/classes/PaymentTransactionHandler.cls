public with sharing class PaymentTransactionHandler {

    // Trigger'dan gelen veriyi alır ve Service Class'a hazırlar
    public static void handlePaymentStatusUpdate(List<Payment_Transaction__c> newPayments, List<Payment_Transaction__c> oldPayments, Boolean isInsertOrUndelete, Boolean isDelete) {
        
        Set<Id> bookingIds = new Set<Id>();

        // 1. Etkilenen tüm Booking ID'lerini topla
        List<Payment_Transaction__c> paymentsToProcess = isDelete ? oldPayments : newPayments;

        for (Payment_Transaction__c payment : paymentsToProcess) {
             
            // Yalnızca Amount__c veya Booking__c değiştiyse işlem yap (After Update optimizasyonu)
            if (isInsertOrUndelete || isDelete || hasRelevantFieldsChanged(payment, oldPayments.get(payment.Id))) {
                if (payment.Booking__c != null) {
                    bookingIds.add(payment.Booking__c);
                }
            }
        }

        if (bookingIds.isEmpty()) return;

        // 2. İlgili Booking kayıtlarını ve tüm ödemelerini SOQL ile çek
        List<Booking__c> bookings = getRelatedBookings(bookingIds);

        // 3. İşi Service Class'a devret
        PaymentService.updateBookingStatuses(bookings);
    }
    
    // Yardımcı Metot: Sadece Booking ID ve Amount değiştiyse True döndürür
    private static Boolean hasRelevantFieldsChanged(Payment_Transaction__c newPayment, Payment_Transaction__c oldPayment) {
        return (newPayment.Booking__c != oldPayment.Booking__c || 
                newPayment.Amount__c != oldPayment.Amount__c);
    }

    // Yardımcı Metot: Booking ve ilişkili ödemeleri çeker
    private static List<Booking__c> getRelatedBookings(Set<Id> bookingIds) {
        return [
            SELECT Id, Status__c, Total_Amount__c, Payment_Status__c, Required_Deposit_Amount__c, // Yeni eklenen alan
                (SELECT Id, Amount__c, Transaction_Type__c FROM Payment_Transactions__r) // Ödemeleri ve Tip alanını çek
            FROM Booking__c
            WHERE Id IN :bookingIds
        ];
    }
}