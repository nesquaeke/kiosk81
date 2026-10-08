# Koşul ve efekt dili (v0)

Yol Planı 1.7 · 4 Ekim 2026 · Kod: `game/core/conditions.gd`, `game/core/effect_pipeline.gd` · Testler: `tests/unit/test_conditions.gd`, `tests/unit/test_effect_pipeline.gd`

İçerik dosyaları (diyalog, olay, belge kuralı, müşteri ziyareti) iki şeyi düz veriyle söyler:

- **Koşul:** bu ne zaman olur? Örnek: "Halina'nın güveni 3 veya üstündeyse".
- **Efekt:** olunca ne değişir? Örnek: "Kasaya 2,90 zł ekle, Marek'in baskısını 1 artır".

Koşullar durumu yalnızca **okur**. Durumu yalnızca efektler değiştirir; efektler de her zaman `EffectPipeline` üzerinden, ya hep ya hiç biçiminde uygulanır.

## Koşulun biçimleri

| Biçim | Anlamı |
| --- | --- |
| `true` / `false` | Her zaman / hiçbir zaman |
| `[k1, k2, …]` | Liste, `{"all": [k1, k2, …]}` için kısa yazım |
| `{"all": [...]}` | Hepsi doğruysa doğru; boş liste doğru |
| `{"any": [...]}` | Biri doğruysa doğru; boş liste yanlış |
| `{"not": k}` | Tersi |
| `{"if": "<test>", ...}` | Tek bir test (aşağıdaki tablo) |

`all`, `any` ve `not` kendi nesnesindeki tek alan olmalıdır.

## Testler

| `if` | Alanlar | Ne okur |
| --- | --- | --- |
| `flag` | `key`; isteğe bağlı `cmp` + `value` | Hikâye bayrağı. `cmp` yoksa: bayrak var ve "boş değil" mi (false, 0, "" ve yokluk yanlış sayılır) |
| `relation` | `character`, `dimension`, `cmp`, `value` (tam sayı) | İlişki: `trust`, `suspicion`, `debt`, `leverage`, `affinity` |
| `money` | `account`, `cmp`, `value` (grosz) | Hesap: `till` (kasa), `commission` (prim), `pocket` (cep), `household` (ev bütçesi), `usd` (dolar, sent). 1 zł = 100 grosz |
| `meter` | `meter`, `cmp`, `value` (tam sayı) | Gösterge: `suspicion` (şüphe, 0–100), `solidarity`, `cooperation`, `family`, `halina` (0–100), `belief`, `marek_lean` (−100…100) |
| `stock` | `location`, `item`, `cmp`, `value` | Yer: `shelf`, `backroom`, `hidden` ya da hepsinin toplamı için `total` |
| `day` | `cmp`, `value` | Kampanyanın kaçıncı günü |
| `date` | `cmp`, `value` ("1982-03-15") | Takvim tarihi |
| `time` | `cmp`, `value` ("07:30") | Günün saati |
| `phase` | `is`: bir evre ya da liste | `morning`, `shift`, `closing`, `evening`, `night` |
| `status` | `character`, `is`: bir durum ya da liste | Karakter durumu; bilinmeyen karakter `active` sayılır |
| `memory` | `character`, `id` | Karakterin bu `id` ile bir anısı var mı |
| `decision` | `id` | Karar günlüğünde bu `id` var mı |

**Karşılaştırmalar (`cmp`):** `==`, `!=`, `<`, `<=`, `>`, `>=`.

- Sayılar değere göre karşılaştırılır.
- Yazılar yalnız `==` ve `!=` ile karşılaştırılır; yazıda sıralama sonucu her zaman yanlıştır.
- Farklı türler (sayı ile yazı gibi) hiçbir zaman eşit değildir.
- `date` ve `time` için sıralama doğal çalışır.

## Kurallar

1. **Bütün ağaç önce doğrulanır.** `any` ilk doğruda dursa bile arkadaki yazım hatası yine bildirilir.
2. **Bilinmeyen alan hatadır.** `"vaule"` gibi bir yazım hatası sessizce geçmez.
3. **Hatalı koşul asla doğru sayılmaz.** Oyun kodu `Conditions.is_true()` kullanır: hata konsola yazılır, sonuç yanlış olur. İçerik yüklenirken (Yol Planı 1.8) `Conditions.validate()` hataları dosya ve yol bilgisiyle listeler.
4. **Hata mesajı yeri gösterir.** Örnek: `all[1].not: day: field 'cmp' must be one of …` (ilk listenin 2. öğesi, onun içindeki `not`).
5. **Okumak bir şey yaratmaz.** Henüz görülmemiş bir karakter nötrdür: ilişkiler 0, durum `active`, anı yok.
6. **JSON sayıları:** JSON'dan okunan sayılar ondalıklı gelir (3 yerine 3.0). İçerik yükleyici bunları tam sayıya çevirir (`CampaignState.normalize_numbers`). Çevrilmemiş bir `3.0`, tam sayı isteyen alanda hata verir.

