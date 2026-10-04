# Teknik mimari (v1)

Yol Planı 1.13 · 4 Ekim 2026 · Godot 4.7.2 (standart sürüm), tipli GDScript, dış eklenti yok.

## Tek cümlede

Oyunun bütün durumu tek bir veri nesnesindedir (`CampaignState`). İçerik JSON dosyalarından okunur (`ContentDB`). Oyuncunun her eylemi bir **efekt listesine** dönüşür ve `Game.apply_effects` ile ya hep ya hiç uygulanır. Sahneler durumu yalnızca **gösterir**.

## Katmanlar

| Katman | Nerede | Görevi | Neyi bilir |
| --- | --- | --- | --- |
| Veri | `game/core/campaign_state.gd` | Gün, saat, para (grosz), stok, defter, karakterler, bayraklar, karar günlüğü | Hiçbir sahneyi |
| Kurallar | `game/core/effect_pipeline.gd`, `conditions.gd` | Efektleri kopya üzerinde uygular, değişmezleri denetler; koşulları okur | Yalnız veriyi |
| İçerik | `game/content/` + `content/`, `dialogue/` | JSON kayıtlarını yükler ve doğrular | Şemaları, kuralları |
| Sistemler | `game/dialogue/`, ileride `game/systems/` | Diyalog, belge, ticaret, olaylar: efekt üretir, durumu kendisi değiştirmez | Veri, kurallar, içerik |
| Sahneler | `scenes/` | Kiosk, oyuncu, müşteri, arayüz; girdiyi sisteme iletir, sonucu gösterir | Hepsini; durumu yalnız `Game` üzerinden değiştirir |

## Autoload sırası

`Settings → ContentDB → Game → SaveManager → Audio → DevPanel`

Sonradakiler öncekilere güvenebilir. `Settings` dil tablolarını ilk o yükler, `ContentDB` içeriği oyun başlamadan doğrular.

## Bir eylemin yolu

1. Oyuncu bir şey yapar: bir seçenek seçer ya da bir nesneyi yuvaya bırakır.
2. İlgili sistem bir **efekt listesi** üretir. Örnek: stoktan 1 düş, kasaya 1,00 zł ekle, deftere yaz, saati 2 dakika ilerlet.
3. `Game.apply_effects(liste)` listeyi durumun kopyasına uygular. Bir adım bile hata verirse ya da sonunda bir kural bozulursa hiçbir şey değişmez ve `effects_rejected` sinyali gelir.
4. Başarılıysa yeni durum yerleşir ve `state_changed` sinyali gelir. Sahneler kendini bu sinyalle günceller.

## Kayıt

- Oyun yalnız **gün sınırlarında** kaydeder (tasarım kuralı). Bunu gün akışı uygular.
- `SaveManager`: `user://saves/slot_N.json`, sürüm numarası ve sağlama toplamı taşır. Önce geçici dosyaya yazar; 3 yedek tutar; bozuk dosyada en yeni sağlam yedeğe döner. Eski sürümleri göç zinciriyle adım adım yükseltir; daha yeni sürümü reddeder.
- Kayıtta içeriğin artık bilmediği kimlikler varsa oyun çökmez, `SaveManager.find_unknown_ids` bunları bildirir.

## Metin ve dil

- Kaynak dil İngilizce. İçerik dosyaları İngilizce metin taşır; her metnin sabit bir anahtarı vardır.
- Çeviriler `localization/*.csv` dosyalarında (`key,en,tr,_status`). `tools/extract_strings.gd` yeni ve değişen satırları işaretler.
- Kod içinde: `Loc.text(anahtar, kaynak)` içerik metni için, `Loc.ui(anahtar)` arayüz metni için. Tabelalar ve gazeteler oyun dünyasında Lehçe kalır.

## Görüntü

- 3B dünya `LoFiView` içinde düşük çözünürlükte çizilir (varsayılan Hafif: 960×540) ve noktalı renk geçişi ekleyen ekran shader'ından geçer.
- Arayüz ve belge inceleme görünümü bunun **üstünde**, tam çözünürlükte ve efektsizdir.
- Dünya malzemeleri `assets/shaders/lofi_world.gdshader` kullanır. Yüz, el ve belge malzemelerinde `lofi_weight = 0`.

## Testler

- `tests/unit`, `tests/save`, `tests/content` altındaki `test_*.gd` dosyaları.
- Editörde `tests/run_tests.tscn` + **F6**. Komut satırında `godot --headless --path . res://tests/run_tests.tscn -- --ci`: hepsi geçerse çıkış kodu 0.
- Testler sahne olarak çalışır, çünkü bazı kodlar autoload kullanır; Godot `--script` modunda autoload yüklemez.

## Kod kuralları

- Her değişken ve fonksiyon tipli; tipsiz bildirim derleme hatasıdır.
- Durumu yalnız efektler değiştirir; sahneler `Game.state` alanlarına doğrudan yazmaz.
- Rastgelelik kampanya tohumundan gelir (`rng_seed`), böylece aynı kayıt aynı sonucu verir.
- Kod ve dosya adları İngilizce, tasarım belgeleri Türkçe.
