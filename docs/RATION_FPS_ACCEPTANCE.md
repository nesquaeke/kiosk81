# FPS karne etkileşimi — kabul raporu

15 Ekim 2026 · Godot 4.7.2 standard · `codex/ration-card-desk`.

[Master prompt](RATION_FPS_MASTER_PROMPT.md) içindeki çekirdek etkileşim
uygulandı. Oyuncu aynı FPS göz kamerasıyla yürür, müşteriden karneyi masaya
alır, etkileşimle eğilir, belgeyi eline alıp çevirir, araçları kullanır;
satışta belge işlemlerinden sonra erzak toplar, tezgâha getirir ve teslim eder.
Ret ve alıkoyma doğrudan karne teslimiyle tamamlanır.

## Doğrulama sonucu

- Birim testleri: **186 geçti, 0 başarısız**.
- Headless FPS: kesintiler/regresyonlar ve sekiz müşteri **geçti**, çıkış 0.
- Pencereli FPS: aynı regresyonlar ve sekiz müşteri **geçti**, çıkış 0.
- 3D görüntüler: elde ön/arka, masada ön/arka, yama, kesilmiş kupon ve erzak
  taşıma incelendi. Yazı kontrastı ve raf etiketlerinin yüzey konumu düzeltildi.
- Özgün prosedürel ürün sesleri: altı dosya, içeri aktarım ve doğru temas
  olayları doğrulandı. Dalga örneklerinde kırpılma yok.

Pencereli kontrol 1600×1000, GL Compatibility ve yazılımsal llvmpipe ile yapıldı.
Dummy ses sürücüsünde ses olayları/dosyalar doğrulandı; gerçek aygıtta dinleme,
insan oyuncuyla ASMR değerlendirmesi veya hedef ekran kartında performans
sertifikası yapılmış sayılmaz.

## 28 kabul ölçütünün karşılığı

Aşağıdaki sıra master prompttaki kabul listesiyle aynıdır. “Geçti”, belirtilen
test/görsel kapsamındaki sonucu ifade eder.

| No | Ölçüt | Sonuç | Kanıt |
| --- | --- | --- | --- |
| 01 | Uzaktaki müşteri veya duvar arkasındaki araç alınamaz. | Geçti | FPS erişim + regresyon engel ışını |
| 02 | Oyuncu WASD ile yürür ve tezgâhın içinden geçmez. | Geçti | FPS gerçek WASD ve tezgâh çarpışması |
| 03 | Müşteriden alınan karne aynı dünya nesnesi olarak masaya yerleşir. | Geçti | Regresyon dünya teslimi + sekiz müşterilik FPS döngüsü |
| 04 | Oyuncu hemen geri çekilip yürüyebilir; karne görüşüne yapışıp gelmez. | Geçti | Regresyon teslim sırasında gerçek geri yürüme |
| 05 | Müşteri bekler; uzaklaşıp dönmek yeni müşteri veya yeni kart oluşturmaz. | Geçti | Regresyon kart konumu/işlem korunumu |
| 06 | Masadaki karta etkileşim aynı göz kamerasıyla eğilme başlatır. | Geçti | Regresyon eğilme + görüntü 06 |
| 07 | Q ve yürümeye başlamak eğilmeden çıkar; normal hareket ve bakış geri gelir. | Geçti | Regresyon Q ve WASD çıkışı |
| 08 | Sağ tuş bırakılmasa dahi açık çıkış/odak kaybı takılı incelemeyi temizler. | Geçti | Regresyon Esc ve Godot odak kaybı bildirimi |
| 09 | Karne masadan ele alınıp çevrilebilir; ön/arka alanlar okunabilir. | Geçti | FPS elde eğme/çevirme + fiziksel masa yönü testleri |
| 10 | Tekrar masaya bırakmak damgaları, kesimleri veya mevcut ürünü sıfırlamaz. | Geçti | Birim JSON/elde-masa dönüşü + regresyon geri dönme |
| 11 | Geçerli ve yıpranmış belgeyle doğru satış yapılabilir. | Geçti | FPS rc_01 ve rc_02 |
| 12 | Eski ay, kullanılmış kupon ve eksik onay uygun ret akışını destekler. | Geçti | FPS rc_03, rc_05 ve rc_07 |
| 13 | Sahte kurum veya değiştirilmiş kota doğru alıkoyma akışını destekler. | Geçti | FPS rc_04 ve rc_06 |
| 14 | Oyuncu yanlış karar verebilir ve sonuç ayrıca kayda geçer. | Geçti | Birim yanlış satış/ret/alıkoyma ve gün sonu kayıtları |
| 15 | Damga görünür temasta tek iz bırakır; ses temasla eşleşir. | Geçti | Regresyon temas öncesi/sonrası iptal ve ses sayısı |
| 16 | Yarım/iptal/çizgi dışı kesim kupon tüketmez ve hareketi kilitlemez. | Geçti | Regresyon Q ve çizgi dışı; FPS kısa kesim |
| 17 | Tam kesim tek kupon ayırır; iki yüzde aynı boşluk kalır. | Geçti | Kupon poz/hiza birim testleri + ön/arka görsel kontrol |
| 18 | Damga ve kesim, raflara gidip ürün almadan önce tamamlanabilir. | Geçti | FPS önce kesim, boş paket kontrolü, sonra raf |
| 19 | Yanlış raf veya yetersiz stok yanlış ürün/paket üretmez. | Geçti | Birim yanlış raf/yetersiz stok ve miktar testleri |
| 20 | Aynı sipariş için ikinci paket üretilemez; mevcut paket geri alınır. | Geçti | Birim yinelenen paket + ambalaj kimliği testi |
| 21 | Oyuncu ürünü odadan tezgâha taşır, bırakır, geri alır ve teslim eder. | Geçti | FPS taşıma/tezgâh/teslim + regresyon zemin/masa |
| 22 | Resmî ve gizli stoktan verme ayrı ve bilinçli seçimlerdir. | Geçti | FPS resmî/gizli et; birim ayrı stok/ödeme hesabı |
| 23 | İki kaynak da yetersizse kesim/teslim güvenli biçimde engellenir. | Geçti | Birim iki kaynak yetersizliği ve kupon korunumu |
| 24 | Kart ve ürün teslimi tek kez stok, para ve kayıt değiştirir. | Geçti | Birim atomik tek işlem/tekrar reddi + FPS |
| 25 | Teslim edilmiş ürünü sonradan retle hesaptan silmek mümkün değildir. | Geçti | Birim teslim edilmiş ürün karar kilidi |
| 26 | Damga/kesimden sonra masadan ayrılıp dönmek işlemi korur. | Geçti | Regresyon kesim sonrası ayrılıp geri eğilme |
| 27 | Alma, çevirme veya damga sırasında yeniden başlatma eski işlemi yeni güne taşımaz. | Geçti | FPS çevirirken restart + regresyon damga/bırakma restart |
| 28 | Duraklatma ve odak kaybından sonra araç, el, kamera ve çarpışmalar tutarlıdır. | Geçti | Regresyon odak/Esc; ambalaj ve el bağının korunması |

