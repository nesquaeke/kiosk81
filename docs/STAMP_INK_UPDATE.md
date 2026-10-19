# Fiziksel mürekkep pedi, damga ve yaş baskı

19 Ekim 2026. [Sıralı planın](CARD_INTERACTION_BACKLOG.md) 6. dilimi.
Kapsam fiziksel masa, mevcut kâğıt ve eldeki aletlerdir; erzak, ödeme veya oda genişlemesi eklenmez.

GitHub Desktop’ta `main` dalını Pull yapıp Godot F5 ile dene.
Geliştirme dalı `codex/ration-card-desk` aynı aşamayı içerir.
İlk geçerli müşterinin karneyi E ile uzatması ve G ile masaya bırakılması önceki akışla aynıdır.

## Oyuncunun yapabildikleri

Masanın sol önündeki açık kap bir mürekkep pedidir. Keçe, metal menteşe,
kapak, kilit ve basılı `TUSZ / MÜREKKEP` etiketi aynı 3D nesnenin parçalarıdır.
Bir karar damgasını E ile al, keçe üzerine hizala; sol tuşu basılı tutup fareyi
aşağı sür. Lastik gerçekten keçeye değince keçe sıkışır ve o damga mürekkep alır.
Yaklaşmak veya havada beklemek yükü değiştirmez. Kaldırmak dolumu durdurur;
tuş hâlâ basılıyken tekrar indirmek yeni bir fiziksel temastır.

Her damganın ayrı lastiği ve mürekkep yükü vardır. Başlangıç yükü 0,75,
kâğıda her fiziksel temasın tüketimi 0,012’dir. Aynı damgayla 16 normal baskıdan
sonra hâlâ 0,55’in üzerinde yük kalır; her müşteride pede dönmek gerekmez.
Kısa bir ped teması yükü zamana bağlı artırır. Yük 0–1 aralığındadır.
Tamamen boş lastik mekanik temas yapar ama kâğıda karar veya hayalî mürekkep yazmaz.
Soluk ama gerçek baskı ise yanlış bir kararı engellemez; mürekkep bir sahtecilik testi değildir.

Damga eldeyken Q ile masadan ayrılıp F ile inceleyebilirsin. Sağ tıkla çevir,
sol sürüklemeyle alt yüzü gözüne döndür. Alt yüzdeki ters çerçeve, yazı ve tarih,
kâğıda basılan düzenle aynıdır. Lastiğin yalnız basan bölgelerinde mürekkep
kaplaması vardır; yük, rengi ve parlaklığı etkiler. İncelemek yük tüketmez.

Kâğıt üzerinde önce yönü ve eğimi seçersin. Shift+tekerlek yüzeyi kâğıt
düzleminde döndürür; Alt+tekerlek lastiği yana yatırır. Sol tuş+aşağı hareket
indirip bastırır. Hız, bekleme ve basınç baskının gözeneklerini ve yoğunluğunu;
eğim ise hangi omuzun daha az temas ettiğini değiştirir. Sol ve sağ tuşu birlikte
tutup hareket ettirmek, temas hâlindeki lastiği iki yönde kaydırır.

Temastan önceki yanal hareket yalnız gerçek çarpma yerini değiştirir, hayalî
bir bulaşma üretmez. Lastik kâğıttan ayrılınca o baskı sabit kalır; havadaki
hareketler leke değildir. Tuşu bırakmadan tekrar kâğıda değersen yeni bir iz ve
bir tüketim oluşur. Basılı beklemek her karede tekrar mürekkep tüketmez.

Yeni baskı 8–12 oyun saniyesinde kurur. İnce, yerel sıvı kaplama yalnız gerçek
mürekkep çizgileri üzerinde ışığa bağlı parlaklık üretir; kâğıdın bütünü parlamaz.
Kuruyunca basılı iz yerinde kalır. Duraklatma ve uygulama odağının kaybı kuruma
saatini durdurur. Karneyi çevirmek veya F ile incelemek izi yeniden ıslatmaz.

Damgayı bırakıp boş elle **Alt+sol sürükle** yaparak yaş baskıya dokunabilirsin.
Bu hareket kâğıdı kaldırmaz; işaret parmağı aynı yüzeydeki temas noktasını izler.
Yalnız dokunulan çizgi/harflerden, gerçek sürükleme yönünde mürekkep taşınır.
İz hareket sırasında oluşur: parmağı basılı tutup baskının kurumasını beklemek
önceden oluşmuş lekeyi silmez. Kurumuş baskı aynı hareketle bulaşmaz.
Düz hareketlerin örnekleri birleştirilir; köşeli yol ayrı yönlerini korur.

## Kontroller

