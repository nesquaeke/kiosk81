# Karne mekaniği: değerlendirme ve geliştirme yol haritası

> Güncel uygulama: [tek tuşla elde inceleme ve damga kılavuzu](CARD_INSPECTION_UPDATE.md).
> Kullanıcının son onayladığı ayrıntılı sıra ve ilerleme [bu listede](CARD_INTERACTION_BACKLOG.md).
> Aşağıdaki değerlendirme, bu ilk iki dilimden önceki sürümün başlangıç analizidir.

18 Ekim 2026 · İncelenen uygulama: `aeebe8b`.

Bu belge bir tasarım değerlendirmesi ve önerilen çalışma sırasıdır. Buradaki yeni
özellikler uygulanmış veya oyuncularla doğrulanmış sayılmaz. Değerlendirme kod,
mevcut tasarım sözleşmesi ve oyun içi görüntülere dayanır. İnsan oyuncularla eğlence,
kullanılabilirlik ve gerçek ses aygıtında ASMR değerlendirmesi henüz yapılmadı.
Önceki 226 test sonucu teknik doğrulamadır; eğlence kanıtı değildir.

## 1. Mevcut durum hakkında hüküm

Çalışan bir fiziksel etkileşim prototipi var. Aynı belge müşteriden masaya geliyor;
ön/arka yüz, büyüteç, referans, kalıcı hasar, damga ve iade/alıkoyma akışı çalışıyor.
Bu altyapı geliştirmeye değer. Oyuncuyu tekrar oynamaya çağıran güçlü bir ana
mekanik henüz kanıtlanmış değil. Yeni sistem sayısı bu belirsizliği çözmez.

Önceki uygulamada teknik doğruluk, oyun kalitesinin önüne geçti. Düzgün kaydedilen
bir yarık veya farklı görünen damga, bunları kullanmak ilginç olmadıkça yeterli değil.
Hedef: oyuncunun kanıt araması, bir sonuca varması, fiziksel bir işlemle kararını
uygulaması ve o kararın insan üzerindeki etkisini görmesi.

## 2. Somut envanter

| Alan | Şu anda olan | Asıl eksik / risk |
| --- | --- | --- |
| Teslim alma | Kart dünya uzayında yaklaşık 0,36 sn'de masaya aktarılıyor | Senkron müşteri bırakışı/oyuncu kavraması zayıf; hareket büyük ölçüde otomatik |
| Kamera ve çalışma | Üstten aynı kamera, pan, zoom; elde inceleme | Çok sayıda ayrı kontrol ve mod, oyuncu hedefinden uzaklaşabiliyor |
| Masa düzeni | Araçların hepsi başlangıçta kadrajda | Karta ayrılan alan küçük; masada doğrudan kaydırma/çevirme yeterince serbest değil |
| Kart sanatı | İki yüz, dönem fontları, mühür, lif, kat, yama | Baskı hiyerarşisi ve kişisel kullanım hikâyesi sınırlı; geniş görünümde küçük yazılar |
| İnceleme | Üç sınıf, kod/kota karşılaştırması, optik büyüteç | Büyüteç çoğunlukla zaten görülen bilgiyi büyütüyor; yöntem seçimi zayıf |
| İçerik | Sabit sırada sekiz vaka | Tekrar oynayınca isim/pozisyon ezberi; sistemik varyasyon ve denge yok |
| Kesim | Metre ölçeği, kalıcı yarık, iki yüz, kopan kupon | Kopma basılı dikdörtgenin dört kenarına bağlı; keyfi kapalı kesim bölgeleri yok |
| Makas hissi | Uç en fazla 7,5 cm/sn ilerliyor, ağızlar yola göre açılıyor | Elden gelen aç/kapa ritmi ve malzeme direnci sınırlı; tüm çevreyi izleme tekrar riski |
| Damga | Temas, yaklaşma hızı, bekleme, açı ve sürüklenme izi | Tek karar alanı; basınç fare hareketinden türetilen bir yaklaşım; farklar karar açısından çoğunlukla kozmetik |
| Kopan parça | Doğru baskıyı taşıyor, tek parça üretiliyor | Kendiliğinden kutuya uçuyor; son dokunma/bırakma oyuncuda değil |
| Eller / müşteri | Prosedürel kavrama ve basit müşteri | Tam el hedefleme/IK, ağırlık, karşılıklı teslim ve inandırıcı tepki yok |
| Sonuç | Doğru/yanlış, hasar gerekçesi ve işlem kaydı | Anlık insan tepkisi, hatırlanan müşteri ve kararın sonraki etkisi sınırlı |
| Ses | Temasa bağlı prosedürel örnekler | Gerçek dinleme, konumsal katmanlar ve tekrarı az, özenli kayıtlar gerekli |
| Mimari | Kurallar Game etkileriyle ayrılmış | Ortak FPS dosyasında 1600'den fazla satır ve çok sayıda etkileşim bayrağı; genişleme riski |

