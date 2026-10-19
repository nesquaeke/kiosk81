# Karne inceleme masası — güncel etkileşim sözleşmesi

Bağımsız uygulama görevi: [master prompt](RATION_FPS_MASTER_PROMPT.md).
Çalıştırılmış kontrollerin tarihli kaydı: [kabul raporu](RATION_FPS_ACCEPTANCE.md).
Objektif değerlendirme ve önerilen geliştirme sırası: [yol haritası](RATION_MECHANIC_ROADMAP.md).

Bu belge davranışı ve sınırları tanımlar; yeni sürümün bütün kontrolleri geçtiği
iddiası değildir. Eski rapor ve görüntüler kendi sürümlerinin kanıtıdır.

## Güncel kapsam

Kullanıcının son isteği yalnızca müşteriden karne alma, masaya koyma,
sahteciliği inceleme ve damga/kesim etkileşimini çok iyi yapmaktır.
Bu dilimde oda genişletme, erzak toplama, stok muhasebesi veya ekonomi eklenmez.
Önceki tam satış deneyi ayrı korunur; temel etkileşimin önüne geçmez.

F5 giriş sahnesi `scenes/kiosk/ration_desk_focus.tscn`;
ortak `fps_kiosk.gd` üzerinde `document_focus = true` kullanır.
`fps_kiosk.tscn` eski erzak ve satış akışını ayrı çalıştırır.
`ration_desk.tscn` eski 2D arayüz denemesidir; ana akışa geri konmaz.

Oyun dünyası 3D'dir. Müşteriye yaklaşma ve elde inceleme birinci şahıstır.
Güncel masa etkileşiminde **aynı Camera3D masanın üstüne taşınır**; oyuncu
imleçle gerçek kâğıt ve araçlarla çalışır, sağ sürüklemeyle masayı kaydırır,
tekerlekle yakınlaşır. Çıkınca kamera baş düğümüne ve önceki bakış/FOV'a döner.
Önceki “kamera gözden hiç ayrılamaz” kısıtı bu masa modu için geçerli değildir.
Bu izin, karneyi tam ekran bir Control/dashboard arayüzüne dönüştürmez.

Dönem atmosferi komünist Polonya'sıdır; meslekler, kurumlar, kotalar ve
alıkoyma kuralları kurmacadır. Meslek veya yıpranmış kâğıt suçluluk kanıtı değildir.

## Tek müşteri döngüsü

1. Pencereye yaklaş; müşteri karneyi uzatsın. E/tek tık ile aynı 3D belgeyi ele al.
2. Elde F ile yakından incele: sol sürükle döndürür, tekerlek yakınlaşır,
   sağ tık ters yüzü gösterir, R düzeltir. F/Esc/Q/WASD önceki tutuşa döner.
3. Masaya bak; fiziksel bırakma çerçevesi görünür. E/G ile yerleştirince aynı
   kamera otomatik üstten çalışma açısına geçer. Kart/geniş masa E ile yeniden açılır.
4. Ön/arka yüz, tarih, sınıf, kurum, hak ve müdahale izlerini fiziksel kaynakla karşılaştır.
5. Masada F çevirir; R ele alır. Sonrasında elde F tekrar yakından inceleyebilir.
6. Karar aracını masadan al. SATICI ONAYI / KARAR alanı basılıdır; geçici izdüşüm
   damganın gerçek konum/açısını gösterir. İlk iki müşteride kapatılabilir hedef
   çerçevesi vardır. Araç hedefin yanında bekler; basarken üstüne gelir.
7. Damgayı indir/bastır/kaldır. Alan dışı fiziksel baskı kâğıtta kalır ama karar
   kaydetmez. Gerçek mürekkep ile geçici kılavuz farklı render katmanlarındadır.
8. Satış onayında gereken kuponun sınırını gerçekten kes. Ret/alıkoymada bu adımı atla.
9. Aracı uygun boş yüzeye bırak; Q ile ayrıl. Karneyi ele alıp müşteriye iade et
   veya alıkoyma bölmesine koy. Sonraki müşteriyi çağır.

Bu modda son adım **belge incelemesinin tamamlanmasıdır**: ürün paketi gerekmez,
stok düşmez ve ödeme alınmaz. Karne hakkı ile ürün satışı aynı işlem sayılmaz.
Yanlış karar verilebilir; sonuç işlem kaydında değerlendirilir.

