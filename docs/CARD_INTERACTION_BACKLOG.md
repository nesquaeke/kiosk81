# Kart etkileşimi — sıralı geliştirme listesi

Kullanıcının onayladığı plan aşağıda korunur. Ana sahne 3D `ration_desk_focus.tscn`;
oda, erzak, ekonomi veya yarı açık dünya genişletilmez. Aynı fiziksel nesne kullanılır.
Bu liste tamamlanmış özellik iddiası değildir; gerçek sonuçlar kabul raporuna yazılır.

## Uygulama dilimleri

| Sıra | Kapsam | Durum |
| --- | --- | --- |
| 1 | E ile ele alma; F ile elde inceleme; sol sürükle döndürme; sağ tık çevirme; R düzeltme; zoom; F/Esc/Q/hareketle çıkış; bırakma önizlemesi; üstten masa | Uygulandı; otomatik ve pencereli kontroller geçti |
| 2 | Basılı satıcı alanı; gerçek ölçü/açıda geçici damga izi; ilk iki müşteride kapatılabilir hedef yardımı; hedefi örtmeyen alet; alan dışı kalıcı mürekkep | Uygulandı; otomatik ve pencereli kontroller geçti |
| 3 | Kâğıt aileleri, kalınlık, baskı/eskime çeşitleri, filigran ve lif ayrıntıları | Uygulandı; 237 birim testi, headless ve pencereli kontroller geçti |
| 4 | Kademeli sahtecilik ipuçları ve karşılaştırma; otomatik suçluluk cevabı yok | Sekiz yeni kanıt vakası, ayrı fiziksel kimlik, yüz/zoom hatırlayan C karşılaştırması ve Tab rehberi eklendi. 251 birim testi, headless/pencereli 16 müşteri ve normal pencerede yeni sekiz vaka geçti; NPC görünüşü/soruları 8. dilimde kalıyor |
| 5 | Kontrollü kesim hissi, bıçak ve el animasyonu, kupon toplama | Uygulandı: kontrollü açılma/dönüş, Shift ince kesim, geçici rehber, fiziksel kupon/E-F inceleme ve temasla dosyalama. 286 birim testi, headless/pencereli 16 müşteri ve normal imleç akışı geçti; prosedürel el/alet sanatı prototip |
| 6 | Damga basıncı/açısı, yaş mürekkep ve ped kullanımı | Uygulandı: ayrı yük, gerçek ped teması, eğimli lastik, Q/F alt yüz, yerel kuruma ve canlı parmak bulaşması. 333 birim testi, headless/pencereli 16 müşteri ve normal imleçle müşteri geçti; el/ses sanatı prototip |
| 7 | Masa düzeni, yuvalar, otomatik yerleştirme ve alet geri koyma | Bekliyor |
| 8 | Müşteri teslim animasyonu, sorular, tepkiler ve anlaşılır işlem sonuçları | Bekliyor |
| 9 | Malzemeye bağlı ses ve son temas/ışık cilası | Bekliyor; gerçek cihazla dinleme gerekir |

Eldeki F artık incelemeyi açar. Masadaki F, önceki gibi kâğıdı çevirir.
Eski `fps_kiosk.tscn` satış deneyi eski kontrollerini korur.
Yeni kullanıcı akışı: **E al → F incele → F geri → masaya bakıp E/G bırak →
üstten çalış → R ele al → E iade/alıkoy.**

İnceleme nesnenin görsel duruşunu geçici değiştirir; kapatınca önceki tutuşa döner.
Kesik, iz, hak, seri veya müşteri durumu değişmez. Forward+ render yönteminde
arka plan için alan derinliği kullanılır; Compatibility yönteminde bu efekt yoktur.

## Kâğıt ve kanıt dilimi

