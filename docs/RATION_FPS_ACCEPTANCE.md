# Karne inceleme masası — doğrulama kaydı

## 18 Ekim 2026 — fiziksel kimlik ve yeni sahtecilik vakaları

[Kontroller, vaka anahtarı, normal oyun kaydı ve görüntüler](EVIDENCE_REVIEW_UPDATE.md).

- **251 birim testi geçti, 0 başarısız.** Yeni 14 kanıt testi; değiştirilen ay,
  fotoğraf mührü, kimlik adı/numarası/portresi, kupon serisi ve önceki teslimi
  denetler. Yıpranma ve soluk mürekkep suç sayılmaz; aynı görünen portreler
  farklı ham kimlik değeri yüzünden gizlice suç sayılmaz.
- Headless odak koşusunda **16 müşteri** tamamlandı; para/stok değişmedi.
  Güncel fiziksel kimlik/F/C/Tab kontrolü; iki belgenin yüz/zoom hafızası,
  önceki tutuşa tam dönüş, Q/WASD/odak/restart temizliği, eski teslim tween'inin
  yeniden canlanmaması ve eldeki kimliğin ışınlanmadan geri verilmesini sınadı.
- **Normal oyun penceresinde sekiz yeni vaka doğru tamamlandı.** Selftest ve
  fare override olmadan E/F/C/Tab, gerçek imleçle damga, kupon çevresini kesme
  ve iade/alıkoyma geçti. 109 kareden hareketli WebP üretildi.
- Bu pencere kontrolü, damga saplarının boş geri bırakma noktasını perdelediğini
  yakaladı. Aralık 19 cm oldu; bütün damgalar için gerçek fizik ışınıyla alıp
  yerine bırakma kontrolü eklendi. Kimliğin ilk kadrajda dört köşesi de sınanır.
- Eski tam satış sahnesinin güncel headless kesinti kontrolleri ve **sekiz
  müşterilik** koşusu geçti; inceleme sahnesine ürün zorunluluğu eklenmedi.
- Grafik kontrolleri 1600×1000, GL Compatibility/llvmpipe ve Dummy sesle yapıldı.
  Son normal koşuda motor/GDScript hatası yok; V-Sync sürücü uyarısı var.
  İnsan oyuncu eğlence testi, gerçek sesle dinleme ve hedef GPU performansı
  otomatik olarak doğrulanmış sayılmaz. Portre ve el modelleri prototiptir.

- **Pencereli birleşik 16 müşteri koşusu da geçti.** Kimlik/C/Tab/boş damga
  yerleri ve önceki kâğıt/ışık/büyüteç/ölçülü kesim kontrolleri birlikte çalıştı.
  Son pencereli koşuda motor/GDScript hatası yok; yalnız V-Sync uyarısı var.

5–9. dilimler [sıralı listede](CARD_INTERACTION_BACKLOG.md) ayrı kalan işlerdir.

## 18 Ekim 2026 — kâğıt çeşitleri ve geçirgen ışık

[Normal oyun kaydı, kart örnekleri ve rapor](PAPER_INSPECTION_UPDATE.md).

- **237 birim testi geçti, 0 başarısız.** Üç gerçek kalınlık, stok/kanıt
  bağımsızlığı, kalınlığa göre ön/arka yüz ve hedef koordinatları, kopan kuponun
  kendi mürekkep/hasar snapshot'ı ve kitapçık arkasının fiziksel yönü sınandı.
- **Headless ve pencereli odak akışları geçti:** T/açı/arka yüz, veri değiştirmeme,
  Esc/odak kaybı/restart temizliği, mevcut inceleme/masa/ölçülü kesim/damga,
  büyüteç ve sekiz müşteri. Odak akışı stok veya para değiştirmedi.
- Eski satış sahnesinin headless kesinti ve sekiz müşteri koşusu geçti.
- Son ışık ayarıyla normal pencerede (selftest ve fare override olmadan)
  kartı ele alma, F/T, serbest eğme, çevirme, çıkış, masaya bırakma ve fiziksel
  arka rehber akışı geçti. 77 kareden hareketli kayıt üretildi.
- Pencereli kontrol GL Compatibility/llvmpipe, Dummy ses ve normal imleçle
  yapıldı. Son günlüklerde GDScript/engine hatası yok; V-Sync sürücü uyarısı var.
  İnsan oyuncu eğlence testi, gerçek ses aygıtı ve hedef GPU performansı bu
  kontrollerden çıkarılamaz. Geçirgenlik bir oyun shader'ıdır, tam kâğıt fiziği değildir.
- Yeni fotoğraf/tarih/kimlik sahteciliği ve ses cilası henüz eklenmedi;
  [sıralı listede](CARD_INTERACTION_BACKLOG.md) ayrı kalan işlerdir.

