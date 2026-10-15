# KIOSK '81 — FPS karne, masa ve erzak döngüsü: master prompt

Bu belgenin tamamı Claude, Codex veya projeye katılan bir geliştiriciye görev
olarak verilebilir. Kullanıcının son talimatı bu belgeden üstündür. Bu belge
hedefi tanımlar; bir özelliğin burada yazması, oyunda tamamlandığı anlamına gelmez.
Uygulanan dilimin güncel durumu README ve `RATION_DESK_DESIGN.md` içinde tutulur.

Bu çekirdeğin uygulama ve doğrulama kaydı: [Kabul raporu](RATION_FPS_ACCEPTANCE.md).
Aşağıdaki onay kutuları yeni uygulamalar için görev şablonudur.

## 1. Görevin

Godot ile geliştirilen KIOSK '81 oyununda ana mekanik olan karne etkileşimini
çok iyi çalışan, fiziksel ve dokunsal bir birinci şahıs deneyimi haline getir.
Oyuncu dükkânın içindeki bir insandır: yürür, cama yaklaşır, müşterinin uzattığı
kâğıdı alır, masaya bırakır, eğilerek inceler, elinde çevirir, damga basar,
kupon keser; sonra odadaki erzakları bulur, taşır ve tezgâhta teslim eder.

İlk öncelik görsel modelleme değil; hareket, kontrol, okunabilirlik, işlem
mantığı, etkileşim hissi ve baştan sona oynanabilir döngüdür. AAA oyunlarındaki
kontrol tutarlılığını, temas hissini ve özeni hedefle. Basit modellerle çalışan
prototipi bitmiş AAA üretimi olarak sunma. Kaliteyi sıfatlarla değil, aşağıdaki
kabul senaryolarıyla kanıtla.

Proje: `https://github.com/nesquaeke/kiosk81`. Önce gerçek çalışma dizinini,
aktif dalı, `git status` çıktısını ve `AGENTS.md` dosyasını kontrol et. Bu görev
başlatılırken çalışma dalı `codex/ration-card-desk` idi; bunun değişmediğini
varsayma. Kullanıcının, Claude'un ve ekip arkadaşının değişikliklerini koru.

## 2. Değişmez oyun kimliği

- Oyun **3D, birinci şahıs ve ileride yarı açık dünya** olacak.
- Bütün eylemler karakterin gözünden görülür. Kamera başka bir karaktere,
  dış çekime veya bağımsız bir masa ekranına geçmez.
- Karne dünyada bulunan tek bir fiziksel nesnedir. Elde, masada, müşteri
  tarafında veya alıkoyma bölmesinde olabilir. Ekrana yapıştırılmış belge değildir.
- Masa, damga, makas, defter ve ürünler gerçek 3D nesnelerdir. Oyuncu bunlara
  bakar ve erişim mesafesi içindeyken etkileşir.
- Bu bir idle oyun, masa yönetimi ekranı veya menülerden belge onaylama oyunu değildir.
- Papers, Please'den alınan fikir belge üzerindeki kanıtları karşılaştırmaktır;
  onun ekran düzenini veya sabit masa kamerasını kopyalama.
- UI yalnızca küçük hedef işareti, bağlamsal kontrol ipucu, gerektiğinde kısa
  altyazı ve duraklatma/ayarlar için kullanılır. Karne yazısı kâğıdın üzerindedir.
- Tarihsel atmosfer: komünist dönem Polonya'sı. Meslek sınıfları, kotalar,
  damgalar ve yaptırımlar oyun için sadeleştirilebilir veya kurgulanabilir.
  Tarihsel simülasyon doğruluğu ana hedef değildir.
- Karne ana mekaniktir; genel açık dünya, dekorasyon veya ekonomi genişlemesi
  bu etkileşim tamamlanmadan önüne geçmez.

## 3. Hedeflenen tek müşteri döngüsü

1. Oyuncu odada serbestçe yürür ve servis penceresine yaklaşır.
2. Müşteri pencerenin dışından istediği ürün ve miktarı söyler, karneyi uzatır.
3. Oyuncu uzatılan karneye bakıp etkileşir. Aynı 3D karne müşteriden alınır;
   kısa teslim alma hareketinden sonra çalışma masasının üzerine bırakılır.