Üç stok 0,14 / 0,28 / 0,48 mm gerçek yüzey kalınlığı, farklı lif/bükülme ve
yıpranma kullanır. Stok meslek veya sahtelik cevabı değildir. Elde F incelemede
T ışığı açar/kapatır; eğmek ışığın gelişini ve filigranı değiştirir. Sağ tıkta
aynı desen arka yüzde aynalanır. Kota yamasındaki ek katman deseni örter.
Referans kitapçığını E ile al, masa açısından Q ile ayrıl, F ve sağ tıkla
arkadaki resimli inceleme rehberini oku. Eski karşılaştırma sayfası ön yüzde kalır.

[Kâğıt diliminin kaydı ve sınırları](PAPER_INSPECTION_UPDATE.md).
Yeni kanıt dilimi artık kazınmış ayın alt baskısını, fotoğraf üzerindeki kesintili
mührü, ad/numara/fotoğraf kimlik eşleştirmesini, farklı seri taşıyan kuponu ve
önceki teslim izini içerir. Önceki sekiz müşteri korunur; yalnız odak sahnesinde
sekiz yeni müşteri eklenerek sıra 16 olur. Eski tam satış sahnesi sekiz müşteride kalır.

Ek kimlik ayrı bir 3D belgedir; masadan E ile alınır ve F ile incelenir.
Karneyle kimlik birlikte eldeyken F incelemesinde C diğer belgeyi gösterir.
Kural kitapçığı F incelemesindeyken Tab iki resimli kanıt sayfası arasında geçer.
Bu araçlar otomatik doğruluk rengi veya suçluluk cevabı göstermez. Yıpranmış,
aynı ayı yeniden yazılmış ve soluk mühürlü geçerli örnek de vardır.

[Kanıt diliminin kullanım rehberi, vaka anahtarı ve güncel test durumu](EVIDENCE_REVIEW_UPDATE.md).
Yeni kanıtların pencereli okunabilirlik ve C/Tab akış kontrolleri geçti.
[5. dilimdeki kontrollü makas ve elle kupon toplama](COUPON_CUTTING_UPDATE.md)
da uygulandı: parça otomatik kutuya gitmez; E ile alınır, F ile incelenir,
kaba E/G ile konur. Yalnız temas dosyalama sayılır. [6. dilimdeki mürekkep pedi ve yaş baskı](STAMP_INK_UPDATE.md) da uygulandı.
Sonraki iş 7. dilimde masa düzeni; müşteri tepkileri ve ses dilimleri bekliyor.

## Onaylanan ayrıntılı plan


### 1. Önce kartla etkileşimi rahatlatmak

Kartı almak ve incelemek iki basit hareket olmalı:
1. Müşterinin uzattığı karta bakıp E basarsın; kart eline gelir.
2. Elindeyken F basarsın; Resident Evil tarzı inceleme açılır.
İnceleme sırasında kart ekranın merkezinde, gerçek bir nesne olarak görünür. Arka plandaki oda hafif bulanıklaşır; kartın kâğıdı, kıvrımları ve gölgeleri okunaklı kalır.

| Kontrol | İşlev |
| --- | --- |
| Sol tuşu basılı tutup sürükleme | Kartı serbestçe döndürme |
| Fare tekerleği | Yakınlaştırma / uzaklaştırma |
| Sağ tık | Kartı ön veya arka yüzüne çevirme |
| R | Duruşunu düzeltme |
| F veya Esc | İncelemeyi kapatma |



Burada en önemli ayrıntılar:
- Küçücük bir noktaya nişan almak gerekmemeli. Kartın tamamı etkileşim alanı olmalı.
- Döndürme hareketi yumuşak olmalı ama fareyi bırakınca kart kaymaya devam etmemeli.
- Yakınlaştırma kartı kameranın içine sokmamalı.
- Ön ve arka yüz için rahat okunabilen dönüş konumları bulunmalı.
- İncelemeden çıkınca kart önceki yerine dönmeli.
- Elindeki kartı masaya bırakmak için masada geniş bir yerleştirme önizlemesi çıkmalı.
- Her durumda tek tuşla geri çıkılabilmeli; konuşma veya kart ekranı oyuncuyu kilitlememeli.
Masadaki karta E basmak ise doğrudan masa incelemesini açmalı: kamera tezgâhın üstüne geçer, imleç görünür, kart ve aletler erişilebilir olur. Elde inceleme ile masa çalışması aynı şey olmamalı; ilki bakmak, ikincisi işlem yapmak için kullanılmalı.