Kesim özelinde: mevcut kupon 10,125 × 5,0625 cm. Çevresi yaklaşık 30,375 cm;
7,5 cm/sn sınırla yalnızca bıçak yolculuğu en az 4,05 sn. Hizalama ve araç
bırakma bu süreye ekleniyor. Bu hesap bir kullanılabilirlik ölçümü değildir;
tekrar maliyetini test etmek gerektiğini gösterir.

Kağıdın içindeki dört kenarlı kupona makasla ortadan başlamak fiziksel olarak da
sorgulanmalıdır. Baskı çizgisinin biraz dışından kesilmiş kapalı bir bölgenin
kopmaması, mevcut geometri yaklaşımının sınırıdır. 'Tam serbest kesim' denmemeli.

## 3. Eğlenceyi kuracak üç ayrı katman

### Merak ve çıkarım

Oyuncu bir şüphe geliştirir, uygun incelemeyi seçer ve kanıtla sınar. Her kartta
bütün araçları kullanmak gerekmez. Aşınma suç kanıtı değildir; sınıf/kurum ilişkisi,
kota müdahalesi ve izin verilen istisnalar farklı bilgi kaynaklarıyla açıklanır.

İlk öğrenme hissi: 'Öğretmen kotasını öğrendim.'
İlerideki ustalık hissi: 'Bu kartta önce hangi alanı kontrol etmem gerektiğini biliyorum.'

### Fiziksel tatmin

Kâğıdı yerleştirme, kenarı kaldırma, makas ağzını kapatma ve damgayı kaldırıp izi
görme kendi başına hoş olmalı. Duyusal çeşitlilik çoğunlukla doğal geri bildirimdir;
her baskıyı kusursuz yapma zorunluluğu, zorunlu ritim veya puan avına dönüşmemeli.

### Karar ve insan

Belgede ne olduğunu anlamak ile kişiye ne yapılacağı ayrı kararlar olabilir.
Kuralı ve olası sonucu açık olan insani istisnalar seçilebilir. Yanlış belgeyi
fark etmek, sahibinin bilerek sahtecilik yaptığını otomatik olarak kanıtlamaz.
Atmosferi insan yaratır: sıkışık zamanı, bir itirazı, sonraki ziyaretinde hatırladığı karar.

## 4. Hedef kısa oynanış örneği — henüz uygulanmadı

Bir öğretmen et kuponuyla gelir. Kartta 750 g yazmaktadır; referans 500 g gösterir.
Oyuncu kotada bir tutarsızlık fark eder. Kartı hafif eğince yapıştırılmış bölümün
kenarı ışığı farklı yakalar. Büyüteçte yeni baskı ile eski mühür çizgisinin ilişkisi
incelenir. Çevrilen arka yüzde kurum kaydı tutarlıdır.

Oyuncu iki soruyu ayırır: hak değiştirilmiş mi; bu kişiye hangi işlemi uygulayacağım?
İsteğe bağlı kısa bir soru durumu açıklar, sahteciliğin cevabını vermez. Örneğin
kişi kartı işyerinden böyle aldığını söyler. Doğrulanabilir bir istisna varsa
masadaki güncel duyuru veya ek belge bunu destekler; yalnız konuşma kanıt sayılmaz.

