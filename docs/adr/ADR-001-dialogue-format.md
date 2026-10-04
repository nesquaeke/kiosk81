# ADR-001: Diyalog biçimi

Yol Planı 1.10 · 4 Ekim 2026 · Durum: **ONAYLANDI (Claude kararı; yönetmen "hızlı ilerleyelim" dedi, istenirse değiştirilir)**

## Karar

Diyaloglar, diğer içerik gibi **JSON kayıtları** olarak yazılır (`dialogue/*.json`, kayıt türü `dialogue`). Bir diyalog düğümlerden oluşur. Düğümlerdeki koşullar ve efektler, koşul ve efekt dilinin aynısını kullanır (`docs/CONDITION_LANGUAGE.md`). Çalıştırıcı `game/dialogue/dialogue_runner.gd`, örnek sahne `dialogue/test_newspaper.json`.

## Biçim

```json
{
  "id": "dlg_test_newspaper",
  "speakers": ["customer", "player"],
  "start": "ask",
  "if": {"if": "phase", "is": "shift"},
  "nodes": {
    "ask": {
      "lines": [
        {"speaker": "customer", "text": "Trybuna Ludu, please."},
        {"speaker": "customer", "text": "And don't tell me it's gone again.", "if": {"if": "flag", "key": "trybuna_sold_out_before"}}
      ],
      "choices": [
        {"text": "Here you are.", "if": {...}, "effects": [...], "goto": "thanks"},
        {"text": "Sold out, sorry.", "goto": "sold_out"}
      ]
    },
    "thanks": {"lines": [{"speaker": "customer", "text": "Thank you."}], "end": true}
  }
}
```

- **Konuşanlar:** karakter kimlikleri (`chr_…`) ya da roller (`player`, `customer`, `narrator`).
- **Düğüm:** `lines` (isteğe bağlı koşulla), isteğe bağlı `effects` (düğüme girilince) ve şu üçünden tam olarak biri: `choices`, `goto` ya da `"end": true`.
- **Seçenek:** `text`, isteğe bağlı `if` ve `effects`, ayrıca `goto` ya da `"end": true`.
- **Metin anahtarları otomatik:** `dlg_id.düğüm.l0` (replik), `dlg_id.düğüm.c0` (seçenek). Çeviriler `localization/content.csv` dosyasında; `tools/extract_strings.gd` yeni ve değişen satırları işaretler.
- **Durumu çalıştırıcı değiştirmez:** her adım uygulanacak efektleri geri verir, oyun bunları `Game.apply_effects` ile ya hep ya hiç uygular.
- **Doğrulama:** içerik yükleyici düğüm grafiğini denetler. Olmayan düğüme `goto`, eksik çıkış, bilinmeyen konuşan, hatalı koşul ya da efekt oyun açılırken dosya ve satırla bildirilir.

## Değerlendirilen seçenekler

| Seçenek | Artı | Eksi | Sonuç |
| --- | --- | --- | --- |
| **JSON düğümleri (seçilen)** | Koşul ve efekt dili aynen kullanılır; içerik yükleyici her şeyi doğrular; dış bağımlılık yok; çeviri anahtarları otomatik | Uzun sahnelerde yazması ve okuması zahmetli | v0 için seçildi |
| Ink (inkle) | Yazar dostu, dallanma güçlü | Godot eklentisi C#/.NET sürümü istiyor (biz standart sürümdeyiz); kendi değişkenleri bizim durumla ikiye bölünür | Hayır |
| Yarn Spinner | Yazar dostu, Godot desteği var | C# gerektiriyor; aynı durum bölünmesi | Hayır |
| Dialogue Manager eklentisi (GDScript) | Metin tabanlı, popüler | Koşullar GDScript ifadesi: bizim doğrulama ve ya hep ya hiç kuralını atlar; dış eklenti | Hayır |
| Kendi metin biçimimiz (`.dlg`) | En okunaklı | Ayrıştırıcı ve hata raporu yazmak gerek | **Sonra:** yazma yükü artarsa, aynı JSON'a derlenen bir katman olarak eklenir. Çalıştırıcı ve doğrulayıcı değişmez |

## Sonuçlar

- Bugünkü sahneleri Claude yazar ve JSON zahmetini Claude çeker. Yönetmen replikleri oyunda ya da `localization/content.csv` dosyasında okur.
- Metin biçimi gerekirse ADR-002 açılır. JSON kayıtları onun derleme hedefi olarak kalır.
