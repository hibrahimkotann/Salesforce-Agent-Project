# Skill: Deploy Error Analysis & Recovery

## Ne Zaman Kullanılır

`sf project deploy start` komutu hata verdiğinde bu skill'i uygula. Hata mesajını oku, kök nedeni tespit et ve düzeltme adımlarını sistematik şekilde uygula.

## Hata Analiz Akışı

```
Deploy Hatası Alındı
       │
       ▼
1. Hata mesajını tam oku
       │
       ▼
2. Hata kategorisini belirle (aşağıdaki tabloya bak)
       │
       ▼
3. İlgili dosyayı/metadata'yı tespit et
       │
       ▼
4. Düzeltmeyi uygula
       │
       ▼
5. sf project deploy preview ile doğrula
       │
       ▼
6. Tekrar deploy et
```

## Adım 1: Detaylı Hata Çıktısını Al

Deploy başarısız olduğunda önce detaylı hata logunu çek:

```bash
# Son deploy sonucunu detaylı göster
sf project deploy report --target-org mydevorg

# JSON formatında detaylı çıktı (parse etmek için)
sf project deploy start --target-org mydevorg --json 2>&1

# Belirli bir deploy ID'nin sonucunu kontrol et
sf project deploy report --job-id <deployId> --target-org mydevorg
```

## Adım 2: Hata Kategorisini Belirle ve Çöz

### Kategori 1 — Apex Compile Error

**Belirtiler:** `Error: Compilation failed`, `Variable does not exist`, `Method does not exist`, `Type not found`