4. Oyuncu hiçbir inceleme başlatmadan odadan uzaklaşabilmelidir. Karne masada
   kalır, müşteri bekler ve kamera serbesttir.
5. Oyuncu masadaki karneye bakıp inceleme etkileşimini seçer. Karakter aynı
   göz kamerasıyla masaya doğru doğal ve sınırlı biçimde eğilir.
6. Oyuncu karneyi masada inceler veya açık bir alma eylemiyle eline alır.
   Elde yakınlaştırır, sağa sola eğer ve arka yüzüne bakar. Masaya bırakınca
   nesne yüzeyde kalır; görüntüye bağlı hareket etmez.
7. Ön ve arka yüzdeki bilgileri, meslek kurallarını ve fiziksel kural defterini
   karşılaştırır. Sistem belgeyi kendiliğinden doğru/yanlış olarak etiketlemez.
8. Oyuncu karar verir: satış, ret veya alıkoyma. Gereken damgayı fiziksel
   olarak alır ve doğru alana basar. Satışta ilgili kuponu makasla keser.
9. **SATIŞ kararında, belge işlemleri tamamlandıktan sonra** oyuncu incelemeden
   ayrılır ve odanın içindeki erzak raflarına gider. Kupon kesmek için önce
   eline ürün almak zorunda bırakılmaz. RET ve ALIKOY kararlarında erzak
   toplama/teslim adımları atlanır; doğrudan belge iadesine veya alıkoymaya geçilir.
10. İstenen ürünü ve miktarı uygun stoktan alır. Ürünü elinde fiziksel olarak
    tezgâha taşır; gerekirse tezgâha bırakıp tekrar alır ve müşteriye uzatır.
11. Kalan karneyi müşteriye iade eder. Alıkoyma kararında karneyi ilgili
    bölmeye koyar; ret kararında ürün vermeden karneyi iade eder.
12. İşlem tek kez kayda geçer. Sonraki müşteri ancak mevcut işlem bittiğinde
    çağrılır. Oyuncu dükkânda dolaşmaya devam edebilir.

Müşterinin isteği konuşma bittikten sonra da dünyadaki talep fişinden
okunabilsin veya müşteriyle kısa tekrar etkileşimiyle hatırlatılabilsin.
Sürekli açık bir sipariş penceresine bağımlılık yaratma.

## 4. Ayrılabilmek zorunlu bir özelliktir

Kullanıcının bildirdiği hata: “İnsanlarla konuşmayı bırakamıyorum; kartları
hâlâ ekranda görünüyor.” Bunu yalnızca altyazıyı gizleyerek çözülmüş sayma.
Hareket, bakış, eldeki nesne, kamera ve devam eden işlem birlikte sınanmalıdır.

- Müşteriyle konuşma karakteri sabit bir sahneye hapsetmez.
- Konuşmayı bitirmek müşteriyi reddetmek veya işlemi silmek anlamına gelmez.
- Oyuncu müşteri onayı beklemeden geri çekilebilir ve odada yürüyebilir.
- Uzaklaşınca konuşma sunumu kapanır; müşteri ve bekleyen işlem korunur.
- Masada incelemeden tek açık çıkış eylemiyle ayrılınır. Yürümeye basmak da
  inceleme pozunu bırakıp hareketi geri vermelidir.
- Çıkışta göz kamerasının geçici eğilme konumu geri alınır. Fare ve hareket
  kilitleri, basılı tuş durumları veya araç kullanımı kalıcı biçimde takılı kalmaz.
- Sağ tuş bırakma olayı kaçırılsa bile açık çıkış ve odak kaybı kontrolü kurtarır.
- Duraklatma, pencere odağını kaybetme ve yeniden başlatma tamamlanmamış
  etkileşimleri güvenle temizler.
- Tamamlanmış bir damga veya kesim ayrılınca silinmez. Tamamlanmamış hareket,
  tamamlanmış işlem gibi stok veya kupon tüketmez.
