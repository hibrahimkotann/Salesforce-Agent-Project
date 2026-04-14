public with sharing class PaymentService {

    /**
     * Booking kayıtları için ödeme ve rezervasyon durumlarını günceller.
     * @param bookings Güncellenecek Booking kayıtları (ilişkili ödemeleri çekilmiş olmalı).
     */
    public static void updateBookingStatuses(List<Booking__c> bookings) {

        List<Booking__c> bookingsToUpdate = new List<Booking__c>();

        for (Booking__c booking : bookings) {

            Decimal totalPaidAmount = 0;
            Decimal totalDepositPaid = 0;

            Decimal totalDueAmount = booking.Total_Amount__c != null ? booking.Total_Amount__c : 0;
            Decimal requiredDepositAmount = booking.Required_Deposit_Amount__c != null ? booking.Required_Deposit_Amount__c : 0;

            // İlgili tüm ödeme işlemlerini topla (Genel ve Depozito)
            for (Payment_Transaction__c payment : booking.Payment_Transactions__r) {
                if (payment.Amount__c != null) {
                    totalPaidAmount += payment.Amount__c;

                    // Depozito Tipini Kontrol Et (VARSAYIM: Transaction_Type__c = 'Security Deposit')
                    if (payment.Transaction_Type__c == 'Security Deposit') {
                        totalDepositPaid += payment.Amount__c;
                    }
                }
            }
            
            // --- 1. Payment Status (Ödeme Durumu) Belirleme Mantığı ---
            String newPaymentStatus = '';
            
            // Kural 1: Paid (Ödendi) => Hem Genel Toplam Eşleşmeli HEM de Depozito Tam Eşleşmeli.
            Boolean isFullyPaid = (totalPaidAmount >= totalDueAmount);
            Boolean isDepositExactlyMatched = (totalDepositPaid == requiredDepositAmount);
            
            if (isFullyPaid && isDepositExactlyMatched) {
                newPaymentStatus = 'Paid';
            } 
            // Kural 2: Partially Paid (Kısmen Ödendi) => Herhangi bir ödeme yapıldıysa VE 'Paid' değilse.
            else if (totalPaidAmount > 0) {
                newPaymentStatus = 'Partially Paid'; 
            }
            
            if (newPaymentStatus != '' && booking.Payment_Status__c != newPaymentStatus) {
                booking.Payment_Status__c = newPaymentStatus;
                bookingsToUpdate.add(booking);
            }

            // --- 2. Booking Status (Rezervasyon Durumu) Yönetimi ---
            // Kural: Otomatik Onaylama (Herhangi bir ödeme alındığında VE statü Pending ise Confirmed yap)
            if (totalPaidAmount > 0 && booking.Status__c == 'Pending') {
                booking.Status__c = 'Confirmed';
                // Eğer PaymentStatus da değiştiyse, zaten listeye eklendi.
                if (!bookingsToUpdate.contains(booking)) {
                    bookingsToUpdate.add(booking);
                }
            }
        }

        // DML İşlemi (Bulkified Update)
        if (!bookingsToUpdate.isEmpty()) {
            update bookingsToUpdate;
        }
    }
}