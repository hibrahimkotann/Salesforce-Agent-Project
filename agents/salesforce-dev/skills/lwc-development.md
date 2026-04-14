# Skill: LWC Development

## Ne Zaman Kullanılır

Lightning Web Component oluşturma, düzenleme veya debug etme görevi geldiğinde bu skill'i uygula.

## Adımlar

1. Component adını camelCase olarak belirle (örn: `carBookingForm`).
2. `.html`, `.js`, `.css`, `.js-meta.xml` dosyalarını oluştur.
3. Apex controller gerekiyorsa `@AuraEnabled(cacheable=true)` ile wire-uyumlu metot yaz.
4. `@wire` decorator'ı tercih et; imperative çağrıyı yalnızca DML veya koşullu çağrı gerektiğinde kullan.
5. SLDS class'larını ve design token'larını kullan, custom CSS'i minimumda tut.
6. Error handling için `try-catch` ve `ShowToastEvent` uygula.
7. Deploy et ve org'da test et.

## Component Yapısı

```
force-app/main/default/lwc/
  componentName/
    componentName.html
    componentName.js
    componentName.css
    componentName.js-meta.xml
```

## Meta XML Şablonu

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
    </targets>
</LightningComponentBundle>
```

## Wire vs Imperative Karar Tablosu

| Senaryo | Tercih |
|---------|--------|
| Sayfa yüklenirken veri çek | `@wire` |
| Buton tıklamasıyla veri çek | Imperative |
| DML işlemi (insert/update/delete) | Imperative |
| Reactive parametre ile otomatik güncelleme | `@wire` |