Oyuncu geçerli oyun kuralına göre karar verir, damgayı yerleştirip basar. İz,
kaldırdığı anda görünür. Gerekiyorsa kuponu gerçekten keser ve kalan bağlantıyı
ayırır. Kartın masadaki konumu/hasarı kalır. İade veya alıkoyma karşısında müşteri
kısa, duruma uygun tepki verir. Sonuç daha sonra belge ve gerekçeyle açıklanır.

Bu örnekte amaç, zorunlu olarak bütün araçları sırayla kullandırmak değil;
her seçilen incelemenin bir soruyu cevaplamasıdır.

## 5. Geliştirme sırası ve geçiş koşulları

Aşamalar takvim taahhüdü değildir. Bir aşamanın oyuncu kontrolü başarısızsa yeni
özellik ekleyerek ilerlemek yerine o aşama düzeltilir. 'Denemek' ile 'uygulandı'
ve 'oyuncuda işe yaradı' durumları iş kaydında ayrı tutulur.

### Aşama 0 — Mevcut deneyimi ölç (P0)

**Amaç:** Kontrol sıkıntısı, bilgi eksikliği ve sıkılmayı ayrı görmek.

- En az üç yeni kişiyle ilk teşhis oturumu; ardından değişen sürümde 5–8 kişi.
- Üç temel vaka: temiz geçerli, yıpranmış geçerli, değiştirilmiş kota.
- İlk tur sesli düşünme, sonraki tur daha az yönlendirmeyle sessiz oynama.
- Kaydet: yardım isteme, yanlış tuş, yanlış nesne alma, kamera düzeltme,
  araç değişimi, inceleme sırası, karar gerekçesi, sıkıldığını söylediği yer.
- Şu soruları ayrı sor: 'Nasıl yapacağını biliyor muydun?', 'Neden o kararı verdin?',
  'Hangi hareket hoşuna gitti?', 'Hangi hareketi atlamak istedin?'
- Karar doğruluğu tek başarı metriği olmasın. Gerekçesiz doğru tahminleri ayır.

**Çıktı:** Kısa kayıtlar ve önem sırasına göre beş sorun. Küçük örneklemden
pazar/başarı yüzdesi çıkarma. Sonraki testte aynı sorunların azalıp azalmadığına bak.

### Aşama 1 — Teslim alma ve masa kontrolü (P0)

**Amaç:** Oyuncu araçla uğraşmadan işini düşünebilsin.

- Yaklaşma, müşteri tutuşu, oyuncunun kavraması, karşı tarafın bırakması ve
  masaya temasını ayrı, görünür temas anları olarak düzenle.
- Hızlı, kontrollü yerleştirme; uzun veya tekrar tekrar bekleten sinematik yok.
- Üstten geçişin bakış merkezi, yakınlık ve çıkış pozunu tutarlı yap.
- Masada boş elle kartı doğrudan kaydırma/döndürme ve kenarından çevirme.
- Bırakılan araç için boş yüzeyi önceden anlaşılır kıl; araçları birbirine yığma.
- Sık kullanılan hareketleri birincil/ikincil girdiyle tutarlı yap; E/G/R/F/Q
  ezberini ve hangi modda olunduğu yükünü azaltmayı deneyerek karşılaştır.
- Hızlı araç değiştirme, eldeki aracı gerçek yerine geri bırakıp yenisini alabilir;
  nesneleri görünmeden yok etmesin. Serbest yerleştirme seçeneği korunsun.
- Kamera hassasiyeti, yazı ölçeği, yeniden tuş atama ve daha toleranslı kullanım.

**Bitti koşulu:** Yeni oyuncu yardım almadan teslim alır, çevirir, bir araç alır,
bırakır ve masadan çıkar. Masayı terk edip dönünce düzen ve iş korunur.
Kontrollerde takılma esaslı hatalar sonraki oturumda belirgin biçimde azalır.

