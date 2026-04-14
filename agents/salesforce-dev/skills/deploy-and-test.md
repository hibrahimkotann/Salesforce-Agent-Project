# Skill: Deploy & Test

## Ne Zaman Kullanılır

Metadata deploy etme, retrieve etme veya test çalıştırma görevi geldiğinde bu skill'i uygula.

## Retrieve

```bash
# Tüm proje metadata'sını çek
sf project retrieve start --target-org mydevorg

# Belirli bir metadata türünü çek
sf project retrieve start --metadata ApexClass --target-org mydevorg

# Belirli bir component'i çek
sf project retrieve start --metadata ApexClass:CarRentalService --target-org mydevorg
```

## Deploy

```bash
# Tüm projeyi deploy et
sf project deploy start --target-org mydevorg

# Belirli bir klasörü deploy et
sf project deploy start --source-dir force-app/main/default/classes --target-org mydevorg

# Deploy preview (dry-run)
sf project deploy preview --target-org mydevorg

# Deploy ve testleri birlikte çalıştır
sf project deploy start --target-org mydevorg --test-level RunLocalTests
```

## Test Çalıştırma

```bash
# Tüm local testleri çalıştır
sf apex run test --test-level RunLocalTests --target-org mydevorg --wait 10

# Belirli bir test class'ını çalıştır
sf apex run test --tests CarRentalServiceTest --target-org mydevorg --wait 10

# Belirli bir test metodunu çalıştır
sf apex run test --tests CarRentalServiceTest.testCreateBooking --target-org mydevorg --wait 10

# Code coverage raporu
sf apex run test --test-level RunLocalTests --target-org mydevorg --code-coverage --wait 10
```

## Kontrol Listesi

1. Deploy öncesi `sf project deploy preview` ile nelerin değişeceğini kontrol et.
2. Deploy sonrası `sf apex run test` ile testleri çalıştır.
3. Coverage %75 altındaysa deploy başarısız olur — önce test ekle.
4. Production deploy'da `--test-level RunLocalTests` zorunlu.