**Çözüm Adımları:**
1. Hata mesajındaki dosya adı ve satır numarasını bul.
2. İlgili dosyayı aç ve syntax/reference hatasını düzelt.
3. Bağımlılık eksikse (başka bir class'a referans) o class'ın da deploy scope'unda olduğundan emin ol.

```bash
# Sadece hatalı class'ı deploy et (bağımlılıkla birlikte)
sf project deploy start --source-dir force-app/main/default/classes/ClassName.cls --target-org mydevorg
sf project deploy start --source-dir force-app/main/default/classes/ClassName.cls-meta.xml --target-org mydevorg
```

**Sık Görülen Compile Hataları:**

| Hata | Sebep | Çözüm |
|------|-------|-------|
| `Variable does not exist: X` | Yanlış alan adı veya typo | Object field API adını kontrol et |
| `Method does not exist or incorrect signature` | Metot imzası uyumsuz | Parametre tipleri ve sayısını doğrula |
| `Type is not visible: X` | Access modifier sorunu | `public` veya `global` olarak değiştir |
| `Non-void method might not return a value` | Eksik return ifadesi | Tüm kod dallarında return ekle |
| `Dependent class is invalid` | Bağımlı class compile hatası | Önce bağımlı class'ı düzelt |

### Kategori 2 — Test Failure

**Belirtiler:** `Test failure`, `System.AssertException`, `INSUFFICIENT_ACCESS`, code coverage yetersiz

**Çözüm Adımları:**
1. Hangi test class ve metodunun fail ettiğini tespit et.
2. Hata detayını oku:

```bash
sf apex run test --tests FailedTestClass --target-org mydevorg --wait 10 --json
```

3. Assert hatalarında beklenen vs gerçek değeri karşılaştır.
4. Coverage yetersizse eksik satırları tespit et:

```bash
sf apex run test --tests TestClassName --target-org mydevorg --code-coverage --wait 10
```

**Sık Görülen Test Hataları:**

| Hata | Sebep | Çözüm |
|------|-------|-------|
| `System.AssertException: Assertion Failed` | Beklenen değer tutmuyor | Test verisini ve iş mantığını kontrol et |
| `MIXED_DML_OPERATION` | Setup/non-setup DML aynı context'te | `System.runAs()` veya `Test.startTest()` ile ayır |
| `REQUIRED_FIELD_MISSING` | Test verisinde zorunlu alan eksik | `@TestSetup`'ta tüm required alanları doldur |
| `INSUFFICIENT_ACCESS` | Sharing/permission sorunu | `System.runAs()` ile uygun profilli user kullan |
| Coverage < %75 | Test yetersiz | Positive, negative ve bulk senaryoları ekle |

### Kategori 3 — Missing Dependency / Reference Error

**Belirtiler:** `Entity of type X named Y cannot be found`, `Invalid type`, `Field does not exist`

**Çözüm Adımları:**
1. Eksik metadata'yı tespit et (custom object, field, record type vb.).
2. Org'da var mı kontrol et:

```bash
# Object'in org'da olup olmadığını kontrol et
sf sobject describe --sobject ObjectName__c --target-org mydevorg --json

# Tüm custom object'leri listele
sf sobject list --sobject custom --target-org mydevorg
```

3. Eksik metadata'yı projeye ekle veya retrieve et:

```bash
sf project retrieve start --metadata CustomObject:ObjectName__c --target-org mydevorg
sf project retrieve start --metadata CustomField:ObjectName__c.FieldName__c --target-org mydevorg
```

4. Deploy sıralamasını düzelt — bağımlılıklar önce deploy edilmeli.

### Kategori 4 — Profile / Permission Error

**Belirtiler:** `Cannot set a value for X`, `Profile does not exist`, `Permission set assignment failed`

**Çözüm Adımları:**
1. Hatalı profile/permission metadata'sını bul.
2. Org'daki profile ile lokaldeki arasındaki farkı kontrol et.
3. Profile metadata'sında olmayan field veya object referansını kaldır.
4. Alternatif: profile'ı deploy scope'undan çıkar.

```bash
# Profile hariç deploy et
sf project deploy start --source-dir force-app/main/default/classes --target-org mydevorg
```

### Kategori 5 — Component Conflict / Already Exists

**Belirtiler:** `Cannot create a new component with the name X. A component with that name already exists`, `Duplicate value`

**Çözüm Adımları:**
1. Org'daki mevcut component'i kontrol et.
2. İsim çakışması varsa ya lokaldeki adı değiştir ya da org'dakini sil/güncelle.
3. Retrieve yaparak org versiyonunu çek ve karşılaştır.

```bash
sf project retrieve start --metadata ApexClass:ConflictingClassName --target-org mydevorg
```

### Kategori 6 — API Version Mismatch

**Belirtiler:** `Invalid version`, `API version X is not supported`

**Çözüm Adımları:**
1. Hatalı dosyanın `-meta.xml`'indeki `<apiVersion>` değerini kontrol et.
2. Org'un desteklediği API versiyonunu doğrula:

```bash
sf org display --target-org mydevorg
```

3. `-meta.xml` dosyasındaki versiyonu org ile uyumlu hale getir (şu an **66.0**).

### Kategori 7 — Deployment Already In Progress

**Belirtiler:** `ALREADY_IN_PROGRESS`, `Another deploy is in progress`

**Çözüm Adımları:**

```bash
# Bekleyen deploy'ları kontrol et
sf project deploy report --target-org mydevorg

# Gerekirse iptal et
sf project deploy cancel --job-id <deployId> --target-org mydevorg
```

## Adım 3: Düzeltme Sonrası Doğrulama

Her düzeltmeden sonra şu sırayı takip et:

```bash
# 1. Preview ile kontrol et
sf project deploy preview --target-org mydevorg

# 2. Deploy et
sf project deploy start --target-org mydevorg

# 3. Testleri çalıştır
sf apex run test --test-level RunLocalTests --target-org mydevorg --wait 10

# 4. Coverage kontrol et
sf apex run test --test-level RunLocalTests --target-org mydevorg --code-coverage --wait 10
```

## Hata Çözüm Karar Ağacı

```
Hata mesajını oku
│
├─ "Compilation failed" → Kategori 1 (Apex Compile)
├─ "Test failure" / "Assert" → Kategori 2 (Test Failure)
├─ "cannot be found" / "does not exist" → Kategori 3 (Missing Dependency)
├─ "Profile" / "Permission" → Kategori 4 (Permission Error)
├─ "already exists" / "Duplicate" → Kategori 5 (Component Conflict)
├─ "API version" / "Invalid version" → Kategori 6 (API Version)
└─ "ALREADY_IN_PROGRESS" → Kategori 7 (Deploy In Progress)
```
