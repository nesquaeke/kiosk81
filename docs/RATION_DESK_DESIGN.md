# FPS karne etkileşimi — ana mekanik ve ortak geliştirme belgesi

Bağımsız uygulama görevi: [FPS master prompt](RATION_FPS_MASTER_PROMPT.md).
Doğrulama ve güncel görüntüler: [Kabul raporu](RATION_FPS_ACCEPTANCE.md).
Bu belge uygulanan dilimi kaydeder; master prompt hedefi ve kabul ölçütlerini tanımlar.

## Değişmez temel

KIOSK '81 üç boyutlu, birinci şahıs, ileride yarı açık dünya olacak bir oyundur.
Oyuncu karakter olarak yürür; bütün işlemler karakterin gözünden görülür.
Karne, araçlar, ürünler ve defterler dünyadaki fiziksel nesnelerdir.

Kullanıcı önceki 2D masa arayüzünü açıkça reddetti. Karne için ayrı bir ekrana
geçmek, sabit masa ekranı açmak veya düğmelerle araç seçmek doğru temel
değildir. Bu belge eski 2D tasarımın yerine geçer. Eski sahne yalnızca arşiv
referansıdır; giriş sahnesi ve oyuncu akışı FPS'tir.

Tarihsel atmosfer korunur; meslek kartları, miktarlar, kurumlar ve alıkoyma
kuralları oyun için tasarlanmıştır. Bunlar gerçek 1982 mevzuatı değildir.
Kurmaca tedarik noktasındaki et satışı gerçek Ruch kioskları için bir iddia
değildir. Meslek kişinin dürüstlüğünü belirlemez.

## Temel sorular

Bu belge gerçek mi? Müşteri ne alabilir? Hangi ürünü hangi stoktan vereceğim?
Kartı iade mi edeceğim, alıkoyacak mıyım?

Belge gerçekliği, hak miktarı, tedarik ve ödeme ayrı konulardır. Karne
ücretsiz mal veren ödeme aracı veya stok garantisi değildir.

## Fiziksel döngü

Odada yürüyerek cama gel → müşteri karneyi uzatır → E ile al ve kısa
hareketle masaya bırak → masadaki karta E ile etkileşip aynı göz kamerasıyla
eğil → masada incele veya R ile bilinçli olarak eline al → eğ/çevir ve tekrar
masaya bırak → kural defteriyle karşılaştır → karar damgasını alıp kâğıda bas →
makası al, uygun kuponu kes → aracı bırak → Q veya yürüyüşle masadan ayrıl →
doğru raftan ürünü al → tezgâha taşı/bırak → müşteriye uzat → kalan karneyi
R ile alıp iade et veya alıkoyma bölmesine koy → zille sonraki müşteriyi çağır.

Kamera hiçbir aşamada karakterin gözünden ayrılmaz. Masaya yaklaşmak UI
açmaz. Yazılar 3D kâğıdın yüzeyindedir. Elde incelemede fare nesneyi döndürür;
karakterin bakış yönü korunur. Elde nesneyle odada yürünebilir.

## Uygulanan ilk FPS dilimi

- Oda, servis penceresi, dışarıdaki müşteri, çalışma masası, koliler,
  kayıt dışı stok ve kapı açıklığı bulunan 3D blok sahne.
- WASD, hızlı yürüyüş, duvar/zemin/tezgâh çarpışması ve yakın erişim.
- Sol elde karne; sağ elde makas, damga, defter veya ürün. Eller ve araçlar
  basit modellerdir; nihai rig/IK veya sanat varlıkları değildir.
- Müşteriden alınan kart kameraya bağlanmadan dünya uzayında masaya yerleşir;
  masadaki karta E ile eğilinir, R ile bilinçli olarak ele alınır.
- Q veya yürüyüş eğilme pozundan çıkar. Karne masada ve işlem korunur.
  Q yarım kesimi ve basılı inceleme durumunu da temizler.
- Konuşma kısa süreli ve yakın bakışta görünür; E ile tekrar dinlenebilir.
  Talep fişi masada fiziksel olarak okunabilir.
- Ön/arka yüz, eğme, çevirme ve yakınlaştırma. Masadaki çevirme, kâğıdı
  masa yüzeyinden kaldırıp gerçek arka yüzü açar; quaternion bileşimi kullanılır. Kesilen kupon iki yüzde de
  gerçek bir boşluk bırakır; kâğıdın arkasında sağlam kupon görünmez.
- Fiziksel SATIŞ, RET, ALIKOY damgaları; yaklaşma/basma/kaldırma ve temas
  anında iz/ses. Temastan önce Q/yürüme/Esc iptalinde iz oluşmaz; temastan
  sonra iptal mevcut izi korur ve aracı ele geri verir.
- Kesimde bakış çizgi boyunca ilerler; makas ağızları hareket eder.
  Kısa veya çizgi dışı kesim kupon tüketmez.
- Ayrılan parça aynı belgenin ürün, miktar ve seri baskısını iki yüzünde taşır;
  3D kupon kutusuna gider; temas sesi çalar.