| Durum | Girdi | Davranış |
| --- | --- | --- |
| Masadaki karar damgası | E | Aynı aracı ele al |
| Damga elde, keçe veya kâğıt üzerinde | Sol tuşu tut + aşağı sür | İndir, temas et, bastır |
| Keçede temas | Basılı bekle | Yalnız eldeki damgaya mürekkep al |
| İndirilmiş damga | Yukarı sür / tuşu bırak | Gerçek yüzey temasını bitir |
| Damga hizalarken | Shift+tekerlek | Kâğıt düzleminde döndür |
| Damga hizalarken | Alt+tekerlek | Lastiği yana eğ |
| Damga kâğıda değmişken | Sol+sağ tuşu tut + sürükle | İki yönde temas lekesi |
| Boş el, ön yüz masada | Alt+sol sürükle | Kâğıdı kaldırmadan mürekkebe dokun |
| Damga elde | Q → F | Aynı lastiğin alt yüzünü yakından incele |
| İncelemede | Sol sürükle / tekerlek / sağ tık | Döndür / yakınlaş / çevir |
| İşlem sırasında | Q / WASD / Esc | Temas etmiş izi koruyup çık; Esc duraklatır |

## Durum sözleşmesi

- `StampInkState`, her fiziksel damganın ayrı yükünü ve tek temas tüketimini tutar.
  Karar, sahtelik, para veya stok okumaz. Yeniden başlatmada başlangıç yüküne döner.
- `RationDeskRules`, fiziksel izde `ink_load`, `tilt`, `contact_time` ve
  `dry_duration` değerlerini ilk temasta sabitler. Sonraki basınç/bekleme aynı
  izi geliştirir; temas zamanı veya ilk yük tekrar yazılmaz.
- `ink_clock` vardiya boyunca korunur. Görsel geçen zaman fiziksel baskı/parmak
  komutunda bu saate kaydedilir; yalnız bir nesneyi incelemek kampanya durumunu
  değiştirmez. Görünüm saatini `TIME` veya duvar saati yönetmez.
- `StampWetnessView`, baskıyla aynı harf/çerçeve/gren düzeninin şeffaf maskesidir.
  Yalnız ıslaklık değişince, en fazla 20 Hz yeniden çizilir. Mürekkep baskısının
  kendisi kuruma için tekrar üretilmez.
- Kopan kupon bağımsız baskı, kesik, stok ve ıslaklık maskesi taşır. Yeni müşteri
  eski parçanın yazılarını, lekesini veya kuruma başlangıcını değiştirmez.
- Parmak izleri aynı baskının `rubs` yollarıdır. Kararı değiştirmez; yeni karar
  damgası üretmez. Aynı düz sürüklemenin devamı tek yol olarak uzar; kurumuş
  bir devam önceki yaş teması geri almaz.
- Temas sesleri fiziksel değme/ayrılma anına bağlıdır. Q, duraklatma veya yeniden
  başlatma eski aktarımı, dolumu ve geç kalmış işaretlemeyi sürdürmez.

## Sınırlar

Keçe ve el hareketleri kontrollü prosedürel modellerdir. Bu dilim bitmiş AAA
el animasyonu, gerçek cihazda dinlenmiş ASMR kaydı veya hedef GPU performansı
iddiası değildir. Damga alt yüzü küçük kabartma ve yüzey normal maskesi kullanır;
her harf ayrı bir yüksek poligonlu model değildir.

Ped ortak nötr keçe kullanır; damgaların kendi boya renkleri korunur. Renklerin
birbirine fiziksel olarak karıştığı sıvı simülasyonu veya parmakta mürekkep
biriktirip odadaki başka eşyalara taşıma uygulanmaz. Kâğıttaki kalıcı bulaşma,
dokunulan çizgilerin yer değiştirmiş pigment izidir; tam lif/sıvı çözümü değildir.

Kayıt verisi temas zamanını ve kuruma süresini korur. Tam dünya kayıt/yüklemesi
ve eldeki alet yüklerinin kayıt dosyasından yeniden kurulması bu masa prototipinin
mevcut sınırı olmaya devam eder.

## Doğrulama ve normal oyun kaydı

Son kontroller Godot 4.7.2 ile gerçekten çalıştırıldı. 333 birim testinin 47’si
bu dilimdeki yük, keçe, temas, kalıcı iz ve kuruma davranışlarını ek olarak sınar.