### Aşama 2 — İncelemeyi gerçek bir bulmacaya dönüştür (P0)

**Amaç:** Oyuncu nereye ve neden baktığını seçsin.

- İlk sette beş kanıt ailesi: tarih, sınıf/kurum eşleşmesi, kota, kurum onayı,
  kâğıda müdahale. Yeni tipler bu beşi anlaşılır hale gelince eklenir.
- Her ipucu için tanımla: görünür belirti, bilgi kaynağı, doğrulama hareketi,
  geçerli açıklama ihtimali, oyuncunun verebileceği karar.
- Doğrudan okunacak alanlar normal çalışma yakınlığında rahat görülsün.
- Büyüteç belirli doku/üst baskı ayrıntılarını, eğme raking ışık/yama kabarmasını,
  çevirme ise arka yüz onayını açığa çıkarsın. Hepsi aynı cevabı farklı büyüklükte
  göstermesin. Mekanik aracın gerekliliği tasarlanmış ipucundan gelsin.
- Büyük/küçük harf, meslek rengi, aşınma ve müşteri tavrı cevap kodu olmasın.
- Geçerli eski onarım ile yetkisiz kota değişikliği gibi karşı örnekler bulunmalı.
  Gerekli ayrımın görülebilir kanıtı ve öğrenilmiş kuralı olmalı.
- İsteğe bağlı bir kısa soru/itiraz akışı. Tekrar eden zorunlu diyalog menüsü yok.
- Rutin geçerli kartlar hızlı tamamlanabilsin; tüm kontroller her kartta şart olmasın.

**Bitti koşulu:** Oyuncu doğru kararı görünür bir kanıtla açıklayabilir. Kuralı
öğrenmiş kişi tanımadığı geçerli/bozuk varyanta aktarabilir; mikro yazı avına muhtaç
kalmaz. Belirsizlik gizli bilgiye veya rastgele cezaya dayanmaz.

### Aşama 3 — Bir damga ve bir makası bitir (P0)

**Damga:**

- Sap tutuşu, hedefe yaklaşma, temas, kauçuk sıkışması, kaldırma tutarlı olsun.
- Mürekkep pediyle doldurma hareketini önce karşılaştırmalı dene. Her müşteride
  zorunlu olmamalı; birkaç baskılık kullanım aralığı olabilir. İyi hissettirmiyorsa ekleme.
- Hız/bekleme farkları görünür ama abartısız; hızlı baskı rastgele okunmaz etiketi
  üretmesin. Piksellik hizalama normal işi cezalandırmasın.
- Şu anda damga ön yüzdeki karar alanıyla sınırlı. Kâğıdın başka yerine basıldığında
  da fiziksel mürekkep izi oluşması deneyde değerlendirilsin; resmî işlemin geçerli
  sayılması ayrı kuraldır. Normal baskıyı piksel hassasiyetiyle cezalandırma.
- Basınç gerçek donanım kuvveti olarak sunulmasın; fare hareketinden yapılan oyun
  yorumudur. Kolay basma alternatifi ve hassasiyet ayarı sınansın.
- İzin okunabilirliğini işleme koşulu yapmak ayrı deneydir; şimdilik ustalık hissi
  ve geri bildirim önceliklidir. Aynı damgayı iki kez basma sistemi sömürü olmamalı.

**Makas ve kâğıt:**

- Dört kenarlı iç kupon ile dış kenara bağlı kupon/perforasyon tasarımını karşılaştır.
  Bir veya iki gerçek kesimle tamamlanabilen tasarım doğal fiziksel bağlantıyla açıklansın.
- 2 cm hasar yine 2 cm kalır. Bütün kupon yalnızca gerçekten serbest kalınca ayrılsın.
- Baskı çizgisini biraz dışından izlemek, fiziksel olarak kapanmış bölgeyi yapay
  biçimde bağlı bırakmamalı. İlk hedef kupon çevresindeki sınırlı alan için güvenilir
  kapalı bölge/bağlantı algısı; tüm kâğıt için pahalı genel yırtılma simülasyonu sonraya.