## Kalıcı testler

- [Karne kuralları](../tests/unit/test_ration_desk.gd): geçerlilik, yanlış karar,
  kaynak, miktar, tek işlem, ret/alıkoyma temizliği, JSON ve geçerli sabun satışı.
- [Fiziksel kâğıt yönü](../tests/unit/test_ration_card_pose.gd): gerçek Godot
  bazları, ön normal yukarı/arka normal aşağı, arka kupon hizası ve elde/masada
  dönüş. Eski Euler dönüşünün arka yüzü açmadığını yeniden üretir.
- [Ambalaj](../tests/unit/test_ration_parcel.gd): üç ürünün collider ve basılı
  etiketi, aynı fiziksel paketin/elin korunması, altı ürün foley olayı.
- [FPS kesinti regresyonları](../tests/fps_ration_regressions.gd): duvar engeli,
  teslim sırasında yürüme, gerçek masada çevirme/yüzeyden açıklık, Q/WASD çıkışı,
  Esc/odak bildirimi, temas öncesi/sonrası damga iptali, kesim/geri dönme,
  zemin/masa ürünü ve bırakma sırasında restart sonrası yeniden alma.
- [FPS oynanış testi](../scenes/kiosk/fps_kiosk.gd): gerçek E/G/R/F/fare
  girdileriyle sekiz müşteri, ürün/kart teslimi ve gün sonu defteri.

Hareket/erişim ayrıca gerçek girdilerle test edilir. Tekrarlı masa/raf
etkileşimlerinde fixture konumları kullanılır; sekiz müşterinin tüm yürüyüş
rotalarının otomatik oynandığı iddia edilmez. Odak kaybı, aynı Godot uygulama
bildirimi gönderilerek kontrol edilir. Belge doğruluğu test verisinde bilinir;
oyuncuya inceleme sırasında sonuç etiketi verilmez.

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest
godot --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest --capture=/tmp/fps-shots
```

`godot` 4.7.2 olmalıdır; buluttaki açık binary yolu AGENTS.md içinde bulunur.

## Oyuncu için

Godot'ta projeyi açıp F5 ile başlat. WASD ile cama yürü; uzatılan karneye E ile
etkileş. Karne masada kalır. Masadaki karta E ile eğil; Q veya yürüyüşle ayrıl.
R ele alır; sağ tuş/fare eğer, tekerlek yaklaştırır, F çevirir. G eldeki nesneyi
yüzeye bırakır. Araçları E ile alıp sol tuşla kullan. Satış damgası ve kupon
kesiminden sonra raflara yürü, ürünü E ile alıp tezgâha taşı. Ürünü ve kalan
karneyi müşteriye E ile ver; alıkoymada kartı belge bölmesine koy.

## Görüntüler

![Masadaki karneye eğilme](images/fps-desk-inspection.png)
![Aynı kartın masadaki gerçek arka yüzü](images/fps-desk-back.png)
![Elde ön yüz](images/ration-front.png)
![Elde arka yüz ve kurum onayı](images/ration-back.png)
![Değiştirilmiş hak: ön yüz](images/ration-tampered-front.png)
![Aynı fiziksel yamanın arka yüzü](images/ration-tampered-back.png)
![Kesilmiş kupon boşluğu](images/ration-cut.png)
![Dükkândaki fiziksel stoklar](images/fps-stock.png)
![Et paketini taşıma](images/fps-goods-hand.png)
![Ürünü tezgâha bırakma](images/fps-goods-counter.png)
![Şeker torbasını taşıma](images/fps-sugar.png)

## Kapsam sınırı

Bu, master prompttaki tek müşterili çekirdek döngüdür. Oda ve müşteri modelleri
basittir; tam vücut/IK, büyük yarı açık dünya haritası, gerçek mikrofon foley'i,
serbest tartım, para üstü, çok ürünlü sipariş ve günler arası kampanya sonraki
aşamalardır. Bu özellikler tamamlanmış olarak listelenmez. Mantıksal işlem
JSON dönüşümünde korunur; tam dünya transform kaydı/yükleme menüsü ayrı iştir.

Ürün ve kart birlikte tek muhasebe işlemiyle tamamlanır. Mevcut tek müşterili
dilimde başka sistem stok tüketmez. İleride paylaşılan stok/yeni NPC satışları
eklenirse teslim ile kart iadesi arasındaki rezervasyon ayrıca uygulanmalıdır.