## Güncel dilim — tek tuşla elde inceleme ve damga kılavuzu

[Yeni kontroller, hareketli normal pencere kaydı ve ayrıntılı rapor](CARD_INSPECTION_UPDATE.md).
[Sıralı onaylanmış liste ve kalan işler](CARD_INTERACTION_BACKLOG.md).

- **232 birim testi geçti, 0 başarısız.** Alan dışı fiziksel damga kalıcı iz
  bırakır; karar alanı dışında karar değişmez; JSON korur ve geçersiz/kâğıt dışı
  konumlar reddedilir.
- **Headless ve pencereli odak koşuları geçti.** Yeni elde inceleme girdileri,
  erken F, sınırlı zoom, serbest dönüş ve bırakınca durma, okunaklı arka yüz,
  R düzeltme, Esc/Q/odak kaybı/restart, kalıcı hasar ve masa önizlemesi sınanır.
- Hızlı Q → F geçişinde kamera ebeveyni ve FOV geri gelir. Dönen kâğıt/alet
  için mürekkep açısı ve yanal bulaşma fiziksel hareketle aynı yöndedir.
- Sekiz müşteri odak modunda tamamlandı; para/stok mutasyonu yok. Eski satış
  sahnesinin headless kesinti ve sekiz müşteri koşusu da geçti.
- Normal sahne kaydı `--selftest` olmadan geçti: E ile ele alma, F ile döndürme,
  zoom/ters yüz/Esc, bırakma çerçevesi, G ile üstten masa, gerçek viewport
  imleciyle damga izdüşümü, alan dışı ve karar alanındaki fiziksel baskı.
- Yeni grafik kontrolleri aynı display üzerinde sırayla çalıştırıldı; son
  pencereli koşuda GDScript/engine hatası yok, yazılım sürücüsünün V-Sync uyarısı var.
- GL Compatibility/llvmpipe + Dummy ses kullanıldı. Forward+ alan derinliği
  bağlandı fakat bu ortamda görsel olarak doğrulanmadı. İnsan oyuncu testi,
  gerçek cihazla ses dinleme ve hedef GPU performansı bu sonuçlara dahil değil.

Aşağıdaki bölümler önceki sürümlerin tarihli kayıtlarıdır; güncel E/F/masa
kontrolleri yukarıdaki yeni raporda tanımlanır.

## 18 Ekim 2026 — doğrudan masa ve makas düzeltmeleri

[Değişiklikler ve normal oyun penceresinden hareketli kayıt](DESK_ROOM_FIXES.md).

- 229 birim testi geçti, 0 başarısız; makasın açılışta kesmemesi ve FPS farkında
  aynı kapanış mesafesi yeni regresyonlarla kontrol edildi.
- Normal oyun penceresi kaydı geçti: `--selftest` olmadan tek tıkla üstten kamera,
  kâğıdı kaldırma/döndürme, gerçek viewport imleciyle makas ve kalıcı kesik.
- Pencereli ve headless odak koşuları geçti: doğrudan masa kontrolleri,
  damgadan önce kesim ve sekiz müşteri. Eski satış yolu headless koşusu da geçti.
- Son yerinde döndürme düzeltmesi ayrıca pencereli doğrudan masa regresyonuyla
  kontrol edildi; döndürürken kâğıdın konumunun kaymaması sınanıyor.
- Oda/karakter/el varlıkları prosedürel prototip; gerçek aygıtta ses dinleme ve
  oyuncuyla eğlence/ASMR onayı bu kontrollerin kapsamında değildir.

Aşağıdaki 17 Ekim kaydı önceki sürüme aittir.

17 Ekim 2026 · Godot 4.7.2 standard · `codex/ration-card-desk`.

F5 artık `scenes/kiosk/ration_desk_focus.tscn` sahnesini açar. Bu dilim yalnızca
müşterinin karneyi uzatması, aynı kâğıdı masaya alma, inceleme, kesim, damga ve
karneyi iade etme/alıkoyma döngüsüdür. Ürün toplama, stok tüketimi veya ödeme
gerektirmez. Önceki satış sahnesi `fps_kiosk.tscn` altında korunur.

## Kontrol edilen davranışlar

- Aynı 3D belge müşteriden masaya gelir; yürümek veya konuşmayı bırakmak onu
  ekrana yapıştırmaz. E ile aynı kamera masanın üstüne geçer; imleç, sağ sürükleme
  ve tekerlek gerçek masa üzerinde çalışır. Q/WASD önceki bakışı geri getirir.