- Makas aç/kapa ritmi, malzeme direnci ve görsel tepkiyi ayrı deneylerle ayarla;
  sırf fareyi hedefe sürükleyip otomatik ucu bekleme hissini azalt.
- Köşelerde el/bilek ve makas yönü inandırıcı olsun. Hassasiyet desteği fiziksel
  hasarı silmesin; bıçak gerçekten takip ettiği yol kadar kessin.
- Son lif, kopan parçanın elle alınması ve kutuya bırakılması prototiplensin.
  Bu ek etkileşim angarya olursa kısa, isteğe bağlı otomasyon tercih edilsin.

**Bitti koşulu:** Oyuncu aracı ikinci/üçüncü kez kullanmayı hâlâ hoş bulur;
kesim sonrası 'neden kopmadı?' hatası yaşamaz. Tekrar süresi ve yardım ihtiyacı
mevcut yöntemle karşılaştırılır. Makas ustalığı, küçük motor farklarını cezalandırmaz.

### Aşama 4 — Ses, el animasyonu ve masa sanatını aynı temas etrafında cilala (P1)

- Üretim kalitesinde ilk varlık seti yalnızca bir el çifti, bir kart stoğu,
  bir damga, bir makas ve yakın masa yüzeyi.
- Referans video: gerçek kart tutuşu, ince kâğıt, eski kauçuk damga, metal makas.
- Parmak temasları, bilek dönüşü ve nesnenin ağırlığı; animasyon işaretleri gerçek
  temas olayına bağlı. Tüm bedeni çözmeden önce bu yakın planı tamamla.
- Gelen kartlar kullanım geçmişi taşısın: yerel kir, katlanma, kenar aşınması,
  zımba izi, farklı kalemler. Her yaşlanma detayı sahtecilik işareti olmasın.
- Baskı hiyerarşisi: ana bilgi, yardımcı bilgi, güvenlik ayrıntısı. Her yere
  küçük yazı serpmek yerine incelenebilir işlevsel ayrıntılar.
- Fiziksel belgede dönem dili ağırlıklı; Türkçe destek okunabilir, isteğe bağlı
  çeviri katmanı olarak değerlendirilsin. Şimdiki çift dil her alanı kalabalıklaştırıyor.
- Kontrollü yandan çalışma ışığı; yazıyı yakmadan yama ve kenarları ortaya çıkarsın.
- Foley: kâğıt sürtünmesi, yüzeye bırakma, makas ağız/pivot, damga kauçuk teması,
  kaldırma ve çekmece. Birkaç kayıt varyantı; hız/malzeme/kuvvet uygun katmanı seçsin.
- Masa yakın sesi ile pencere/oda ambiyansı ayrı olsun; ses seviyesi, dinamik aralık
  ve tekrarda yoruculuk gerçek kulaklık/hoparlörde sınansın.

**Bitti koşulu:** Sessiz görüntüde de temas okunur; sadece ses dinlendiğinde de
olayların niteliği anlaşılır. 10–15 dakikalık kullanımda sert/tekrarlı sesler yorucu
olmaz. Kör karşılaştırmada oyuncu tercihleri gerekçeleriyle toplanır.

### Aşama 5 — 10–15 dakikalık farklılaşan müşteri oturumu (P1)

**Amaç:** Yeni hareket öğrenildikten sonra merakı ve kararları sürdürmek.

- Yaklaşık 10–12 karşılaşmalı ilk oturum taslağı; süre ve adet test sonucu ayarlanır.
- Önce temiz belge, sonra yıpranmış geçerli; ardından tek tutarsızlık, karşı örnek,
  iki kanıtın birlikte değerlendirilmesi, öğretildiği açık bir istisna.
- Aralara kolay/rutin müşteriler koy; her kişi sahte veya gizemli olmasın.
- Sekiz sabit vakanın yerine, doğruluğu önceden çözülebilen kurallardan tutarlı
  varyantlar üret. Ad/seri/kota/kurum/rakamlar bağımsız rastgele karıştırılmasın.
