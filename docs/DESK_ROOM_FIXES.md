# Masa etkileşimi düzeltmeleri — 18 Ekim 2026

Kapsam masa ve oda içindeki mevcut etkileşimdir. Yeni erzak/ekonomi veya dış dünya
mekaniği eklenmedi. Bu kayıt tamamlanmış AAA sanat üretimi iddiası değildir.

## Kullanıcıya görünen değişiklikler

- Müşterinin kartına **tek sol tık veya E**: aynı belge masaya gelir ve odak sahnesi
  otomatik olarak gerçek üstten kamera açısına geçer. İkinci dar hedef aranmaz.
  Oyuncu teslim sırasında uzaklaşırsa kamera onu uzaktan masaya çekmez.
- Masadan ayrıldıktan sonra **kart veya geniş masa yüzeyine tık/E** çalışma açısını
  geri açar. Q/WASD çıkışı ve önceki bakış korunur.
- Masada boş elle **sol tuş basılı**: kâğıt yüzeyden kalkar ve taşınır.
  **Sol tutarken sağ tuş + yatay fare** kartı yerinde döndürür. Bırakınca masanın
  veya minderin gerçek yüksekliğine iner. F, masada verilen açıyı koruyarak çevirir.
- Kamera kâğıdı daha yakından çerçeveler. Makas alındığında kesim yakınlığına geçer;
  sağ sürükleme ve tekerlekle masa üzerinde gezinme korunur.
- Kâğıtta asimetrik yükselen/bükülen köşeler, içeri kıvrılmış sağ üst köşe ve
  ön/arkada fiziksel metal zımba geometrisi var. Baskı aynı 3D yüzeye bağlı kalır.
- Makasın alt bıçağı kâğıdın altından geçer; üst bıçak ayrı bir menteşede açılır,
  kapanır ve dinlenir. Önceki görünür bıçak/kesim yüksekliği farkı giderildi.
- Kesim **yalnızca kapanma evresinde** ilerler. Açma ve bekleme evreleri kâğıdı
  kesmez. El, hareketli sapa eşlik eder; diğer el kâğıdı destekler.
- Snip sesi gerçek kesim yapan kapanış başına bir kez tetiklenir. 2 cm kesik,
  kupon sınırları ve tek parça/tek hak korunumu devam eder.

## Normal oyun penceresinden kayıt

Aşağıdaki hareketli görüntü motorun gerçek karelerinden üretildi. Sahne
`--selftest` olmadan çalıştı: test imleci/ekran dışı ışın veya zorla masa durumu
kullanılmadı. Normal viewport imleci, sol tık ve fare hareketleri kullanıldı.
Başlangıç bakışı kayıt için müşterinin kartına yöneltildi.

![Tek tıklamayla üstten kamera, kâğıdı kaldırma/döndürme ve açılıp kapanan makas](images/desk-direct-interaction.webp)

![Gerçek üstten masa](images/desk-auto-overhead.png)
![Masadan kaldırılmış, döndürülmüş kâğıt](images/desk-paper-lift.png)
![Hareketli bıçak açıkken](images/desk-scissors-open.png)
![Hareketli bıçak kapanırken](images/desk-scissors-closed.png)

Kayıt GL Compatibility/llvmpipe, 1600×1000, 30 sabit simülasyon adımıyla yapıldı;
her iki kareden biri kaydedilip 15 FPS hareketli WebP üretildi. Ses sürücüsü Dummy;
kayıt gerçek ses dinleme veya gerçek donanım performans ölçümü değildir.

Tekrar üretmek için:

```sh
godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
  --resolution 1600x1000 --fixed-fps 30 \
  --script res://tools/capture_desk_interaction.gd -- --capture=/tmp/kiosk81-desk-native
```

## Sürüm farkı

Uzak `main` dalı kontrol edildi: PR #1 ile birleştirilmiş önceki FPS sürümünü
başlatıyor. Bu yeni masa sürümü `codex/ration-card-desk` dalında;
`project.godot` ana sahnesi `scenes/kiosk/ration_desk_focus.tscn`.
Bu dal güncellendikten sonra F5 kullanılmalı. Eski açık sahneyi F6 ile çalıştırmak
başka bir prototipi başlatabilir. Kullanıcının yerel dalı henüz doğrulanmadı.

## Kontroller

- Birim: makas kapanışının açma/beklemeden ayrılması, FPS farkında aynı kesim mesafesi.
- Doğrudan masa regresyonu: tek tıkla üstten görünüm; kaldırma, sürükleme,
  döndürme, bırakma; dönmüş kartı çevirme ve geniş masadan tekrar giriş.
- Belge regresyonu: damgadan önce kesim, sonra onay, tek parça ve iade.
- Mevcut sekiz müşteri, kısmi kesim, damga ve eski satış yolu kontrolleri korunur.

Kesin çalıştırma sonuçları güncel kabul raporunda kaydedilir.
