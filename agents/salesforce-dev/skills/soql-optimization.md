# Skill: SOQL Optimization

## Ne Zaman Kullanılır

SOQL sorgusu yazma, mevcut sorguyu optimize etme veya sorgu limitlerine yaklaşma durumunda bu skill'i uygula.

## Temel Kurallar

1. **Sadece gerekli alanları seç** — `SELECT *` yok, `SELECT Id, Name, Status__c` kullan.
2. **WHERE'de indeksli alan kullan** — `Id`, `Name`, `CreatedDate`, `SystemModstamp`, `RecordType`, `lookup/master-detail`, `External Id`, `Unique` alanlar indekslidir.
3. **Selective query yaz** — WHERE filtresi kayıtların %10'undan azını (veya 333K satırdan azını) döndürmeli.
4. **Relationship query kullan** — Ayrı sorgu yerine parent-child veya child-parent ilişkisini tek sorguda çöz.
5. **Aggregate fonksiyonları değerlendir** — `COUNT()`, `SUM()`, `AVG()`, `MAX()`, `MIN()`, `GROUP BY`.

## Pattern'ler

### Child-to-Parent (Dot Notation)

```sql
SELECT Id, Name, Account.Name, Account.Industry
FROM Contact
WHERE Account.Industry = 'Technology'
```

### Parent-to-Child (Subquery)

```sql
SELECT Id, Name, (SELECT Id, LastName FROM Contacts)
FROM Account
WHERE Industry = 'Technology'
```

### Aggregate

```sql
SELECT Status__c, COUNT(Id) total
FROM Car_Rental__c
GROUP BY Status__c
HAVING COUNT(Id) > 5
```

### Bind Variable ile Güvenli Sorgu

```apex
String searchTerm = '%' + String.escapeSingleQuotes(userInput) + '%';
List<Account> results = [SELECT Id, Name FROM Account WHERE Name LIKE :searchTerm];
```

## Anti-Pattern Tespiti

| Anti-Pattern | Çözüm |
|-------------|-------|
| SOQL inside for loop | Sorguyu döngü dışına al, Map kullan |
| SELECT tüm alanlar | Sadece gerekli alanları belirt |
| Unfiltered query (WHERE yok) | WHERE + LIMIT ekle |
| Non-selective query | İndeksli alan ile filtrele |
| Hardcoded ID in WHERE | Bind variable veya Custom Metadata kullan |