### 2. Damganın nereye basılacağını anlaşılır yapmak

Şu an damga alanı belli değilse oyuncunun hatasıyla arayüzün hatası birbirine karışıyor. Bunu üç katmanda çözmeliyiz.
Kartın üzerinde basılı bir alan:
- “Satıcı onayı” gibi dönem havasına uygun bir başlık.
- Soluk çerçeve veya kesik çizgi.
- İçinde çok hafif bir mühür örneği.
- Ret, onay ve teslim işlemleri için anlamlı yerleşim.
Damgayı eline alınca fiziksel önizleme:
- Damganın altındaki gerçek baskı şekli kâğıda düşen soluk bir izdüşüm olarak görünür.
- Damga döndükçe izdüşüm de döner.
- Kartın dışına taşıyorsa taşan bölüm açıkça anlaşılır.
- Damga gövdesi hedefi tamamen kapatmaz; yaklaşırken görüş açısı korunur.
Öğrenme desteği:
- İlk müşterilerde ilgili alan hafifçe vurgulanır.
- Oyuncu alışınca yardım azaltılabilir.
- Her doğru hareketi yeşile boyamak yerine basılı tasarım ve fiziksel hizalama oyuncuya yol gösterir.
Yanlış yere basılan damga kâğıtta kalabilir. Ancak sistem, oyuncu daha basmadan ne yapacağını anlaşılır göstermeli.

### 3. Kartı bakmaya değer bir nesne yapmak

Kartı yalnızca daha yüksek çözünürlüklü bir görselle değiştirmek yetmez. Yakından incelemenin bilgi vermesi gerekir.
Kâğıt özellikleri:
- İnce ve kalın kart çeşitleri.
- Aşınmış kenarlar, ezilmiş köşeler, kat izleri.
- Ön ve arka baskının hafif hizasızlığı.
- Işığa tutulunca görülen lifler ve filigran.
- Bazı bölgelerde yağ lekesi, nem izi veya silinmiş yazı.
- Kesilen yerde yeni açığa çıkan açık renkli kâğıt kenarı.
Baskı özellikleri:
- Matbaa baskısı, elle yazılmış bilgiler ve sonradan vurulmuş mühür birbirinden ayrılmalı.
- Mürekkep kâğıda yer yer fazla veya az işlemiş olmalı.
- Seri numarası, sınıf, geçerlilik tarihi ve kuponlar tutarlı bir tasarım dili kullanmalı.
- Kart aileleri farklı görünmeli; her kart rastgele kirletilmiş aynı şablon olmamalı.
Önemli kural: Her leke sahtecilik işareti olmamalı. Eski ve yıpranmış bir kart tamamen geçerli olabilir.

### 4. İncelemeyi gerçek bir dedektiflik işine dönüştürmek

Oyuncu yalnızca tarih okuyup onay vermemeli. Küçük bir şüpheden hareketle karar verebilmeli.

| Şüphe | Oyuncunun yapacağı inceleme |
| --- | --- |
| Fotoğraf değiştirilmiş olabilir | Kartı eğip fotoğrafın üzerinden geçen mührü kontrol eder |
| Kupon yeniden yapıştırılmış olabilir | Kenara yakınlaştırır, kesik ve lif sürekliliğine bakar |
| Tarih değiştirilmiş olabilir | Büyüteçle kazınmış kâğıdı ve farklı mürekkebi inceler |
| Yanlış kart sınıfı kullanılmış olabilir | Masadaki kısa referans kartıyla karşılaştırır |
| Aynı kupon daha önce kullanılmış olabilir | Eski damga, kesik veya kayıt izini kontrol eder |
| Kart başka birine ait olabilir | Karttaki bilgileri müşterinin görünüşü ve açıklamasıyla karşılaştırır |