- Bozulan bir kartta çelişkinin kanıtı gerçekten bulunsun; geçerli kartta yeni
  tasarımın farkında olmadan yarattığı sahtecilik belirtisi kalmasın.
- Zorluk: bilgi ilişkisi ve karar bileşimi. Küçük font, düşük kontrast veya aşırı
  benzer mühür tek başına zorluk yöntemi olmasın.
- Sonraki turda düzen/vaka değişsin; aynı sırayı ezberlemek yeterli gelmesin.
- Müşteri talep, bekleme ve karar karşısında kısa tepki versin. Öğrenilmiş beden
  hareketi sahteciliği ele veren kesin ipucu olmasın.

**Bitti koşulu:** Oyuncu oturum sonuna kadar yeni bir düşünme ihtiyacı yaşar;
ikinci oturumda isim ve sıra ezberiyle bütün cevapları alamaz. 'Bir müşteri daha'
isteği gönüllü davranış ve gerekçeyle gözlenir; sayısal hedef başarı garantisi sayılmaz.

### Aşama 6 — Sonuç, adalet ve tekrar oynama (P1/P2)

- Onay, eksik belge nedeniyle işlem yapmama, kartı alıkoyma ve insani istisnayı
  ayır. Her ek kararın oyuncunun bildiği koşulları ve anlaşılır karşılığı olmalı.
- Yanlış belge ile kasıtlı dolandırıcılık ayrı olabilir. Kanıtı yetmeyen kişiyi
  alıkoymak otomatik 'tek doğru' olarak tasarlanmasın.
- Doğrudan müşteri tepkisi, daha sonra gelen kısa sonuç ve gün sonu denetimi.
- Denetim her hatayı belge alanı ve görünür kuralla açıklasın; gizli gerçeğe bakıp
  oyuncuya bilgisi dışında ceza yazmasın.
- Geri gelen birkaç müşteri önceki kararı hatırlasın; büyük dallanan hikâyeden önce
  üç küçük, elle yazılmış sonuç zinciri.
- Kural değişiklikleri önceden duyurulsun; rutin ve yeni istisnalar dengelensin.
- Zaman baskısı ancak kontrollere alışıldıktan sonra denensin. Sürekli sayaç ASMR
  ve inceleme temposunu bozuyorsa sakin mod veya daha geniş zaman penceresi kullan.

**Bitti koşulu:** Oyuncu hatasının nedenini ve seçeneğinin sonucunu açıklayabilir;
tekrar oynama yalnızca kusursuz puan almaya değil başka vaka/kararı görmeye dayanır.

### Aşama 7 — Büyük oyuna geri bağlama kapısı (P2)

Erzak taşıma ve yarı açık dünya şu anda geliştirme hedefi değildir. Yeniden
bağlanmadan önce masa kontrolü, inceleme, temas ve 10–15 dakikalık oturum en az
iki test/düzeltme turu görmeli. Aynı ana kontrol sorunları tekrarlanıyorsa kapı kapalı.

Sonra yalnızca küçük bir entegrasyon: belge tamamlanır, odadan tek ürün alınır,
tezgâha getirilir ve teslim edilir. Yürüme/arama gerçekten anlamlı seçim veya
tempo değişimi yaratıyor mu ölçülür. Her müşteri için aynı koridoru yürümek süre
uzatıyorsa düzen değişir; geniş dünya ekleyerek bu sorun büyütülmez.

## 6. Teknik işler — oyuncu ihtiyacına bağlı

- Ortak FPS dosyasındaki etkileşim durumlarını tek bir açık durum modeli etrafında
  toparla: serbest, teslim, masa, elde inceleme, araç teması, bırakma, iade.
  Birbirinden bağımsız bayrakların çelişmesi geçiş denetimleriyle engellensin.
- Kamera, belge taşıma, damga, kesme ve müşteri sunumunu küçük sorumluluklara ayır.
  Bütün sistemi bir seferde baştan yazma. Her ayırma mevcut davranışı korusun.
