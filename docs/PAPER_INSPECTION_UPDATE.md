# Kâğıt çeşitleri ve ışıkla inceleme — 18 Ekim 2026

Dal: **`codex/ration-card-desk`**. Aynı klasördeki `project.godot` dosyasını açıp
**F5** ile başlat. GitHub Desktop: **Fetch origin → Pull origin**.
Bu sürüm [sıralı listenin](CARD_INTERACTION_BACKLOG.md) kâğıt malzemesi dilimini
ve fiziksel kanıt karşılaştırmasının ilk bölümünü uygular.

## Nasıl kullanılır?

1. Müşterinin kartını E ile ele al, F ile yakından incele.
2. T ile ışığa tut. Sol sürükleyerek eğ; filigranın ve liflerin ışığı geçirişi
   açıya göre değişir. T tekrar normal ışığa döner.
3. Sağ tıkla aynı kâğıdın arkasına bak. Asimetrik desen aynı fiziksel yerde
   ters yönde görünür; yeni bir ön yüz resmi açılmaz.
4. Mevcut değiştirilmiş kota örneğinde ek kâğıt, filigranın geçişini örter.
   Yandan bakmak yükselen kenarı, büyüteç tutkal çizgisi ve lifleri gösterir.
5. F/Esc/Q ile önceki tutuşa dön, E/G ile masaya koy. Işık, kesik veya
   damgaları değiştirmez; çıkınca ışık modu temizlenir.
6. Referans kitapçığını E ile al. Q ile masa açısından ayrıl, F ile incele,
   sağ tıkla arkasını çevir: üç çizimli karşılaştırma örneği bulunur.
   Ön yüzde sınıf, kota ve kurum mührü örnekleri kalır.

## Normal oyun penceresinden kayıt

Aşağıdaki akış normal sahnede gerçek E/F/T/Esc/G/fare girdileriyle çekildi.
`--selftest`, ekran dışı imleç, kopya kart veya elle üretilmiş kampanya verisi yok.
Kayıt için motor zamanı 30 FPS'e sabitlenip her iki kareden biri kaydedilir;
bu hedef ekran kartında performans ölçümü değildir.

![Aynı 3D kartı ışığa tutma, eğme, ters yüz ve fiziksel kitapçığın arka sayfası](images/paper-inspection-workflow.webp)

![Normal incelemede kâğıt ve baskı](images/paper-inspection-normal.png)
![Işık altında aynı kâğıdın filigranı](images/paper-inspection-light.png)
![Kitapçığın fiziksel arka sayfası](images/paper-evidence-guide.png)

## Değişen malzeme ve baskı

| Stok | Gerçek kalınlık | Görsel/hareket farkı |
| --- | --- | --- |
| İnce | 0,14 mm | Daha esnek; ışığı daha güçlü geçirir, arka baskının izi daha belirgin |
| Orta | 0,28 mm | Dengeli lif, esneme ve geçirgenlik |
| Kalın | 0,48 mm | Daha sert; lifli çekirdek ve daha düşük geçirgenlik |

Kalınlık yalnız bir etiket değildir: iki yüzün mesafesi, dış/kesik kenarları
ve kopmuş kupon aynı stok ölçüsünü kullanır. Fareyle belgeye vurulan nokta
artık sabit boşluk yerine görünür yüzeyin kalınlığını takip eder.

İşçi, öğretmen ve emekli baskılarının kenar süsü, arma ve form kodu ayrıdır.
Ornamental matbaa kayması, gerçek veri alanlarını ve kupon kesim sınırlarını
kaydırmaz. Matbaa başlıkları, daktilo alanları, kalemle atılmış imza ve kauçuk
mühür farklı görünür. Aşınma, nem/yağ benzeri yaygın lekeler ve lifler belge
serisine bağlıdır; her bakışta yeniden rastgeleleşmez.

Kopmuş kupon artık kendi önceki damgasını da taşır. Lif/kesik koordinatları ana
kâğıttaki yerinden devam eder. Hasar dokusunun bağımsız snapshot'ı ve kendi stok
profili, sonraki müşteri geldiğinde eski parçanın değişmesini önler.

## Karar hâlâ oyuncunun