- Et kâğıt/sicim paketi, şeker katlı torba, sabun kılıflı bar olarak gösterilir.
  Ürün açık ahşap koliden alınır, yüzeye bırakılır ve müşteriye hareketle uzatılır.
  Her birinin ayrı alma/bırakma foley olayı vardır.
- Gün sonu kararları dünyadaki deftere yazılır; elde okunur.
- Hedef ipucu, konuşma altyazısı ve Esc menüsü dışında belge dashboard'u yok.

Bu dilim temel FPS ve karne etkileşimidir. Büyük yarı açık dünya haritası,
tam vücut/IK, serbest tartım, para üstü ve kampanya devamlılığı henüz yoktur.

## Kurmaca kart kuralları

15 Şubat 1982; üç sınıf, sekiz hazırlanmış karşılaşma:

| Sınıf | Et hakkı | Kurum |
| --- | --- | --- |
| İşçi | 750 g | F14 |
| Öğretmen | 500 g | S03 |
| Emekli | 250 g | E02 |

Her sınıfta şeker 1000 g, sabun 1 adet. Ön yüzde ad/sınıf/seri/ay/haklar;
arkada kurum kodu, onay mührü ve müdahale izleri bulunur. Çift yüz kupon
kayıtları, baskı deseni, lif, kat izi, kenar aşınması ve damgada sabit mürekkep
aşınması kâğıdın üstündedir. Yama iki yüzde aynı fiziksel konuma hizalanır.

| Durum | Karar |
| --- | --- |
| Geçerli kart, kupon ve stok | SATIŞ; ürün, kesim ve kart teslimi |
| Eski ay, kullanılmış kupon, eksik onay | RET ve kartı iade |
| Sınıf/kurum çelişkisi veya değişmiş hak | ALIKOY ve belge bölmesine koy |
| Geçerli kart, resmî stok yok | Ret veya kayıt dışı tedarik |
| Yanlış onay / alıkoyma | Gün sonu hata ve denetim riski |

Yıpranma sahtecilik değildir. Sistem önceden doğru/yanlış etiketi göstermez.
Oyuncu yanlış karar verebilir; sonuç gün sonu defterinde görünür.
Kurum mührü ve satıcının işlem damgası farklı işlevler taşır.

Karşılaşmalar: geçerli işçi, yıpranmış öğretmen, eski ay, yanlış kurum,
kullanılmış kupon, değiştirilmiş hak, eksik onay ve stok tükendiğinde gelen
geçerli emekli. Kayıt dışı et ayrı stoktan azalır; geliri cebe gider ve risk
doğurur. Stok gram/adet cinsinden izlenir.

## Kontroller ve işlem güvenilirliği

| Kontrol | Davranış |
| --- | --- |
| WASD / Shift | Yürü / hızlı yürü |
| E | Teslim al/masaya bırak; masadaki karneye eğil; araç/ürün al veya teslim et |
| R | Masadaki karneyi açık bir seçimle eline al |
| Q / eğilmedeyken WASD | İncelemeden ayrıl; yarım hareketi iptal et |
| G | Önce sağ eldeki nesneyi yüzeye bırak; sağ el boşsa karneyi masaya bırak |
| Sağ tuş basılı + fare | Elde tutulan kartı/defteri eğ; göz kamerası dönmez |
| F | Elde veya bakılan masada karneyi çevir |
| Tekerlek | Elde tutulan belgeyi yaklaştır/uzaklaştır |
| Sol tuş basılı → bırak | Damgayı kartın karar alanına bastır |
| Sol tuş basılı + bakış | Makasla kupon çizgisini soldan sağa izle |
| Esc | Ayar/duraklatma; tamamlanmamış kesimi iptal et |

İşlem için karne masada ve ön yüz yukarıda olmalıdır. Kupon, ürün hazırlanmadan
da kesilebilir; satış kararı, doğru kullanılabilir kupon, yeterli hak ve iki
stoktan en az birinde yeterli miktar gerekir. Fiziksel raf etkileşimi belge
işlemlerinin bitmesini bekler; kaynak raf seçimiyle belirlenir. Satışı tamamlamak
için ürün müşteriye uzatılmış ve kalan
kart elde olmalıdır. Tekrarlanan teslimat çift stok/para değişimi yaratmaz.
Aynı sipariş için ikinci paket hazırlanamaz; mevcut paket geri alınır.
Ürün müşteriye uzatıldıktan sonra karar RET/ALIKOY'a çevrilemez; satış kalan
kart iade edilerek tamamlanır. Böylece verilmiş ürün hesaptan kaybolmaz.
Kesilmiş kupon, kart alınca veya çevrilince geri gelmez.

İlk dilimde paketler istenen miktara göre hazır gelir. Terazi ve serbest
gramaj sonraki adımdır. Kesilen parça kutuya otomatik aktarılır; elle parça
toplama ve serbest kesim gelecekte değerlendirilebilir.

## Dokunsal ve ASMR sözleşmesi

