# Elde inceleme ve damga — ilk iki uygulama dilimi

> Sonraki dilim: [kâğıt çeşitleri, T ile ışığa tutma ve fiziksel rehber](PAPER_INSPECTION_UPDATE.md).

Dal: **`codex/ration-card-desk`**. Godot'ta bu checkout'un `project.godot`
dosyasını açıp **F5** ile başlat. Ana sahne `ration_desk_focus.tscn`.
GitHub Desktop'ta **Fetch origin → Current Branch → codex/ration-card-desk →
Pull origin** ile güncelle. F6 açık olan eski sahneyi çalıştırabilir.

Bu değişiklik, [onayladığın sıralı listenin](CARD_INTERACTION_BACKLOG.md)
ilk iki dilimini uygular: rahat elde inceleme ve okunaklı damga hizalama.
Diğer kâğıt aileleri, yeni sahtecilikler, mürekkep pedi, müşteri animasyonu ve
ses cilası o belgede sonraki işler olarak duruyor.

## Gerçek oyun kaydı

Aşağıdaki kayıt normal sahneden, `--selftest` olmadan alınmıştır. Gerçek viewport
imleci ve E/F/G/Esc/fare girdileri kullanılır; kâğıt kopyalanmaz, kampanya verisi
elle doldurulmaz, sahte bir hedef ışını veya ekran dışı fare kullanılmaz.

![Ele alma, elde döndürme/zoom/ters yüz, masaya bırakma ve fiziksel damga](images/card-inspection-workflow.webp)

## Yeni akış

1. Müşterinin kartına bakıp **E / sol tık**: karneyi eline al.
2. **F**: elde incelemeyi aç. Tuşu basılı tutman gerekmez.
3. **Sol sürükle**: serbestçe döndür. Fareyi bırakınca nesne kaymaya devam etmez.
4. **Tekerlek**: yakınlaş/uzaklaş. Mesafe sınırlıdır; nesne kameraya girmez.
5. **Sağ tık**: okunaklı ön/arka yüz konumuna çevir. **R** başlangıç duruşudur.
6. **F / Esc / Q**: önceki tutuşa dön. **WASD** incelemeyi bırakıp yürümeyi verir.
   Esc ilk basışta incelemeyi kapatır; ikinci basış menüyü açar.
7. Masaya bak: kâğıdın yerleşeceği çerçeve görünür. **E / G** ile koy;
   aynı kamera otomatik masanın üstüne geçer. Sonrasında **E** ile geniş masa
   yüzeyinden de geri açılabilir. Masada **F** kâğıdı çevirir; **R** ele alır.
8. Damgayı al; **SATICI ONAYI / KARAR** alanına yönelt. Baskının gerçek ölçü ve
   açısını gösteren soluk izdüşüm kâğıtta görünür. Araç/elin hizalama hedefini
   örtmemesi için damga yaklaşmadan önce hedefin yanında tutulur.
9. **Sol tut + fare aşağı** ile indir/bastır, bırakınca kaldır. İlk iki müşteride
   hedef çerçevesi bulunur; Esc menüsünden bu yardım kapatılabilir. Yer/açı
   önizlemesi karar doğruluğunu söylemez.

Yüzeye yanlış yerde fiziksel baskı yapabilirsin. İz kalır; yalnız satıcı karar
alanındaki baskı onay/ret/alıkoyma kararı kaydeder. Kâğıt dışına basılamaz.
Önizleme geçicidir; belge baskısına, kopan kupona veya kayıt verisine işlenmez.

Eldeki damga, makas, büyüteç ve kitapçık da FPS görünümündeyken F ile
incelenebilir. Masa çalışmasında F kâğıdı çevirmeye ayrılmıştır; aracı incelemek
istersen Q ile çalışma açısından çıkıp F kullan.

## Görünüm