- Normal alma/bırakma ve temas animasyonları kısa olabilir; müşteri konuşması
  boyunca veya belirsiz süreyle oyuncunun kontrolünü kilitleme.

## 5. Masaya eğilme ve elde inceleme ayrı eylemlerdir

### Masada inceleme

Karne masada dururken etkileşim karakterin gözünü masaya yaklaştırır. Kart
kameraya taşınmaz. Yazılar okunabilir boyutta görünür; araçlar ve yakın masa
alanı erişilebilir kalır. Oyuncu aynı kamerayla bakışını kart üzerinde gezdirir.
Eğilme yüzeye veya duvara kamera sokmamalı, aşırı FOV değişimi yapmamalıdır.

İncelemeyi kapatınca kamera yürüyüş konumuna yumuşakça döner. Oyuncu tekrar
etkileştiğinde aynı karneyi, önceki izleri ve kesimleri bulur. Yakına gelmek
veya bakmak tek başına tam ekran arayüz açmaz.

### Elde inceleme

Masadaki karneyi ele almak ayrı ve açık bir girdidir. Sol el kâğıdı kenarından
kavrar; önemli yazıyı kapatmaz. Sağ tuş gibi bir inceleme girdisi basılıyken
fare karneyi eğer; oyuncunun bakışını aynı anda istemsiz döndürmez. Girdi
bırakıldığında normal FPS bakışı geri gelir. Yakınlaştırma mesafesi sınırlıdır.

Ön ve arka yüz aynı kâğıdın iki yüzüdür. Çevirme gerçek 3D dönüşle yapılır;
arka yüz ayrı açılır pencere değildir. Masaya bırakma yüzey temasıyla biter.
Elde taşımak bilinçli bir seçimdir; teslim alınan her karneyi sürekli kameranın
önünde tutmak varsayılan akış değildir.

## 6. Karne ayrıntısı ve kanıta dayalı inceleme

Karne yalnızca renkli bir dikdörtgen veya onay butonu olmasın. İki yüzündeki
bilgiler, meslek sınıfı ve kullanım izleri karar vermek için gerçekten işe yarasın.

İlk çalışan dilimde en az işçi, öğretmen ve emekli sınıfları bulunur. Yeni
sınıflar veriyle eklenebilir. Her sınıfın okunabilir adı, görsel ayrımı, kurum
kodu ve ürün hakları vardır. Meslek kişinin dürüstlüğünü belirlemez.

İncelenebilecek alanlar:

| Alan | Oyuncunun karşılaştırdığı şey |
| --- | --- |
| Ad soyad | Kart sahibi ve müşteri/ek belge bilgisi; yalnızca ek belge uygulanmışsa |
| Seri numarası | Ön ve arka kayıt; yinelenen seri denetimi ayrı uygulanacak özellik |
| Ay ve yıl | İşlem tarihine göre geçerlilik |
| Meslek sınıfı | Fiziksel kural defterindeki kurum ve kota |
| Kurum kodu | Sınıfla uyum ve arka yüz kaydı |
| Ürün kuponları | Ürün adı, hak miktarı ve kullanılabilirlik |
| Kurum onayı | Arka yüzde basılmış mühür; eksiklik veya görünür müdahale |
| Satıcı damgaları | Oyuncunun bu işlemde bastığı gerçek izler |
| Kâğıt izleri | Yıpranma, kıvrım, silinti, ek yama veya değiştirilmiş baskı |

Veriyle uygulanmış karşılaşmalar; geçerli belge, yıpranmış ama geçerli belge,
eski ay, kullanılmış kupon, eksik onay, sınıf/kurum çelişkisi ve değiştirilmiş
hak gibi birbirinden farklı durumları kapsasın. Eskimiş kâğıt otomatik sahte
olmasın. Eksik mühür ile kasıtlı sahtecilik aynı yaptırım olmak zorunda değildir.

Gelecek özellikleri uygulanmış gibi gösterme: kimlik belgesi, aile adına
alışveriş, veri tabanından seri kontrolü, UV ışık, büyüteç veya sınırsız belge
üretimi ancak ayrıca tamamlanıp test edilirse özellik listesine yazılabilir.
İlk dilimde belgenin kendi alanları ve kural defteri yeterli olmalıdır.