Konuşmayı bırakmak ret kararı değildir. Uzaklaşma müşteriyi, kartı ve bekleyen
kararı silmez. Kısa altyazı odada oyuncuyu takip etmez; talep masadaki fişten
veya müşteriyle tekrar etkileşimden okunur.

## Karşılaştırılacak kanıtlar

15 Şubat 1982, üç kurmaca sınıf:

| Sınıf | Et hakkı | Kurum |
| --- | --- | --- |
| İşçi | 750 g | F14 |
| Öğretmen | 500 g | S03 |
| Emekli | 250 g | E02 |

Her sınıfta şeker 1000 g ve sabun 1 adet. Ön yüzde ad, sınıf, seri, ay ve haklar;
arkada kurum kaydı/onayı ve müdahale izleri bulunur. Kurum mührü ile oyuncunun
bastığı işlem damgası ayrı şeylerdir. Seri denetimi/kimlik karşılaştırması ancak
ilgili ek belge veya kayıt uygulanmışsa kanıt olarak kullanılır.

| Durum | Belge kararı |
| --- | --- |
| Geçerli belge ve kullanılabilir hak | SATIŞ onayı, uygun kupon ve kart iadesi |
| Eski ay, kullanılmış kupon veya eksik onay | RET ve kart iadesi |
| Sınıf/kurum çelişkisi veya değiştirilmiş hak | ALIKOY ve belge bölmesi |
| Yıpranmış ama tutarlı belge | Tek başına ret/alıkoyma nedeni değil |

Elde/masada çevirmek görünür arka yüzü gerçekten değiştirmelidir; sadece bir
bool değişmesi yeterli değildir. İki yüzdeki kupon boşluğu ve yama aynı fiziksel
konuma karşılık gelir. Yazılar yakın incelemede okunur; eller onları örtmez.

**Bu dilimin inceleme araçları:** masada fiziksel sınıf/kurum örnekleri ve optik
büyüteç. Kaynak kartın yanına bakarak karşılaştırılabilmeli; büyüteç yalnızca
altındaki gerçek baskıyı büyütmeli, “sahte” etiketi üretmemelidir. Referans ve büyüteç sahneye bağlıdır; gerçek optik görüntü pencereli koşuda
kontrol edilmiştir. Güncel görüntüler kabul raporundadır. UV, kimlik veri
tabanı ve sınırsız belge üretimi mevcut kapsam değildir.

## Makas: kısa kesik de gerçektir

Önceki “kısa/çizgi dışı kesim bırakınca kaybolur” davranışı terk edildi.
Makas ucu fiziksel uzunluk kadar ilerler: **2 cm kesmek, kâğıtta kalan 2 cm
kesiktir**. Tuşu bırakmak, Q, duraklatmak, çevirmek ve yeniden incelemek bu
hasarı iyileştirmez. Kesik ön/arka yüz ve kâğıt kenarıyla tutarlı görünür.

Kesik ile kupon tüketimi ayrı durumdur. Bir kısa yarık bütün kuponu koparmaz.
Kuponun dört kenarı ayrılınca, damga henüz basılmamış olsa da tek 3D parça oluşur ve kartta iki yüzden de boşluk
kalır. Ayrılan parça aynı kartın ürün/miktar/seri baskısını taşır. Açık sınırın
tek seferde çizilmesi gerekmez; daha önceki kesiklere devam edilebilir.

Makasın ağız hareketi ve aralıklı sesler uç ilerlemesini destekler. Farenin
uzak noktaya gitmesi, bütün çizginin anında kesildiği anlamına gelmez. Kâğıt
üzerindeki fiziksel hasar, satış hakkının işlenmesi ve ayrılan kupon ayrı tutulur.
Hazırlanmış ürün, erzak toplamak veya karar damgası fiziksel kesimin önkoşulu
değildir. Onay ve istenen kuponun tamamen ayrılması iki sırayla da yapılabilir;
ancak ikisi tamamlanınca istenen hak işlenir. Talep dışı kuponu koparmak siparişi
karşılamaz ve işlem sonrası denetim kaydında hata gerekçesiyle görünür.

