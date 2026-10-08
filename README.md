# KIOSK '81

Varşova, 1981–1989. Bir Ruch kioskunun arkasında, birinci şahıs bir anlatı simülasyonu.

- **Motor:** Godot 4.7.2 (standart sürüm, GDScript)
- **Açmak için:** Godot'u başlat → Import → bu klasördeki `project.godot` dosyasını seç.
- **Durum:** Altyapı hazır (Yol Planı Faz 1). **Oynanabilir deneme günü var: F5.** Kanon değil: müşteriler uydurma, karne basitleştirilmiş, fiyatlar geçici.

## Klasörler

| Klasör | İçerik |
| --- | --- |
| `game/` | Oyunun çekirdek kodu: durum, sistemler, kayıt, içerik yükleyici |
| `scenes/` | Godot sahneleri: kiosk, ev, oyuncu, müşteri, arayüz, efektler |
| `content/` | Oyun içeriği (JSON): ürünler, belgeler, kurallar, karakterler, olaylar |
| `dialogue/` | Diyalog dosyaları |
| `localization/` | Çeviri tabloları |
| `assets/` | Modeller, dokular, malzemeler, sesler, yazı tipleri, shader'lar |
| `tests/` | Otomatik testler |
| `tools/` | Yardımcı betikler |
| `docs/` | Tasarım belgelerine bağlantılar |

## Kurallar

- Bütün kod tipli GDScript'tir; tipsiz değişken derleme hatası verir.
- Oyunun durumunu yalnızca `Game` değiştirir; sahneler yalnızca gösterir.
- Kod ve dosya adları İngilizce, tasarım belgeleri Türkçe.

## Testleri çalıştırmak

- **Godot'ta:** `tests/run_tests.tscn` sahnesini aç ve **F6**'ya bas. Yazılar yeşilse bütün testler geçmiştir, kırmızıysa en az biri kırılmıştır.
- **Komut satırında:** `godot --headless --path . res://tests/run_tests.tscn -- --ci` (bütün testler geçerse çıkış kodu 0).

## Deneme günü (F5)

- **Açmak:** Godot'ta **F5** (ana sahne `scenes/kiosk/prototype.tscn`).
- **Ne var:** 15 Şubat 1982, 8 müşteri. Gazete, sigara (karneyle), kibrit satışı; rafları tezgâh altındaki kolilerden doldurma; karne kontrolü; deftere yazmak ya da parayı cebe atmak; komşu, milis ve Marek; gün sonu defteri (pencere + bütün gün: rutin satış, Ruch'a teslim, prim, ev gideri, şüphe) ve kayıt.
- **Tuşlar:** Fareyi ekran kenarına götür: etrafa bak · Kolilere tıkla: rafı doldur · Sağ tık: belgeyi incele · Q basılı: saat · 1–9: seçim · F2: English/Türkçe · F3: geliştirici paneli.
- **Sahneler kodla üretilir:** `godot --headless --path . res://tools/build_scenes.tscn` (dünya, görsel deneme ve deneme günü). Metinler: `localization/*.csv`; yeni metin eklenince `godot --headless --path . --script res://tools/extract_strings.gd`.

## Para ve risk simülasyonu

- `godot --headless --path . --script res://tools/simulate.gd -- --runs=200 --days=28`
- Dört oyun tarzını (dürüst, kasadan çalan, dikkatli, açgözlü) ekransız oynatır ve sonucu `docs/BALANCE_REPORT.md` dosyasına yazar. Sayılar `content/balance/balance.json` içindedir.

## Görsel deneme sahnesi

- **Açmak:** `scenes/sketch/visual_sketch.tscn` sahnesini aç ve **F6**'ya bas.
- **Tuşlar:** Bakmak için ekrana tıkla ve fareyi oynat (**Esc** fareyi bırakır). **1–4** retro seviyesini değiştirir (Kapalı, Hafif, Orta, Güçlü), **L** masa lambasını yakıp söndürür, **E** test belgesini açıp kapatır.
- Sahne gri kutulardan oluşur; ölçüler Yol Planı'ndan, renkler Görsel Hedef'ten gelir. Sahneyi elle değil, `tools/build_scenes.tscn` aracıyla yeniden üret.