## Efektler

Her efekt bir `op` alanı taşır. Bir listedeki efektler sırayla, durumun bir **kopyası** üzerinde uygulanır. Biri bile hata verirse ya da sonunda bir kural bozulursa hiçbiri uygulanmaz. Bozulan kural örnekleri: eksi para, eksi stok, geçersiz evre, gece yarısını geçen saat.

| `op` | Alanlar | Ne yapar |
| --- | --- | --- |
| `money_add` | `account`, `amount` (grosz, eksi olabilir) | Hesaba ekler veya çıkarır |
| `stock_add` | `location`, `item`, `qty` | Stok ekler veya çıkarır |
| `stock_move` | `from`, `to`, `item`, `qty` (> 0) | Stoku bir yerden diğerine taşır; yeterli yoksa hata |
| `register_append` | `entry` (nesne) | Satış defterine satır yazar; gün ve dakika eklenir |
| `flag_set` | `key`, `value` | Bayrak koyar |
| `flag_add` | `key`, `amount` (tam sayı) | Sayaç bayrağına ekler; olmayan bayrak 0 sayılır, sayı olmayan bayrakta hata |
| `meter_add` | `meter`, `amount` | Göstergeyi değiştirir; değer göstergenin aralığında tutulur (kırpılır) |
| `day_advance` | (alan yok) | Ertesi sabah: gün + 1, tarih + 1, saat 07:30, evre `morning` |
| `clock_advance` | `minutes` (> 0) | Saati ilerletir |
| `phase_set` | `phase` | Evreyi değiştirir |
| `relation_add` | `character`, `dimension`, `amount` | İlişkiyi değiştirir |
| `memory_add` | `character`, `memory` (nesne, `id` önerilir) | Karaktere anı ekler; gün eklenir |
| `decision_log` | `entry` (nesne, `id` önerilir) | Karar günlüğüne yazar; gün ve dakika eklenir |
| `when` | `if` (koşul), `then` (efekt listesi), isteğe bağlı `else` | Koşula göre bir dalı uygular |

`when` koşulu, durumu **listede kendisinden önceki efektler uygulandıktan sonraki** haliyle görür.

## Örnekler

Akşam evde Marek'in soru sorduğu sahne, ancak Tadeusz onu yeterince sıkıştırdıysa açılır:

```json
{"all": [
  {"if": "phase", "is": "evening"},
  {"if": "flag", "key": "pressure_on_marek", "cmp": ">=", "value": 3},
  {"not": {"if": "status", "character": "marek", "is": ["arrested", "emigrated"]}}
]}
```

Bir müşterinin geçen hafta reddedildiğini hatırlaması:

```json
{"if": "memory", "character": "chr_old_woman", "id": "refused_cigarettes"}
```

Gizli yerdeki yeraltı gazetesini satmak. Rafta yoksa tezgâh altından gelir:

```json
[
  {"op": "when",
   "if": {"if": "stock", "location": "hidden", "item": "itm_underground_paper", "cmp": ">=", "value": 1},
   "then": [
     {"op": "stock_add", "location": "hidden", "item": "itm_underground_paper", "qty": -1},
     {"op": "money_add", "account": "pocket", "amount": 500},
     {"op": "decision_log", "entry": {"id": "sold_underground_paper"}}
   ],
   "else": [
     {"op": "flag_set", "key": "had_to_refuse_paper", "value": true}
   ]}
]
```

Örneklerdeki karakter, ürün ve bayrak adları yalnızca biçimi göstermek içindir. Gerçek adlar içerik dosyalarında belirlenecek.

## Sonra eklenecekler (ÖNERİ)

| Test | Ne zaman | Neden |
| --- | --- | --- |
| `knows` / `believes` | Bilgi sistemi (Yol Planı 3.3) | "Bilmediğini kullanma": karakter bir şeyi yalnız gerçekten öğrendiyse ona göre davranır |
| `event` | Olay sistemi (3.4) | Bir olay oldu mu, ne zaman oldu |
| `chance` | Gerektiğinde | Kampanya tohumuna bağlı, tekrarlanabilir şans |