## Damga: temas ve mürekkep

6. dilimin ayrıntılı kullanım ve sınırları: [mürekkep pedi ve yaş baskı](STAMP_INK_UPDATE.md).
Gerçek ped temasında ayrı damga yükü dolar. Alt+tekerlek yana eğim seçer;
sol+sağ tutup sürükleme iki eksende temas lekesi bırakır. Boş el Alt+sürükle
yaş mürekkebe parmak temasını kâğıdı kaldırmadan işler. İzler temas sırasında
kaydedilir; kuruma önceki lekeyi silmez, kuru iz yeniden bulaşmaz.


Araç masadan fiziksel olarak alınır; imleç altında kâğıda hizalanır.
Sol tuş basılıyken aşağı fare hareketi damgayı indirir. Yaklaşma hızı, basılı
kalma süresi, basınç ve açı mürekkebin dağılımını değiştirir; yanal hareket
sürüklenme izi oluşturur. Girdiyi bırakınca damga kaldırılır.

- Temastan önce iptal: mürekkep ve temas sesi yok.
- Temas: tek kalıcı iz ve eşzamanlı baskı sesi.
- Temastan sonra bekleme/basınç: aynı izin görünümü güncellenir, yeni damgalar üretilmez.
- Kaldırma/ayrılma: iz korunur, kaldırma sesi bir kez çalar.
- Kartı çevirmek/ele almak izi, açıyı veya mürekkep dağılımını sıfırlamaz.

Baskı hissi sahtecilik cevabı değildir. Oyuncu yanlış karar aracını da kullanabilir.
Araçlar sabit, anlaşılır yerlerden alınır; bırakma başka aracı örtüp onu
seçilemez hale getirmemelidir. Araç yüzeyi, çarpışması ve tutma noktası aynı
fiziksel konuma karşılık gelir.

18 Ekim doğrudan masa/makas değişiklikleri ve hareketli kayıt: [masa düzeltmeleri](DESK_ROOM_FIXES.md).

## Kontroller

| Durum / girdi | Davranış |
| --- | --- |
| Serbest: WASD / fare / Shift | Yürü, bak, hızlı yürü |
| E, uzatılan karne | Teslim al ve masaya yerleştir |
| E, masadaki karne | Üstten masa çalışma açısına geç |
| Masada sağ tuş + sürükleme | Masanın farklı bölgesine kaydır |
| Masada tekerlek | Yaklaş/uzaklaş |
| R, masadaki karne | Bilinçli olarak ele al |
| Elde sağ tuş + fare | Belgeyi eğ; normal bakış aynı anda dönmez |
| F | Ön/arka yüzü fiziksel olarak çevir |
| E, araç / G, uygun yüzey | Aracı al / bırak |
| Damga: sol tuş + aşağı fare | İndir, bastır; bırakınca kaldır |
| Damga: Shift + tekerlek | Baskı açısını değiştir |
| Makas: sol tuş + sürükleme | Ucu ilerlet; bırakınca gerçek kesik kalır |
| Q veya masada WASD | Çalışma açısından ayrıl, yürüyüşü geri ver |
| E, müşteri / belge bölmesi | Eldeki karneyi uygun hedefe teslim et |
| Esc / odak kaybı | Kontrolleri güvenle bırak, duraklat |

Büyüteç E ile alınır; masada imleç altındaki gerçek baskıyı büyütür, G ile
bırakılır. Q ile masadan ayrılınca büyütecin render işlemi durur. Gerçekte pencere dışında kalan bir imleç koordinatı,
otomatik testte ışınla ulaşılabilse bile oyuncu erişimi sayılmaz.

## Durum, mimari ve sınırlar

- `KioskFPSPlayer`: yürüyüş, çarpışma, normal FPS bakışı.
- `fps_kiosk.gd`: ortak sahne; `document_focus` giriş/çıkış ve yalnız belge tamamlama.
- `RationCard3D` / `RationCardView`: 3D kâğıt, yüzler, baskı, iz ve boşluklar;
  Control yalnızca dünya nesnesinin baskısını üretir.
