# KIOSK '81

Varşova, 1981–1989. Bir Ruch kioskunun arkasında, birinci şahıs bir anlatı simülasyonu.

- **Motor:** Godot 4.7.2 (standart sürüm, GDScript)
- **Açmak için:** Godot'u başlat → Import → bu klasördeki `project.godot` dosyasını seç.
- **Durum:** Çekirdek durum ve efekt hattı hazır (Yol Planı 1.4–1.6). Henüz oynanabilir bir şey yok.

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