### Okunabilirlik ve fiziksel tutarlılık

- Yazı çözünürlüğü yakın incelemede okumaya yeterli olsun; etkileşim alanı
  basılı alanla örtüşsün. Ön yüzdeki bir kupon arka yüzde başka yere kaymasın.
- Damga izi kâğıda bağlı kalsın. Kartı çevirmek veya eline almak izi sıfırlamasın.
- Ayrılan kuponun bulunduğu yerde iki yüzden de boşluk görülsün.
- El, araç ve kâğıt kameraya girip çıkmasın; metni veya hedefi sürekli kapatmasın.
- Duruma göre sahtecilik cevabı veren renk, işaret veya başarı sesi kullanma.
- Oyun için uydurulmuş kuralları tarihsel gerçek olarak sunma.

## 7. Karar, damga ve alıkoyma

Oyuncu fiziksel SATIŞ, RET ve ALIKOY araçlarını kullanır. Araç seçimi yalnızca
menü düğmesiyle gerçekleşmez: masadan alır, tutar, hedefe götürür ve bırakır.

SATIŞ geçerli görülen kartla işlem yapma kararıdır; otomatik ürün teslimi değildir.
RET, ürünü vermeden karneyi müşteriye iade etmektir. ALIKOY, sahtecilik şüphesiyle
belgeyi özel bölmeye koymaktır. Her hata aynı yaptırımı gerektirmez; kurmaca
karar kuralları kural defterinde anlaşılır biçimde bulunur.

Oyuncu yanlış karar verebilir. Sistem sahte belgeye SATIŞ basılmasını yalnızca
sahte olduğu için engelleyerek cevabı açığa çıkarmaz. Yanlış kararın sonucu
sonraki değerlendirme, denetim riski veya uygun oyun sonucunda görülür.

Damgada beklenen his:

1. Kâğıt masa üzerinde desteklenir.
2. Araç karar alanına hizalanır.
3. Basma hareketi fiziksel temas noktasına iner.
4. Mürekkep izi ve temas sesi aynı anda oluşur.
5. Araç kaldırılır; ayrı kaldırma sesi ve küçük geri hareket hissi vardır.

İz her karede yeniden eklenmez; bir temas bir işlem üretir. Araç hedefe
ulaşmadan iptal edilirse iz oluşmaz. Tamamlanmış temas korunur.

## 8. Kupon kesme

Makas gerçek bir el nesnesidir. Oyuncu doğru ürünün kupon çizgisine hizalar;
kesme girdisiyle çizgi boyunca ilerler. Makas ağızları, ilerleme ve kesme sesleri
aynı hareketi destekler. İşlem tek tıklamayla açıklamasız bir kupon silme olmasın.

- SATIŞ kararı ve müşterinin istediği uygun kupon gerekir.
- Kupon miktarı istenen miktarı karşılamalıdır; yanlış ürün kuponu tüketilemez.
- **Hazırlanmış veya elde taşınan ürün kesimin önkoşulu değildir.**
- İlk dilimde kesim kısa kalırsa, çizgiden çıkılırsa veya iptal edilirse kupon
  tüketilmez. Tam kâğıt yırtılma simülasyonu sonraki bir özellik olabilir.
- Kesim tamamlanınca kupon tek kez ayrılır. Kart üzerinde fiziksel boşluk,
  masada/kutuda ise ayrı bir 3D parça görünür.
- Aynı kupon yeniden kesilemez; eline alma, çevirme, uzaklaşma veya kayıt
  dönüşümü kuponu geri getiremez.
- İlk dilimde parça kutuya yönlendirilebilir. Oyuncunun her parçayı tek tek
  toplaması zorunlu değildir; bu sınırı belgede açıkça belirt.

## 9. Erzak, taşıma ve karaborsa seçimi

Belge işlemleri tamamlandıktan sonra oyuncu odadaki fiziksel stoklara yürür.
İlk dilimde et, şeker ve sabunla döngüyü bitir. Sonraki ürünler dönem atmosferine
uygun, normalde satılabilen erzak ve gündelik ihtiyaçlardan seçilebilir: un,
ekmek, çay, kahve/ikamesi, konserve, süt ürünü veya kibrit. Bunları tek seferde
varmış gibi saymak yerine model, miktar, stok ve etkileşimleri tamamlandıkça ekle.

