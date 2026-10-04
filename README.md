# KIOSK '81

Varşova, 1981–1989. Bir Ruch kioskunun arkasında, birinci şahıs bir anlatı simülasyonu.

- **Motor:** Godot 4.7.2 (standart sürüm, GDScript)
- **Açmak için:** Godot'u başlat → Import → bu klasördeki `project.godot` dosyasını seç.
- **Durum:** Çekirdek durum, efekt hattı ve koşul dili hazır (Yol Planı 1.4–1.7). Görsel deneme sahnesi var (1.6b); oynanış henüz yok.

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
- **Komut satırında:** `godot --headless --path . --script res://tools/run_tests.gd` (bütün testler geçerse çıkış kodu 0).

## Görsel deneme sahnesi

- **Açmak:** `scenes/sketch/visual_sketch.tscn` sahnesini aç ve **F6**'ya bas.
- **Tuşlar:** Bakmak için ekrana tıkla ve fareyi oynat (**Esc** fareyi bırakır). **1–4** retro seviyesini değiştirir (Kapalı, Hafif, Orta, Güçlü), **L** masa lambasını yakıp söndürür, **E** test belgesini açıp kapatır.
- Sahne gri kutulardan oluşur; ölçüler Yol Planı'ndan, renkler Görsel Hedef'ten gelir. Sahneyi elle değil, `tools/build_visual_sketch.tscn` aracıyla yeniden üret: `godot --headless --path . res://tools/build_visual_sketch.tscn`