| Eylem | Görsel temas | Ses |
| --- | --- | --- |
| Alma | Kâğıt göz kamerasının önündeki ele gelir | Kısa kâğıt sürtünmesi |
| Çevirme | Gerçek 3D yüz döner | Kâğıt bükülmesi |
| Bırakma | Kâğıt/nesne yüzeyde kalır | Yumuşak masa teması |
| Damga | Araç hedefe iner, bastırır ve kalkar | Tok temas ve ayrı kaldırma |
| Kesme | Makas çizgide ilerler, ağızlar kapanır | Aralıklı kesme/metal |
| Kupon düşüşü | Ayrı 3D parça kutuya iner | Kâğıt düşüşü |
| İade/alıkoyma | Kâğıt müşteriye veya bölmeye gider | Kâğıt/çekmece |

Başarı/hata jingle'ı temas sesini örtmez. Ses seviyesi Esc menüsünde ayarlanır.
Sesler özgün prosedürel prototiplerdir; gerçek yakın mikrofonlu kayıtlar ve
kullanıcı dinlemesi kalite yol haritasındadır. ASMR kalitesi bitmiş sayılmaz.

## Mimari ve kalıcılık

- KioskFPSPlayer: hareket, baş/göz kamerası, çarpışma.
- fps_kiosk.gd: oda, müşteri, araçlar, tutma ve yüzey işlemleri.
- RationCard3D: çift yüz, kupon boşlukları ve yüzey koordinatları.
- RationCardView: yalnızca kâğıdın yazı/görselini üretir; FPS'te ekran olarak açılmaz.
- RationDeskRules: karar/gramaj; hand/table/customer yerleşimleri ve ürün teslim aşaması.
- Game: stok, para, kupon ve kayıtları atomik değiştirir.
- RationParcel3D: tek aktif paket, ürün ambalajı, fiziksel baskı ve tutuş.
- RationFoley: temas sesleri. content/ration/: müşteri/kart verisi.

Mantıksal yerleşim, kuponlar, damgalar ve teslim aşaması JSON kopyasında
korunur. İlk FPS dilimi ayrı demo günü başlatır; serbest dünya nesnelerinin
tam konum/rotasyon kayıtları ve yükleme menüsü henüz yoktur.

## Doğrulama

186 birim testi içinde karne testleri sınıf/kurum, miktar, kayıt dışı stok, iki kez kesme/teslim,
fiziksel yerleşim ve JSON dönüşümünü sınar. Gerçek baz yönleri, arka yüz kupon
hizası ve üç ambalajın collider/etiket/yeniden kullanım özellikleri ayrıca sınanır.
`tests/fps_ration_regressions.gd` duvar engeli, teslim sırasında yürüme, eğilmeden
çıkış, gerçek masada arka yüz, odak kaybı, damga/kesim iptali ve nesne bırakırken
yeniden başlatmayı gerçek girdilerle kontrol eder. FPS selftest'i gerçek WASD ile
hareket/tezgâh çarpışması ve erişimi, sonra gerçek E/G/F/fare girdisiyle
müşteriden masaya teslim alma, masaya eğilme/yürüyerek ayrılma, açık çıkış,
kamera sabitken elde eğme, 3D yüz çevirme, masaya bırakma,
araç alma/bırakma, temas, kısa/tam kesim, belge işlemlerinden sonra ürün
toplama/teslim ve sekiz müşteriyi sınar.

Hareket/çarpışma ayrı doğrulandıktan sonra işlemler için test konumları
kullanılır; sekiz müşterinin bütün yürüyüş rotalarının otomatik oynandığı
iddia edilmez. Pencereli kontrol gerekir; headless tek başına görsel kaliteyi
doğrulamaz. Sanal aygıtta Dummy ses sürücüsü kullanılır; dosyalar ve ses
tetiklemeleri kontrol edilir, gerçek aygıtta duyusal kalite iddia edilmez.

## Sonraki geliştirme

1. Kullanıcı değerlendirmesi: eldeki kart, erişim, okunabilirlik, kesim, ses.
2. El rig'i/IK, parmak kavrama, kola bağlı uzanma ve müşteri teslim animasyonu.
3. Çelişki işaretleme, konuşma ve ek belge.
4. Yeni sınıflar, aile adına alışveriş, çok ürünlü talep.
5. Terazi, serbest gramaj, para üstü.
6. Gerçek foley kayıtları.
7. Günler arası ilişkiler, denetim, ev ve yarı açık dünya rotaları.
8. Dünya nesnelerinin fiziksel kayıt/yüklemesi.

Codex, Claude ve ekip arkadaşı aynı kapsamı kullanır. Dosya sahipliği ve
kabul ölçütleri paylaşılır. Kullanıcının son talimatı eski prototip belgelerinden üstündür.

## FPS görüntüleri

![Aynı göz kamerasıyla masadaki karneye eğilme](images/fps-desk-inspection.png)

![Pencereden alınan karne elde](images/ration-front.png)
![Aynı fiziksel kartın arka yüzü](images/ration-back.png)
![Masada kesilmiş kuponun boşluğu](images/ration-cut.png)