- `PaperCutGeometry` / `PaperCutMesh`: kalıcı kesik geometrisi ve ayrılma.
- `StampImpressionRenderer`: temas verisinden tutarlı mürekkep izi.
- `RationDeskRules`: karne kararları, kesikler, kupon ve tekil tamamlama.
- `Game` / `CampaignState`: yetkili durum ve atomik etkiler.
- `RationFoley`: fiziksel temaslara bağlı sesler.

Müşterinin tek kartı vardır. İşlemden çıkıp dönmek kartı yeniden yaratmaz.
Kayıt dönüşümü kesikleri ve damgaları korur; tam serbest dünya kayıt/yüklemesi
ayrıca uygulanmadıkça var sayılmaz. Yeniden başlatma eski callback'leri durdurur;
bırakılmakta olan aracın çarpışması ve elin ebeveyni de düzeltilir.

Sahne, araçlar, kâğıt ve sesler prosedürel prototip varlıklarıdır. Yakından
okunabilirlik, temas ve tutarlı kontrol hedeflenir; bitmiş AAA sanat, el IK'sı
ve gerçek cihazda dinlenmiş ASMR kalitesi iddia edilmez.

## Doğrulama ve sonra

Birim testleri kural/hasar/iz durumunu; odak sahnesinin selftest'i gerçek girdi,
masa kamerası, imleç, kesim, damga ve belge teslimini sınamalıdır. Pencereli
çalışma ayrıca gerekir. Sayılar ve PASS sonuçları yalnızca gerçekten çalıştırılan
sürüm için kabul raporuna yazılır. Eski tam satış testleri odak sahnesinin
ürünsüz döngüsünü tek başına doğrulamaz.

Daha önce kabul edilen erzak toplama, resmî/gizli kaynak seçimi, ödeme ve ürün
getirme fikri korunur; bu görev bitince yeniden ele alınacak ayrı döngüdür.
Yarı açık dünya, oda genişletme, terazi, para üstü ve kampanya bu göreve eklenmez.

## Yeni dilimlerin takibi

Kullanıcının ayrıntılı, sıralı listesi [burada](CARD_INTERACTION_BACKLOG.md).
Güncel görsel kayıt ve doğrulama [elde inceleme raporunda](CARD_INSPECTION_UPDATE.md).
Elde inceleme ekranında aynı 3D nesne kullanılır; dönüş/zoom işlemi kanıtı,
kesikleri veya kararları değiştirmez. Kapatınca önceki tutuş ve kamera ayarları
aynen geri gelir. Alan derinliği yalnız Forward+ yöntemiyle kullanılabilir;
Compatibility görüntüsüne bulanıklık varmış gibi davranılmaz.

## Kâğıt malzemesi ve ışıkla inceleme

[Güncel kayıt](PAPER_INSPECTION_UPDATE.md). Üç stok 0,14 / 0,28 / 0,48 mm gerçek
yüzey mesafesiyle çizilir; kalınlık ve yıpranma mesleği/suçluluğu göstermez.
Seri ve açık stok seçimi lifleri, tonu, bükülmeyi ve aşınmayı sabit tutar.

Elde F incelemede T, arkadan simüle edilmiş geçirgen ışığı açar/kapatır.
Kâğıdın eğimi ışığın gelişini değiştirir. Filigran ön/arka yüzde aynı fiziksel
konumdadır; arka yüzden aynalanır. Mevcut kota yamasının ek katmanı desenin
geçişini keser; büyüteç ve yana yatırma tutkal/kâğıt kenarını gösterir.
Oyuncuya doğru/sahte yazısı verilmez ve mevcut karar kuralları değiştirilmez.

Kitapçığın önünde sınıf/kota/kurum örnekleri; arkasında çizimli kâğıt, filigran,
yama ve normal aşınma karşılaştırması vardır. E ile al, Q ile masa açısından
çık, F ve sağ tıkla arka sayfayı oku. Ayrı belge paneli açılmaz.

Kopmuş kupon kendi stok, baskı, mürekkep ve kesiğinin snapshot'ını taşır;
sonraki müşteri ona yeni hasar/desen yazamaz. Kamera/ışık, Esc/Q/odak kaybı ve
yeniden başlatmada temizlenir. Fotoğraf, kazınmış tarih ve ayrı kimlik eşleme
senaryoları bu dilimde eklenmedi; sıralı listedeki sonraki kanıt işleridir.