Ürün alma bir ekran envanterinden sürükleme işlemi olmasın. Oyuncu ilgili
raf/kolinin yanına gider, doğru ürünü alır, elinde taşır ve tezgâha koyar.
İlk dilimde miktarı hazır paketler kabul edilir. Serbest tartım, açılan paketler
ve çok ürünlü siparişler bu döngü tamamlandıktan sonra geliştirilir.

Resmî stok ile gizli/kayıt dışı stok ayrı tutulur. Et gibi normal bir ürünün
hangi kaynaktan verildiği oyuncunun kararıdır; sırf ürünün adı nedeniyle
kaçak eşya olarak sınıflandırma. Gizli stoktan verme otomatik çözüm olmasın.
Oyuncu riski alıp vermeyi veya uygun durumda reddetmeyi seçebilir. Kaynak,
ödeme hesabı ve sonuç doğru kayda geçer.

Karne bedava ürün kuponu değildir; ürün hakkını belirler. Fiyat ve ödeme
mantığı bunu ayırır. İlk dilimde ödeme hesaplaması otomatik olabilir; fiziksel
para sayma ve para üstünü uygulanmış gibi gösterme.

İki kaynakta da yeterli stok yoksa oyuncuyu fark etmeden geri dönüşsüz kesime
zorlama. İlk tek müşterili dilimde stok kontrolü kesimden önce yapılabilir;
fiilî kaynak seçimi ürün alınırken yapılır. Gelecekte stok başka sistemlerle
paylaşılırsa rezervasyon ve iptal kuralları ayrıca tasarlanmalıdır.

## 10. Kontrollerin sözleşmesi

Varsayılan eşleme aşağıdaki gibi olabilir. Değiştirilecekse bütün ipuçlarını,
belgeleri ve testleri birlikte güncelle. Aynı girdi, durumuna göre öngörülemez
biçimde başka işlem başlatmasın.

| Girdi | Davranış |
| --- | --- |
| WASD / fare / Shift | Yürü, bak, hızlı yürü |
| E, müşteri karneyi uzatırken | Karneyi al; kısa hareketle masaya bırak |
| E, masadaki karne veya çalışma alanında | Aynı göz kamerasıyla incelemek için eğil |
| R, masadaki karne üzerinde | Karneyi bilinçli olarak eline al |
| Sağ tuş basılı + fare | Elde tutulan belgeyi eğ; normal bakışı geçici olarak durdur |
| F | Elde veya masadaki karneyi ön/arka çevir |
| Tekerlek | Elde tutulan belgeyi sınırlı mesafede yaklaştır/uzaklaştır |
| E, masadaki araç/ürün üzerinde | Uygunsa al |
| G, uygun yüzeye bakarken | Tutulan nesneyi yüzeye bırak |
| Sol tuş | Tutulan damga veya makasla fiziksel işlem yap |
| E, müşteri üzerinde | Elde ürün/kart varsa uygun teslim; yoksa isteği tekrar dinle |
| Q | Etkileşimden ayrıl; yarım inceleme/kesme durumunu temizle |
| WASD, eğilerek inceleme sırasında | İncelemeden ayrılıp yürümeye başla |
| Esc | Duraklatma/ayarlar; yarım araç hareketini güvenle bırak |

Sağ ve sol el işlevleri, bırakma önceliği ve neden yapılamadığı kısa ipuçlarıyla
anlaşılır olsun. Aynı anda tutulamayan iki nesnenin biri sessizce kaybolmasın.
Uzakta, duvar arkasında veya başka nesnenin arkasında kalan araca erişilemesin.

## 11. İşlem durumları ve güvenilirlik

İşlemin mantıksal durumu ile nesnenin fiziksel konumunu ayır:

- Belge konumu: müşteri → alınma → masa ↔ el → iade veya alıkoyma.
- Oyuncu modu: serbest hareket ↔ masaya eğilme; elde inceleme ve araç hareketi
  bu modlarla açık, iptal edilebilir geçişler üzerinden çalışır.