- Kalıcı veri: belge alanı, mürekkep, fiziksel hasar, kopmuş bölge, işlem kararı.
  Bunlar aynı kavram veya tek bir 'tamamlandı' bayrağı olmasın.
- Kanıt üretimi/doğrulaması tek güvenilir tanıma dayansın. Oyuncuya cevabı veren
  görsel kodlarla içerik üreticisinin doğrulama verisini karıştırma.
- Temas olayından animasyon/foley/baskı tetikle; tek olay bir kez işlensin.
- Optik viewport, canlı kesik maskesi ve baskı güncellemelerini hedef donanımda
  profille. '60 FPS' ölçülmeden yazılmasın; hedef cihaz ve frame-time seçilsin.
- Uzun oturumda biriken kupon/iz, duraklatma, farklı çözünürlük, düşük FPS,
  farklı fare hassasiyeti ve kayıt dönüşümü kontrol edilsin.
- Tam dünya kaydı/yüklemesi ayrıca uygulanır; yeni belgenin durumunu başka karttan
  miras alma, kopya kupon ve iki kez denetim kaydı regresyonları korunsun.

## 7. Küçük ekip çalışma düzeni — öneri

Bu bölüm görev önerisidir; ajanlar otomatik olarak çalıştırılmış değildir.

| Sorumluluk | Önerilen sahip | Teslimat |
| --- | --- | --- |
| Ürün hedefi ve karar | Kullanıcı | Bir sonraki aşamanın kabulü, oynanış geri bildirimi |
| Etkileşim durumları, kesim/damga mantığı, entegrasyon | Codex | Küçük oynanabilir değişiklik, uygun regresyon ve kayıt |
| Kanıt/vaka tasarımı, alternatif kontrol taslağı | Claude | Kurallı vaka seti, istisna/karşı örnek ve ayrı dosyada prototip |
| Gerçek malzeme referansı, animasyon/varlık ve bağımsız oyun testi | Ekip arkadaşı, becerisine göre | Yakın plan varlık/temas çalışması veya ekran kayıtlı test |

Bir araç diğerinden daha uygun çıkarsa sahip değişebilir. Esas kural: aynı dosyayı
aynı anda iki kişi/ajan düzenlemez. Özellikle `fps_kiosk.gd` tek sahibinde kalır;
diğer katkılar ayrı dosya/varlık veya içerik seti olarak gelir. Her görevde şu
alanlar yazılır: oyuncu sorunu, kapsam, sahibi, dosya sınırı, somut teslimat,
kabul kontrolü ve henüz doğrulanmayan nokta.

Günlük ritim: küçük oynanabilir değişiklik → kısa oynama/kayıt → bulgular →
gerekli düzeltme → ortak dala entegrasyon. Birleştirmeden önce güncel dal/diff
okunur; eski dosyanın tamamını yeni diye üstüne yazmak yok.

## 8. İlk iş paketi

Aşağıdaki sırayı öneriyorum; bunlar henüz yapılmış değişiklik değildir.

1. Üç vaka ve yeni oyuncu test kaydı: kontrol mü, kanıt mı, tekrar mı sorun çıkarıyor?
2. Masada doğrudan kart hareketi ve daha tutarlı araç al/bırak akışı.
3. Bir kartta üç anlamlı kanıt: normal bakış, eğme ve büyüteç farklı bilgi sağlasın.
4. Bir damganın kavrama–temas–kaldırma hareketini ve sesini bitir.
5. Dış kenardaki kupon ile mevcut dört kenarlı kesimi karşılaştır; ölçülü kalıcı hasarı koru.
6. Bir müşteri için kısa karar tepkisi ve açıklanabilir denetim sonucu.
7. Aynı kişiyle birkaç tekrar, sonra yeni oyuncuyla yeniden test.

Bu paket başarılı olmadan yeni meslekler, UV lambası, uzun diyaloglar, rüşvet,
para üstü, genel kâğıt fiziği veya yeni oda eklenmez. İlk hedef tek müşterinin
bütün etkileşiminde belirgin kalite; ardından artan vaka çeşitliliği.