Stok seçimi sınıf, kurum, hak miktarı, eksik mühür veya sahtecilik bilgisi okumaz.
Yıpranmış geçerli öğretmen kartı ile değiştirilmiş kart aynı kâğıt ailesinden
gelebilir; kalın kâğıt da tek başına sahte sayılmaz. T veya büyüteç otomatik
onay, kırmızı/yeşil suçluluk vurgusu ya da başarı sesi üretmez.

Arka rehber üç şeyi karşılaştırmayı öğretir: geçirgen rozet/dal deseni,
kota alanındaki katman/kenar ve olağan kat/aşınma. Desen oyun için tasarlanmış
kurmaca bir kâğıt fabrikası işaretidir; tarihsel sertifika iddiası değildir.

Aşağıdaki örnekler ayrıca sekiz müşterilik pencereli kabul koşusundan alınmıştır:

![Mevcut kota yamasında filigranın örtülmesi](images/paper-quota-transmission.png)
![Yıpranmış ama geçerli ince öğretmen kartı](images/paper-worn-thin.png)
![Kalın stokta ayrı emekli baskı ailesi](images/paper-thick-stock.png)

## Doğrulama ve sınırlar

- **237 birim testi geçti, 0 başarısız.** Stok/suçluluk bağımsızlığı, JSON/seri
  kararlılığı, üç fiziksel kalınlıkta iki yüz/kenar/hedef eşleşmesi, kuponun
  orijinal mürekkep/hasar snapshot'ı ve rehberin arkasının doğru yönü sınandı.
- **Headless odak koşusu geçti:** T/açı/ters yüz, kampanya verisinin değişmemesi,
  Esc/odak kaybı/restart temizliği, mevcut elde/masa regresyonları ve sekiz müşteri.
- **Pencereli odak koşusu geçti:** aynı regresyonlar, büyüteç, damga, kalıcı 2 cm
  kesik, kupon ayırma ve sekiz müşteri; stok/para değişmedi. GDScript/engine hatası
  yok; yalnız yazılım ekran sürücüsünün V-Sync uyarısı var.
- **Eski satış akışının headless koşusu geçti:** kesinti kontrolleri ve sekiz
  müşterilik erzak/satış yolu ortak malzeme değişiklikleriyle çalıştı.
- **Normal pencere kaydı geçti:** son ışık ayarıyla E/F/T/çevirme/Esc/G ve
  kitapçığın fiziksel arka sayfası. 77 gerçek motor görüntüsü animasyona alındı;
  son koşuda GDScript/engine hatası yok.

GL Compatibility/llvmpipe ve Dummy ses sürücüsü kullanıldı. Geçirgenlik, normal
ve ışık yönüne tepki veren bir oyun shader'ıdır; tam optik/kâğıt fiziği değildir.
Kalınlık farkı gerçektir fakat zoom olmadan milimetre altı kenarı okumak zordur.
Kesilen kuponun köşesinde mevcut yuvarlatılmış siluet/sabit kenar yaklaşımı
vardır; serbest kâğıt topolojisi ve bütün kesim cilası sonraki makas dilimindedir.

Fotoğraf değiştirme, kazınmış tarih, ayrı kimlik belgesi karşılaştırması, yeni
müşteri soru/cevapları ve mürekkep pedi bu sürümde eklenmedi. ASMR için yeni
ses üretimi/dinleme yapılmadı; insan oyuncuyla eğlence testi ve hedef GPU
performansı doğrulanmış sayılmaz. İlerleme durumu sıralı listede tutulur.

## Tekrar çalıştırma

Godot 4.7.2 kullan; bulut binary yolu `AGENTS.md` içindedir. Grafik komutları
çalışan bir display ister. Aynı display üzerinde iki oyunu birlikte çalıştırma.

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest
godot --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest --capture=/tmp/kiosk-paper-shots
godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest
godot --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 30 --resolution 1600x1000 --path . --script res://tools/capture_paper_inspection.gd -- --capture=/tmp/kiosk81-paper-native
ffmpeg -framerate 15 -i /tmp/kiosk81-paper-native/frames/%04d.png -vf scale=1280:-1 -loop 0 -c:v libwebp_anim -quality 78 /tmp/paper-inspection-workflow.webp
```