| Kontrol | Sonuç |
| --- | --- |
| Import ve tür denetimi | Geçti; `/tmp/kiosk-ink-current-import.log`. Son normal kayıt betiği ayrıca `--check-only` ile geçti |
| Birim testleri | **333 geçti, 0 başarısız**; `/tmp/kiosk-ink-final-unit.log` |
| Birleşik headless odak akışı | **16 müşteri geçti**; `/tmp/kiosk-ink-verified-headless.log`. Yeni mürekkep, kupon, kimlik/C/Tab, kâğıt/ışık, inceleme, kesim ve damga birlikte; para/stok değişmedi |
| Eski tam satış sahnesi | Kesinti kontrolleri ve **8 müşteri geçti**; `/tmp/kiosk-ink-final-legacy.log` |
| Yeni temas kesintileri | Geçti; `/tmp/kiosk-ink-live-contact-regressions.log`. Temas öncesi Q/Esc/restart, basılıyken kaldırıp tekrar değme, temas sırasında duraklatma/restart, havada hareketin iz oluşturmaması, ayrı kâğıt temasları/tüketimler, yaşken oluşan parmak izinin doğal kurumadan sonra korunması |
| Normal pencerede ilk müşteri | **Geçti**; `/tmp/kiosk-ink-final-native.log`. Pedde örneklenen yük 0,750 → 0,884; aynı lastiğin Q/F incelemesi; hafif baskıda 0,188 basınç / −0,180 radyan eğim; güçlü baskıda 1,000 basınç; canlı bulaşma, doğal kuruma, kuru izde değişmeme, gerçek kesim/elle kupon dosyalama ve doğru iade. Para/stok değişmedi; 486 kaynak kare |
| Gerçek çizilmiş ıslaklık maskesi | Yaş maskede 2.527 pigment pikseli; dokunulmamış kâğıtta alfa 0. Kuruduktan sonra bütün maske alfa 0. Veri/karar değiştirmeyen GPU çıktısı üzerinden kontrol edildi |
| Pencereli birleşik odak akışı | **16 müşteri geçti**; `/tmp/kiosk-ink-final-gui.log`. 1280×800 GL Compatibility/llvmpipe, Dummy ses. Yeni temaslar ve önceki kupon/kimlik/kâğıt/masa akışları birlikte; para/stok değişmedi |

Normal kayıt 1600×1000 GL Compatibility/llvmpipe, Dummy ses ve gerçek pencere
imleciyle yapıldı. Selftest, ışın için imleç override’ı, hazır karar/kampanya,
yapay yük veya zamanı ilerleten hile kullanılmadı. Kamera yakınlaşması normal
tekerlek girdisidir; üç ters adım başlangıç mesafesine tam döndü.

Aynı kadrajın yaş/kuru görüntü karşılaştırmasında karar baskısının 12.312
pikselinden 3.495’i değişti (%28,39; en yüksek kanal farkı 10/255). Yanındaki
4.565 kâğıt pikseli ve 10.000 masa pikseli aynı kaldı. Bu, kâğıdın tamamını
parlatmadan yerel mürekkep kaplamasının kuruduğunu doğrular. Mühür üzerindeki
küçük lif boşlukları ve izler kuruma sonunda yerinde kaldı.

Bu koşular gerçek GPU performansı veya insan oyuncunun eğlence değerlendirmesi
değildir. Ses Dummy sürücüsüyle sınandı; gerçek cihazda dinleme yapılmadı.
Son birim ve işlevsel günlükler motor/GDScript hataları için ayrıca tarandı ve temiz.
Pencereli koşularda yazılım sürücüsünün V-Sync uyarısı var. Yeni ıslaklık katmanını
başka bir baskı yüzü sayan üç eski test seçicisi düzeltildi; iki gerçek basılı yüzün
korunması ve kırpma/kâğıt snapshot denetimleri eksiksiz çalıştı.

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest --ink-only
godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest
# Grafik oturumunda, normal pencere girdisiyle:
godot --rendering-method gl_compatibility --audio-driver Dummy --path . --resolution 1600x1000 --fixed-fps 30 --script res://tools/capture_ink_desk.gd -- --capture=/tmp/ink-shots
```

486 kaynak kareden üretilmiş normal oyun akışı:

![Gerçek ped, lastik inceleme, baskı ve yaş mürekkep akışı](images/ink-workflow.webp)

| Görüntü | Gösterdiği durum |
| --- | --- |
| [Pedde temas](images/ink-pad-contact.png) | Damganın aynı keçe yüzüne basması; dolum menü tıklaması değildir |
| [Yüklü lastik yüz](images/ink-loaded-rubber-die.png) | Q/F ile çevrilen aynı fiziksel alt yüzde ters yazı ve mürekkep kaplaması |
| [Eğik temas](images/ink-tilted-contact.png) | Lastiğin kaldırılmış omzu ve hafif basış |
| [Hafif ve güçlü baskı](images/ink-light-and-firm.png) | Alan dışındaki soluk iz ile karar alanındaki güçlü baskı |
| [Parmak teması](images/ink-finger-contact.png) | Boş el Alt+sürükleme, kâğıdı kaldırmadan gerçek temas |
| [Yaş bulaşma](images/ink-smeared-wet.png) | Yakın kadrajda basılı çizgilerden taşınan pigment |
| [Kurumuş iz](images/ink-dry.png) | Parlaklık kaybolur; baskı ve parmak izi kalır |
| [Kupon dosyası](images/ink-filed.png) | Aynı karne üzerinde izler korunurken kesilen parça gerçek kaba bırakılmış |

Sonraki iş 7. dilim: çalışılabilir masa düzeni ve alet yuvaları.
Müşteri davranışları ve son malzeme/ses cilası 8–9. dilimlerde kalır.