- Satış ilerleyişi: inceleme → karar/damga → uygun kupon → ürünü toplama →
  tezgâhta/elde ürün → müşteriye ürün → kalan belgenin teslimi → tamamlanma.
- Ürün konumu: raf → el ↔ tezgâh → müşteri. Yere bırakma destekleniyorsa
  aynı ürün tekrar alınabilmeli ve işlemden kopmamalıdır.

Fiziksel belgeyi yeniden yaratarak işlem ilerletme. Müşteri beklerken masadaki
tek belge ve tek hazırlanmış paket korunur. Aynı paket tekrar hazırlanamaz;
var olan paketi geri almak gerekir. Müşteriye verilen ürünü ikinci kez verme.

Stok ve para sonuçlarını tek yetkili işlem katmanı değiştirsin. Animasyon
kodları her karede stok düşürmesin. Toplama/yer değiştirme ayrı, fiilî satışın
muhasebeleştirilmesi ayrı olsun. İlk dilimde ürün ve kalan kart teslimi birlikte
tek satış olarak tamamlanabilir; hangi aşamada taahhüt edildiği açık olmalıdır.
Ürün teslim edildikten sonra RET basarak verilmiş ürünü kayıttan silmek mümkün
olmasın. Çift tıklama veya yeniden etkileşim çift gelir üretmesin.

İptal, duraklatma ve yeniden başlatma eski animasyon callback'lerinin yeni
müşterinin kartına işlem yapmasını engellesin. Ekrandaki görünüm, kayıtlı
konum ve etkileşim çarpışması birbiriyle tutarlı kalsın. Kart izleri ve kesimler
mantıksal kayıt dönüşümünde korunsun. Tam dünya konumu kaydı uygulanmamışsa
“tam kayıt/yükleme var” deme.

## 12. ASMR ve etkileşim kalitesi

Her eylemde önce oyuncunun yaptığı hareketi, sonra gerçek temas anını düşün:

| Eylem | Görsel/bedensel his | Ses |
| --- | --- | --- |
| Karneyi alma | Kenardan kavrama, kısa çekiş | Hafif kâğıt sürtünmesi |
| Masaya bırakma | Yüzeye yerleşme, küçük durulma | Yumuşak kâğıt/masa teması |
| Çevirme | Tutarlı iki yüz, kontrollü dönüş | Kâğıt bükülmesi |
| Damga | Hizalama, basınç, temas, kaldırma | Tok baskı ve ayrı kaldırma |
| Kesme | Makas ağızları ve çizgide ilerleme | Aralıklı metal/kâğıt kesimi |
| Kupon ayrılması | Aynı karttan ayrılan parça | Hafif düşüş/sürtünme |
| Ürün bırakma | Ağırlığa uygun yerleşme | Ambalaj ve yüzeye uygun temas |

Ses girdiye basıldığı anda değil, uygun fiziksel olayda çalsın. Sesler üst üste
patlamasın, tekrarda küçük ve kontrollü çeşitlilik taşısın. Başarı/hata melodisi
kâğıt ve araç seslerini örtmesin. Ses seviyesi ayarlanabilsin. Prosedürel sesler
ilk dilim için kullanılabilir; gerçek foley kaydı dinlenmeden bitmiş ASMR kalitesi
iddia edilmez. Kamera sallantısı ve hareketler yazıyı okumayı zorlaştırmasın.

## 13. Mevcut projeyle çalışma

Önce `AGENTS.md`, `README.md`, `docs/RATION_DESK_DESIGN.md` ve ilgili sahne/kodları
oku. Godot 4.7.2 standard ve typed GDScript kullan. Mevcut başlangıç sahnesini
kontrol et. Bu görev hazırlanırken ana FPS sahnesi `scenes/kiosk/fps_kiosk.tscn` idi.

Mevcut sorumlulukları koru; gerekirse kontrollü biçimde ayır:

| Parça | Sorumluluk |
| --- | --- |
| KioskFPSPlayer | Hareket, çarpışma, baş/göz kamerası |
| FPS kiosk etkileşimi | Erişim ışını, alma/bırakma, eğilme, araç temasları |
| RationCard3D | Aynı belgenin iki yüzü, dünya/yazı koordinatları, kupon boşlukları |
| RationCardView | 3D yüzeye basılan yazı/görsel; oyuncuya açılan masa ekranı değil |
| RationDeskRules | Kararlar, kotalar, konum önkoşulları ve işlem sonuçları |
| Game / CampaignState | Yetkili durum ve atomik değişiklikler |
| RationFoley | Temas anlarına bağlı ses |
| content/ration | Müşteri, belge ve karşılaşma verisi |

Eski 2D sahneyi ana akışa geri koyma. Mevcut içerik verisini, kayıt sistemini
ve başka geliştiricilerin çalışmasını gereksiz yere yeniden yazma. Bütün sahne
üreticilerini çalıştırıp elle yapılmış sahneleri ezme. Mevcut checkout'ta çalış;
kullanıcı istemedikçe yeni worktree kurma. Eşzamanlı çalışan geliştiricilerle
dosya sahipliğini paylaş. Yapılanlar ve sonraya kalanları belgelerde ayrı tut.

## 14. Uygulama sırası

Her aşamayı çalışan ve kontrol edilebilir halde bitir; yalnızca plan bırakma.

1. Mevcut hatayı yeniden üret: müşteriden ayrılma, karne konumu, kamera/fare
   kilidi, araç hareketleri. Önce gerçekten neyin kilitlediğini bul.
2. Temel FPS ve erişimi doğrula: yürüyüş, bakış, tezgâh çarpışması, mesafe,
   tek nesneyi alma ve doğru yüzeye bırakma.
3. Teslim alınan karneyi masaya yerleştir. Serbest ayrılma ve aynı belgeye
   dönmeyi tamamla. Bu aşamada kâğıt kameraya kalıcı bağlı kalmasın.
4. Masaya eğilme, açık çıkış, elde inceleme ve iki yüz arasında geçişi ekle.
5. Okunabilir belge alanları, sınıf/kota kuralları ve sahtecilik kanıtlarını kur.
6. Damga, kesim ve alıkoyma temaslarını güvenilir hale getir.
7. Belge sonrası raflardan ürün toplama, taşıma, tezgâha bırakma ve teslimi bağla.
8. Yanlış karar, ret, gizli stok, stok yetersizliği ve tekrar eylemleri işle.
9. Temas animasyonları, ses, yazı okunabilirliği ve kontrolleri birlikte iyileştir.
10. Gerçek girdilerle uçtan uca doğrula; güncel belgeleri ve inceleme kanıtını bırak.

Bu sırada gereksiz kapsam büyütme. Açık dünya haritası, tam vücut IK, çok ürünlü
sipariş, terazi, para üstü ve günler arası kampanya bu çekirdeğin sonraki aşamalarıdır.

## 15. Zorunlu kabul senaryoları

Aşağıdaki maddeler geçmeden “tamamlandı” deme. Her başarısızlığı düzelt veya
somut dış engeli belirt; bir testi kaldırarak başarı elde etme.