Bunlar aşama aşama gelmeli. İlk gün oyuncuya altı ayrı sahtecilik türü yüklememeliyiz.
Ayrıca kanıt ile karar ayrılmalı: büyüteç bir noktayı otomatik “SAHTE” diye işaretlememeli. Oyuncu gördüğünü yorumlamalı.

### 5. Makası küçük bir beceri mekaniğine dönüştürmek

Kesmek hem anlaşılır hem dokunsal olmalı.
- Makas seçildiğinde kesilecek kuponun sınırları okunaklılaşır.
- Kâğıdın kenarına yaklaşınca makasın alt bıçağı gerçekten kâğıdın altına girer.
- Sol tuşla bıçaklar kapanır; yalnızca kapanırken kesim oluşur.
- Küçük kapanış küçük kesik, tam kapanış daha uzun kesik üretir.
- Oyuncu yön değiştirirken makası yeniden açıp konumlandırır.
- Yarım bırakılan kesik kalır; kaldığı yerden sürdürülebilir.
- Kupon son bağlantısından ayrılınca bağımsız bir nesne olur.
- Kesilen parça masaya düşer, alınabilir ve kupon kabına atılabilir.
- Kartın arkasına bakıldığında aynı fiziksel kesik görülür.
İlk sürümde kontrollü kupon kesimi daha doğru olur: hafif yönlendirme, geniş tolerans ve tutarlı sonuç. Serbest biçimde bütün kâğıdı parçalama sistemini daha sonra değerlendirebiliriz.

### 6. Damgayı basit tıklamadan fiziksel bir harekete çevirmek

Damga kullanımı üç aşamalı olmalı: hizala → bastır → kaldır.
- Hafif basınca eksik veya soluk baskı.
- Dengeli basınca okunaklı baskı.
- Eğik basınca bir tarafı koyu, diğer tarafı eksik iz.
- Basılıyken sürüklemeye çalışınca bulaşma.
- Yeni basılmış mürekkebin kısa süreli hafif parlaklığı.
- Üst üste basılan mühürlerin birbirine karışması.
- Mürekkep pedine dokunmanın görünür ve duyulur karşılığı.
Bunun eğlenceli kalması için oyuncu her müşteride ped yenilemek zorunda kalmamalı. Mürekkep bakımı seyrek, anlaşılır ve kısa bir hareket olmalı.

### 7. Masayı çalışılabilir bir alan yapmak

Masada rastgele duran aletler yerine okunaklı bir düzen gerekli:
- Ortada kart için geniş çalışma alanı.
- Bir tarafta bekleyen belgeler.
- Ayrı bir yerde tamamlanan kartlar.
- Kesilmiş kuponlar için küçük kap.
- Damgalar için birbirinden ayırt edilebilir yuvalar.
- Makas, büyüteç ve referans kitapçığı için sabit yerler.
- Kartın üstünü aydınlatan yönlendirilebilir masa lambası.
Oyuncu eşyaları küçük ölçüde düzenleyebilmeli. Ancak yanlışlıkla bir damgayı odanın öbür ucuna fırlatmak veya kartı masanın içine sokmak günlük oynanışın parçası olmamalı.
Ek rahatlıklar:
- Alet bırakırken hafif yerleşme yardımı.
- Kartların üst üste binmesini azaltan konumlandırma.
- Kullanılan aleti yerine koymak için tek tuş.
- Masa modunda ekran kenarlarında anlaşılır erişim.
- Yazılar için isteğe bağlı okunabilirlik desteği.

### 8. Müşterinin de bu işlemin parçası olması

