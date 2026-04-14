# Skill: Apex Development

## Ne Zaman Kullanılır

Apex class, trigger, batch, queueable veya schedulable yazma/düzenleme görevi geldiğinde bu skill'i uygula.

## Adımlar

1. Gereksinimi analiz et ve hangi Apex pattern'in uygun olduğunu belirle (Trigger Handler, Service Layer, Selector, Domain).
2. Mevcut kodu `sf project retrieve start` ile çek veya dosya sisteminden oku.
3. Bulkification kurallarına uygun şekilde kodla:
   - DML/SOQL döngü dışında
   - Koleksiyon kullanımı (List, Set, Map)
   - `Limits` class'ı ile runtime kontrol
4. `with sharing` keyword'ünü varsayılan kullan.
5. Hard-coded ID kullanma; Custom Metadata veya Custom Label tercih et.
6. İlgili test class'ını yaz veya güncelle (%90+ coverage hedefi).
7. `sf project deploy start --target-org mydevorg` ile deploy et.
8. `sf apex run test --target-org mydevorg --tests <TestClassName> --wait 10` ile testleri çalıştır.

## Trigger Handler Pattern

```apex
trigger ObjectNameTrigger on ObjectName (before insert, before update, after insert, after update, before delete, after delete) {
    ObjectNameTriggerHandler.handle(Trigger.operationType, Trigger.new, Trigger.oldMap);
}
```

```apex
public with sharing class ObjectNameTriggerHandler {
    public static void handle(System.TriggerOperation operationType, List<ObjectName> newList, Map<Id, ObjectName> oldMap) {
        switch on operationType {
            when BEFORE_INSERT { beforeInsert(newList); }
            when BEFORE_UPDATE { beforeUpdate(newList, oldMap); }
            when AFTER_INSERT  { afterInsert(newList); }
            when AFTER_UPDATE  { afterUpdate(newList, oldMap); }
        }
    }
}
```