![Elde aynı 3D karneyi yakından inceleme](images/card-inspection-front.png)
![Serbest dönüş ve yakınlaştırma](images/card-inspection-rotated.png)
![Gerçek baskıyla aynı ölçü/açıda damga önizlemesi](images/card-stamp-projection.png)
![Alan dışı baskı ve satıcı karar alanındaki kalıcı mürekkep](images/card-stamp-permanent.png)

## Korunan davranışlar

- Aynı fiziksel nesne, iki yüz, mevcut kesikler, kupon boşluğu ve mühürler korunur.
- İnceleme kartta bir iz/karar oluşturmaz. Kapatınca önceki tutuş, kamera
  özellikleri, ellerin görünürlüğü ve FPS kontrolü geri gelir.
- Ele alma animasyonu sürerken basılan F sıraya alınır; giriş yutulmaz.
- Odak kaybı, Q, Esc, yürüyüş ve yeniden başlatma yarım dönüşte kilit bırakmaz.
- Masa açısından ayrılırken hemen F açmak kamera/FOV'u yarım bırakmaz.
- Damga ve kâğıt ayrı döndürülse bile önizleme ve mürekkep aynı kâğıt
  koordinatlarını kullanır; yanal bulaşma fiziksel hareketin yönünü korur.
- 2 cm kalıcı kesik, dört kenarda kupon ayrılması ve damgadan önce kesim temeli
  korunur. Odak modu ürün toplamadan, stok veya para değiştirmeden tamamlanır.

## Doğrulama

- **232 birim testi geçti, 0 başarısız.** Alan dışı fiziksel iz, kararın korunması,
  JSON dönüşümü ve kâğıt dışı/NaN/kopmuş kupon boşluğu konumlarının reddi için yeni kontroller dahildir.
- **Headless odak koşusu geçti:** elde inceleme, doğrudan masa, kesimden sonra
  onay ve sekiz müşteri; ürün/para değişmedi.
- **Eski satış sahnesi headless koşusu geçti:** kesinti regresyonları ve sekiz
  müşterilik ürün teslimi. Eski sahnenin elde kontrol düzeni korunur.
- **Normal pencere kaydı geçti:** E/F/fare/zoom/ters yüz/Esc/G, fiziksel bırakma
  çerçevesi, üstten kamera, gerçek damga hedefi, alan dışı iz ve karar damgası.
- **Pencereli odak koşusu geçti:** elde inceleme ve hızlı masa/F geçişi, kalıcı
  hasar, doğrudan masa, kesimden sonra onay ve sekiz müşteri.
  Çalıştırılmış son koşuda GDScript/engine hatası yok; yalnız yazılım ekran
  sürücüsünün V-Sync uyarısı var.

Görüntüler 1600×1000, GL Compatibility, llvmpipe ve Dummy ses sürücüsüyle
alındı. Compatibility'de alan derinliği/bulanıklık yoktur. Forward+ için inceleme
sırasında kamera alan derinliği bağlandı; o görsel efekt bu ortamda doğrulanmadı.
Gerçek ses aygıtında dinleme, insan oyuncuyla kullanılabilirlik/eğlence testi,
hedef ekran kartı performansı veya bitmiş AAA sanat kalitesi iddia edilmez.

Tekrar üretmek için Godot 4.7.2 kullan:

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest
godot --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest --inspection-only
godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest
godot --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 30 --resolution 1600x1000 --path . --script res://tools/capture_card_inspection.gd -- --capture=/tmp/kiosk81-card-inspection
ffmpeg -framerate 15 -i /tmp/kiosk81-card-inspection/frames/%04d.png -vf scale=1280:-1 -loop 0 -c:v libwebp_anim -quality 78 /tmp/card-inspection-workflow.webp
```

Bulut binary yolu `AGENTS.md` içindedir. Grafik komutları çalışan bir display
ister; aynı X display üzerinde iki oyunu eşzamanlı çalıştırmak fare yakalamayı
bozar. Pencereli kontrolleri sırayla çalıştır.