- İki yüzlü, 0,32 mm kalınlığında, elde hafif bükülen kâğıt; 2560×1600 baskı,
  lifler, kat izi, dönem yazı tipleri, kurum mühürleri ve yükselen yama kenarı.
- Fiziksel referans, sınıf/kurum/miktar ve örnek mühür karşılaştırması sağlar.
  Gerçek dünya kamerası kullanan büyüteç, altındaki baskıyı yaklaşık 2,4 kat
  büyütür. Sahtecilik cevabı gösterilmez.
- Makas ucu metre cinsinden ilerler. 2 cm kesik bırakınca kalır; kuponun diğer
  kenarları kesilmeden tamamı kaybolmaz. Aynı yarık iki yüzde de açılır.
- Dört kenarı ayrılan kupon damgadan önce de kopar. Yanlış kuponun fiziksel
  hasarı istenen hakkı işlemez; denetim gerekçesi olarak kaydedilir.
- Onaydan önce veya sonra kesmek desteklenir. Kopan parça kendi ürün, miktar
  ve seri baskısını taşır; aynı parça ikinci kez üretilmez.
- Damga fareyle gerçekten indirilir. Temas öncesi iptal iz bırakmaz; hız,
  bekleme, basınç, açı ve yanal hareket aynı kalıcı mürekkep izini değiştirir.
  Kaldırma sesinin ve kalıcı izin zamanı temasla eşleşir.
- Geçerli/yıpranmış, eski ay, kullanılmış kupon, eksik mühür, yanlış kurum ve
  değiştirilmiş kota senaryoları bulunur. Oyuncu yanlış karar verebilir.

## Çalıştırılan kontroller

- **226 birim testi geçti, 0 başarısız.** Kural, hasar, kupon baskısı, fiziksel
  yön, JSON korunumu, mürekkep ve optik kamera regresyonları dahildir.
- **Pencereli belge regresyonu geçti:** onaysız kesim, damgadan önce fiziksel
  ayrılma, sonradan onay, tek parça ve gerçek kart teslimi.
- **Pencereli ve headless odak sahnesi geçti:** sekiz müşteri; gerçek E/G/R/F/fare girdileri,
  üstten masa, optik büyüteç, ölçülü kesim, temasla damga ve para/ürün mutasyonu
  olmadan belge tamamlama. Sekiz karar da beklenen denetim sonucunu verdi.
- Önceki satış sahnesinin headless kesinti regresyonları ve sekiz müşterilik
  tam satış koşusu geçti. Pencereli regresyon/satış koşusu da geçti.
- Görüntülerde araç kadrajı, elde/masada ön ve arka yüz, kuponun doğru baskısı,
  kalıcı kısa yarık ve büyüteçte gerçek kota rakamları incelendi.

Pencereli koşular 1600×1000 GL Compatibility, llvmpipe ve Dummy ses sürücüsüyle
yapıldı. Bu, gerçek ses aygıtında dinleme veya insan oyuncuyla eğlence/ASMR
onayı değildir. Tam gövde IK'sı, taranmış karakter modelleri ve hedef ekran
kartında performans ölçümü uygulanmış sayılmaz.

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest --capture=/tmp/ration-shots
godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest
```

`godot` 4.7.2 olmalıdır; buluttaki kesin yol AGENTS.md içindedir.
Tekrarlanan etkileşimlerde fixture başlangıç konumları kullanılır; tüm NPC
rotalarının yüründüğü veya insan kullanılabilirlik testi yapıldığı iddia edilmez.
Testte pencere dışındaki hedefe doğrudan ışın atılmaz; kamera önce hedefe kaydırılır.

## Oyun içi görüntüler

![Karne, kurum örnekleri ve erişilebilir fiziksel araçlar](images/ration-focus-workbench.png)
![Gerçek kâğıttaki değiştirilmiş kota büyüteçle incelenirken](images/ration-focus-loupe.png)
![Bırakılmış 2 cm kesik — yakın masa görünümü](images/ration-focus-two-cm.png)
![Aynı kesiğin fiziksel arka yüzü](images/ration-focus-reverse-cut.png)
![Kopmuş kuponun kendi ürün/miktar/seri baskısı ve kalan damgalı belge](images/ration-focus-detached.png)

## Uygulama sınırı

Bu, geliştirilebilir bir fiziksel etkileşim prototipidir. Genel kumaş/yırtılma
simülasyonu yoktur: serbest yarıklar kalır, ayrılabilen parçalar üç basılı kupondur.
Dünya transformlarının tam kayıt/yüklemesi, çok ürünlü sipariş, ekonomi ve yarı açık
dünya ayrı işlerdir. Prosedürel eller/oda/karakterler bitmiş AAA sanat üretimi değildir.