Kartı incelemek boş bir odada bulmaca çözmek gibi hissettirmemeli.
- Müşteri kartı gerçekten uzatır; sen alınca elini çeker.
- Kart masadayken müşterinin varlığı pencerenin arkasında sürer.
- Uzun incelemede bakışı ve duruşu değişebilir.
- Şüpheli bir bölge bulunca kısa bir soru sorabilirsin.
- Bazı cevaplar açıklayıcı, bazıları kaçamak olabilir.
- Kartı geri verirken müşteri uzanıp alır.
- El koyarken ayrı ve açık bir hareket gerekir; yanlışlıkla geri verme veya el koyma olmamalı.
İlk prototipte uzun diyaloglar gerekmiyor. Üç iyi müşteri; sorunsuz, yıpranmış ama geçerli ve belirgin şekilde değiştirilmiş kart, sistemi değerlendirmek için yeterli.

### 9. ASMR hissini oluşturan küçük ayrıntılar

Bunlar temel kontroller çalıştıktan sonra değer kazanır:
- Kâğıdı kaldırırken kısa sürtünme sesi.
- Kalın ve ince kâğıdın farklı sesi.
- Kartı çevirirken hafif esneme.
- Makasta açılma, metal sürtünmesi ve kesme seslerinin ayrılması.
- Damganın masaya temasıyla kâğıda teması arasında fark.
- Kuponun koparken son liflerinin ayrılma sesi.
- Kesilmiş parçanın masaya hafifçe konması.
- El ve nesne hareketlerinde küçük, kontrollü gecikmeler.
- Masa lambasında kâğıdın dokusunu gösteren yan ışık.
Ekranı sürekli sallamak veya her harekette büyük animasyon oynatmak bu hissi bozabilir. Etki kısa ve hassas olmalı.

## Yapım sırası


### 1. Etkileşimi düzeltme

- Tek tuşla alma.
- Tek tuşla elde inceleme.
- Döndürme, zoom ve arka yüz.
- Masaya rahat yerleştirme.
- Masaya bakınca güvenilir şekilde üst kamera.
- Her durumdan sorunsuz çıkış.
Tamamlanma ölçütü: Yeni oyuncu açıklama almadan kartı alıp inceleyebiliyor, masaya koyabiliyor ve tekrar yürümeye dönebiliyor.

### 2. Kart ve damga okunaklılığı

- Tutarlı kart tasarımı.
- Açık damga alanı.
- Baskı önizlemesi.
- Okunaklı yazı ve zoom.
- Ön/arka yüzün tutarlılığı.
Tamamlanma ölçütü: Oyuncu nereye damga basacağını ve hangi bilgiyi kontrol edeceğini tahmin etmek zorunda kalmıyor.

### 3. Fiziksel işlem kalitesi

- Makasın kâğıtla hizalanması.
- Kısmi kesik ve kalıcı kesim.
- Ayrılan kupon.
- Basınca ve açıya tepki veren mühür.
- İlgili el animasyonları ve sesler.
Tamamlanma ölçütü: Ekranda görünen hareket ile oluşan sonuç birebir uyuşuyor.

### 4. İlk gerçek oyun döngüsü

- Üç müşteri ve üç dikkatle hazırlanmış kart.
- Birkaç öğrenilebilir sahtecilik işareti.
- Onay, ret ve el koyma.
- Doğru işlemi tamamlayıp kartı teslim etme.
- Oyuncuya kararının neden doğru veya yanlış olduğunu açıklayan gün sonu değerlendirmesi.
Tamamlanma ölçütü: Oyuncu yalnızca aletlerle oynamıyor; gözlem yapıp anlamlı karar veriyor.

### 5. Atmosfer ve çeşitlilik

- Daha fazla kart ailesi.
- Kâğıt ve baskı çeşitleri.
- Müşteri tepkileri.
- Masa düzenleme.
- Daha zengin ses ve ışık.