- [ ] Uzaktaki müşteri veya duvar arkasındaki araç alınamaz.
- [ ] Oyuncu WASD ile yürür ve tezgâhın içinden geçmez.
- [ ] Müşteriden alınan karne aynı dünya nesnesi olarak masaya yerleşir.
- [ ] Oyuncu hemen geri çekilip yürüyebilir; karne görüşüne yapışıp gelmez.
- [ ] Müşteri bekler; uzaklaşıp dönmek yeni müşteri veya yeni kart oluşturmaz.
- [ ] Masadaki karta etkileşim aynı göz kamerasıyla eğilme başlatır.
- [ ] Q ve yürümeye başlamak eğilmeden çıkar; normal hareket ve bakış geri gelir.
- [ ] Sağ tuş bırakılmasa dahi açık çıkış/odak kaybı takılı incelemeyi temizler.
- [ ] Karne masadan ele alınıp çevrilebilir; ön/arka alanlar okunabilir.
- [ ] Tekrar masaya bırakmak damgaları, kesimleri veya mevcut ürünü sıfırlamaz.
- [ ] Geçerli ve yıpranmış belgeyle doğru satış yapılabilir.
- [ ] Eski ay, kullanılmış kupon ve eksik onay uygun ret akışını destekler.
- [ ] Sahte kurum veya değiştirilmiş kota doğru alıkoyma akışını destekler.
- [ ] Oyuncu yanlış karar verebilir ve sonuç ayrıca kayda geçer.
- [ ] Damga görünür temasta tek iz bırakır; ses temasla eşleşir.
- [ ] Yarım/iptal/çizgi dışı kesim kupon tüketmez ve hareketi kilitlemez.
- [ ] Tam kesim tek kupon ayırır; iki yüzde aynı boşluk kalır.
- [ ] Damga ve kesim, raflara gidip ürün almadan önce tamamlanabilir.
- [ ] Yanlış raf veya yetersiz stok yanlış ürün/paket üretmez.
- [ ] Aynı sipariş için ikinci paket üretilemez; mevcut paket geri alınır.
- [ ] Oyuncu ürünü odadan tezgâha taşır, bırakır, geri alır ve teslim eder.
- [ ] Resmî ve gizli stoktan verme ayrı ve bilinçli seçimlerdir.
- [ ] İki kaynak da yetersizse kesim/teslim güvenli biçimde engellenir.
- [ ] Kart ve ürün teslimi tek kez stok, para ve kayıt değiştirir.
- [ ] Teslim edilmiş ürünü sonradan retle hesaptan silmek mümkün değildir.
- [ ] Damga/kesimden sonra masadan ayrılıp dönmek işlemi korur.
- [ ] Alma, çevirme veya damga sırasında yeniden başlatma eski işlemi yeni güne taşımaz.
- [ ] Duraklatma ve odak kaybından sonra araç, el, kamera ve çarpışmalar tutarlıdır.

Birim testleri kuralları ve atomik sonuçları; FPS selftest'i gerçek klavye/fare
girdilerini, erişimi ve konum geçişlerini sınasın. Kamera/animasyon değişince
pencereli çalıştırıp görsel olarak da kontrol et. Test için oyuncuyu fixture
konumlarına taşıdıysan bütün yürüyüş rotasını otomatik oynadığını iddia etme.

Mevcut kontrolleri repository kökünde çalıştır:

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest
# Grafik oturumu gerektirir:
godot --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest
```

Sistemdeki `godot` farklı sürümse projenin 4.7.2 binary'sini kullan. Başarılı
çıkış kodunun yanında testlerin gerçekten çalıştığını, hata günlüklerini ve
görüntüleri kontrol et. Dummy ses aygıtında yapılan kontrolü gerçek dinleme
olarak sunma. Geçmiş test sayısını yeni çalışmanın kanıtı olarak kopyalama.

## 16. Teslimat

İş sonunda somut, oynanabilir sonucu ve şu bilgileri ver:

- Hangi davranış değişti ve oyuncu bunu nasıl kullanacak?
- Hangi dosyalar değişti; diğer geliştirici nereden devam edecek?
- Hangi testler gerçekten geçti, hangileri çalışmadı veya başarısız oldu?
- Masada ve elde incelemeyi gösteren güncel görüntüler nerede?
- Hangi özellikler tamamlandı, hangileri hâlâ hedef veya prototip?

Açık kararları gereksiz onay sorularıyla çoğaltma; kullanıcı bu kapsamda
uygulama istemiştir. Gerçekten gereken eksik bilgi varsa bağımsız işleri
sürdürerek sor. Erişim yoksa kod yazmış gibi davranma; dış engeli açıkça bildir.
GitHub'a kaydetme yetkisi kapsamında üzerinde çalışılan dala anlaşılır commit
bırak; başkasının dalını ezme veya ana dala onaysız birleştirme yapma.

**Bütün tasarım kararlarını şu soruyla denetle:** “Bu hareketi gerçek bir
insan camdaki müşteriden aldığı karneyle, kendi elleri ve masası üzerinde nasıl
yapardı?” Oyunda da karakterin gözünden o fiziksel ilişki görülmelidir.
