# KIOSK '81 — karne inceleme masası: güncel master prompt

Bu belgenin tamamı Claude, Codex veya ekip arkadaşına bağımsız görev olarak
verilebilir. Kullanıcının son talimatı önceliklidir. Bu metin hedef ve kabul
sözleşmesidir; burada bir özellik bulunması, uygulanıp test edildiği anlamına gelmez.
Uygulama durumu [tasarım belgesinde](RATION_DESK_DESIGN.md), gerçekten çalıştırılan
kontroller ise tarihli [kabul raporunda](RATION_FPS_ACCEPTANCE.md) tutulur.

## 1. Şimdiki görev ve kapsam

Godot 4.7.2 ile geliştirilen KIOSK '81'de yalnızca şu etkileşimi çok iyi yap:

**Müşteri karneyi uzatır → oyuncu E ile ele alır → F ile yakından döndürüp
inceler → E/G ile masaya koyar → üstten çalışıp damga basar / kupon keser →
karneyi iade eder veya alıkoyar.**

Kullanıcı bu ana mekanik sıradan, ucuz görünen ve sıkıcı bir deneme olarak
kalmamalı diyor. Kaliteyi yeni odalar, dekor listeleri veya ek sistemlerle
ikame etme. Oynanabilirlik, okunabilirlik, merak, fiziksel temas ve kontrol
üzerinde çalış. AAA oyunlarındaki tutarlılık ve özeni hedefle; prosedürel bir
prototipi bitmiş AAA sanat/animasyon/ASMR üretimi olarak sunma.

**Bu görevde erzak toplama, ürün taşıma, stok düşme, ödeme, ekonomi veya oda
büyütme yok.** Önceden kabul edilmiş tam satış fikri silinmedi; bölüm 12'de
gelecek entegrasyon olarak korunur. Oyuncuyu mevcut belge döngüsünü bitirmek
için raflara gitmeye zorlama.

Repo: `https://github.com/nesquaeke/kiosk81`. İşe başlamadan gerçek dizini,
aktif dalı, `git status` ve `AGENTS.md` talimatını kontrol et. Başka geliştiricilerin
çalışmasını koru; dalın veya dosyaların önceki konuşmadaki gibi kaldığını varsayma.

## 2. Sahne ve kamera sözleşmesi

Ana sahne `scenes/kiosk/ration_desk_focus.tscn`; ortak `fps_kiosk.gd` üzerinde
`document_focus = true` kullanır. Eski ürün/satış deneyi `fps_kiosk.tscn` içinde
ayrı korunur. `ration_desk.tscn` eski 2D denemedir; ana akışa geri alınmaz.

Dünya, kâğıt, damga, makas ve inceleme araçları 3D nesnelerdir. Pencereye
birinci şahıs yaklaşılır; eldeki kâğıt karakterin görüşünde tutulur. Masada
çalışmaya girince **aynı Camera3D fiziksel masanın üstüne taşınabilir**. Görünen
imleç, sağ tuşla kaydırma ve tekerlekle yakınlaşma bu yeni masa modunun parçasıdır.
Önceki “kamera karakterin gözünden hiç ayrılamaz” kuralı bu etkileşimi engellemez.

Bu, tam ekran bir belge paneline geçiş değildir: yazılar aynı 3D kâğıtta,
araçlar aynı masa üzerindedir. Control/SubViewport kâğıdın baskısını veya
büyütecin optik görüntüsünü üretebilir; oyuncuya bir dashboard açmaz.

Çıkışta kamera baş düğümüne, önceki bakışına ve FOV'una döner. Q/WASD hareketi
geri verir. Erken kaydırma/yakınlaştırma veya odak kaybı kamerayı yarım geçişte
bırakmamalıdır. Pan/zoom sınırları masa üstündeki işi erişilebilir tutar;
araçlar ekrandan kaybolduğunda oyuncunun onları bulabileceği anlaşılır olmalıdır.

## 3. Tamamlanacak tek müşteri döngüsü

1. Müşteri dışarıdan kartını uzatır ve kısa bir talep söyler.
2. Oyuncu erişim içindeki karta E/tek tık ile etkileşir. Aynı fiziksel kart ele
   alınır. Elde F yakın incelemeyi açar: sol sürükle döndürür, tekerlek zoomlar,
   sağ tık çevirir, R düzeltir; F/Esc/Q/WASD önceki tutuşa döner.
   Masaya bakarken fiziksel çerçeve yerleştirilecek yeri gösterir. E/G bırakır;
   kart masaya oturunca aynı kamera otomatik üstten çalışma açısına geçer.
3. Oyuncu hemen uzaklaşabilir. Konuşmadan çıkmak ret kararı veya işlem sıfırlama değildir.
4. Masadaki karta E ile etkileşip üstten çalışma açısına gelir; imleçle inceler.
5. Ön/arka yüzü çevirir; tarih, sınıf, kurum, hak ve müdahale izlerini karşılaştırır.
   Kural/kurum örneği aynı masada fiziksel olarak görülebilir; optik büyüteç küçük
   baskı ve yama incelemesine yardım eder.
6. İsterse R ile kâğıdı ele alır, F ile yakından inceleyip çıkışta E/G ile tekrar
   masaya bırakır. Masada F kâğıdı çevirir.
7. Karar aracını fiziksel olarak alır: SATIŞ, RET veya ALIKOY. Hedefe götürür,
   indirir, bastırır, kaldırır. Damga hareketinin niteliği mürekkepte görülebilir.
8. SATIŞ kararında gereken kuponun dört kenarını keser; kısa kesikler ve devamları
   gerçek hasar olarak kalır. RET/ALIKOY bu satış adımını atlar.
9. Aracı uygun boş yere bırakır. Karneyi müşteriye iade eder veya alıkoyma
   bölmesine koyar; **belge incelemesi burada tamamlanır**.
10. Tek bir sonuç kaydı oluşur. Sonraki müşteri çağrılabilir; oyuncu serbesttir.

Bu odak modunda paket hazırlama veya ürün teslimi tamamlama önkoşulu değildir.
Stok ve ödeme değişmez. Yanlış belge kararı verilebilir ve ayrıca değerlendirilir.
Müşteri isteği kısa tekrar etkileşimi veya dünyadaki fişten hatırlanabilir;
sürekli açık ekran sipariş paneli oluşturma.

## 4. Kanıta dayalı inceleme

Tarihsel atmosfer komünist dönem Polonya'sıdır. Sınıflar, kurumlar, kotalar ve
yaptırımlar oyun için sadeleştirilebilir; tarihsel simülasyon doğruluğu zorunlu değil.
Meslek, yıpranma veya müşterinin tavrı tek başına sahtecilik cevabı değildir.

İlk karşılaştırma seti işçi, öğretmen ve emekli kartlarını kapsasın. Her sınıfta
okunabilir kurum/kota bilgisi ve karşılaştırılacak fiziksel başvuru bulunsun.

| İncelenen alan | Oyuncunun aradığı kanıt |
| --- | --- |
| Ay / yıl | Görünür işlem tarihiyle geçerlilik |
| Sınıf / kurum kodu | Başvuru belgesindeki eşleşme |
| Ürün hakkı / kupon | Sınıf kotası, miktar ve kullanılabilirlik |
| Arka yüz onayı | Kurum mührü, eksiklik veya tutarsızlık |
| Yama / silinti / üst baskı | Değiştirilmiş hak veya kâğıda müdahale |
| Aşınma / kat izi | Tek başına suç sayılmayan normal kullanım |
| Satıcı damgaları | Oyuncunun yaptığı kalıcı işlem |

Ad ve seri basılı olabilir; kimlik belgesi veya seri kayıt sistemi uygulanmadan
bunları otomatik veri tabanı denetimi varmış gibi kullanma. Kartın kendi
alanları, fiziksel başvuru ve görünür müdahale izleri ilk dilim için yeterlidir.

**İnceleme oyun olsun:** geçerli ama yıpranmış kâğıt ile sahte kota yamasını
ayırt etmek için çevirmek, yakın bakmak ve başvuruya dönmek anlamlı olmalıdır.
Aynı kararı sekiz kez ezberletmek yerine farklı kanıt durumları sun.
Fiziksel sınıf/kurum örnekleri kâğıdın yanında karşılaştırılabilsin. Büyüteç
altındaki gerçek baskıyı büyütsün; “doğru/sahte” rozeti, yeşil/kırmızı vurgu veya
cevabı veren ses üretmesin. Kamera, cam ve büyütülen alan birbiriyle hizalansın;
büyütecin kendi kendini yeniden görüntülediği bir optik döngü oluşmasın.

Kullanıcı yanlış SATIŞ, RET veya ALIKOY kararı verebilir. Sistem sırf belgenin
sahte olduğunu bildiği için damgayı engelleyip cevabı açığa çıkarmaz. Kuralların
kullanım ve miktar önkoşulları ile gizli sahtecilik değerlendirmesini ayır.

## 5. Kâğıt ve tutma

Karne tek nesnedir; müşteri, masa, el ve belge bölmesi arasında yer değiştirir.
Ön ve arka yüz aynı kâğıdın iki yüzüdür. Çevirme gerçekten ters yüzü göstermeli;
sadece bir durum bayrağını değiştirip ön yüzü masada döndürmemelidir.
Masa üzerinde çevirirken kenarlar yüzeyin içinden geçmesin.

Elde kavrama önemli metni örtmez; arka yüz çevrilince el anlamsız tarafa geçmez.
Masaya bırakma kâğıdı yüzeyde bırakır. Kartı ele almak, çevirmek veya masadan
ayrılmak baskıyı, mürekkebi, kesik yollarını ve ayrılan kuponu sıfırlamaz.
Yazı, etkileşim koordinatı ve gerçek yüzey aynı yerde olmalıdır.

## 6. Gerçek uzunlukta kesme

Makas bir ilerleme çubuğunu çalıştıran düğme değildir. Sol tuşla keserken uç
kâğıt üzerinde ilerler; ağızlar ve ses gerçek hareketi destekler. Metre/cm ölçeği
korunur: **oyuncu 2 cm keserse 2 cm kesik kalır**.

- Tuşu bırakmak/Q, yapılmış kesikleri iyileştirmez. Yarım kesik kâğıtta hasardır.
- Ön/arka yüz, kesik kenarı ve gölge aynı hasarı göstermelidir.
- Hızlı bir fare atlaması bütün yolu anında kesmez; makas ucu fiziksel olarak yetişir.
- Kısmi yarık, bütün kuponu silmez veya hakkı tüketmez.
- Kupon ancak dört kenarı ayrıldığında tek fiziksel parça olarak kopar.
- Önceki kesiklere devam edilebilir. Dört kenarı tek basışta çizme şartı koyma.
- Ayrılan parça aynı kartın baskısını taşır; boşluk iki yüzden de görülür.
- Kesik kaydı, ayrılan parça ve kullanılan hak tekilleştirilir; tekrar kesmek
  yeni kupon, hak veya sonuç üretemez.
- Ürün hazırlama veya taşıma bu kesimin önkoşulu değildir.

Kâğıda fiziksel hasar vermek ile satış kuponunun mantıksal işlenmesi ayrı
konulardır. Eski “kısa veya çizgi dışı hareket iptal edilince kâğıt eski haline döner”
kuralını geri getirme. Henüz sonsuz yırtılma/serbest kumaş simülasyonu varmış gibi
konuşma; uygulanan geometri ve kesim sınırlarını açık tut.

## 7. Damganın baskı hissi

Araç seçim menüsünden spawn edilmez; masadan alınır, tutulur ve yerine bırakılır.
İmleç kâğıtta hedefi belirler. Sol tuş basılıyken aşağı fare hareketi damgayı
indirir; beklemek ve basınç mürekkebin işlemesini değiştirir. Hızlı ve yavaş
baskı aynı kusursuz sabit etiketi üretmemelidir. Açı ve yanal hareket lekeyi etkiler.

1. Yaklaşma: henüz iz yok.
2. İlk fiziksel temas: tek baskı sesi ve tek kalıcı mürekkep izi.
3. Bekleme/basınç/sürüklenme: aynı izin niteliği güncellenir.
4. Kaldırma veya temastan sonra ayrılma: iz korunur, bir kaldırma sesi çalar.

Temastan önce çıkılırsa iz oluşmaz. Temastan sonra Q/Esc ile ayrılmak izi silmez.
Mürekkep kâğıda bağlıdır; ele alınınca veya çevrilince konumu/açısı değişmez.
Küçük görsel çeşitlilik deterministik tutulabilir; aynı kayıt her karede yeni
rastgele bir damga üretmesin. Damga dokusu sahtecilik cevabı değildir.

## 8. Kontroller ve araç düzeni

| Durum / girdi | Beklenen davranış |
| --- | --- |
| Serbest WASD / fare / Shift | Yürü / bak / hızlı yürü |
| E / tek tık, uzatılan karne | Aynı fiziksel karneyi ele al |
| E, masadaki karne | Üstten 3D masa çalışma açısına geç |
| Masada sağ tuş + sürükleme | Masayı kaydır |
| Masada tekerlek | Yaklaş / uzaklaş |
| R | Bakılan masadaki karneyi ele al |
| Elde F | Nesneyi yakından incelemeye gir/çık |
| İncelemede sol sürükle / tekerlek | Serbestçe döndür / sınırlı zoom |
| İncelemede sağ tık / R | Ters yüz / okunaklı başlangıç duruşu |
| İncelemede Esc / Q / WASD | Önceki tutuşa dön; hareketi geri ver |
| Masada F | Kâğıdı fiziksel olarak ters yüz et |
| E, masadaki araç | Uygun eli boşsa al |
| G, uygun yüzey | Tutulan nesneyi bırak |
| Damga: sol tut + fare aşağı | İndir / bastır; bırakınca kaldır |
| Damga: Shift + tekerlek | Açıyı değiştir |
| Makas: sol tut + sürükle | Gerçek kesik oluştur; bırakınca yapılan hasarı koru |
| Q veya masadayken WASD | Masa/araç etkileşiminden ayrıl |
| E, müşteri / belge bölmesi | Eldeki karneyi uygun yere teslim et |
| Esc / odak kaybı | Kontrolü güvenle bırak ve duraklat |

Yeni fiziksel başvuru/büyüteç bağlanınca kontroller ve ipuçları birlikte güncellenir.
Araçlar anlaşılır, birbirini örtmeyen yerlerde dursun. Bırakma hareketi masaya
ulaşsın; bir aracın üstüne yığıp sonraki müşteride diğerini alınamaz hale getirmesin.
Her engelin kısa bir nedeni gösterilebilir; başarısız eylem sessizce kaybolmasın.

## 9. Serbest ayrılma ve güvenilirlik

Konuşma, belgeyi ele alma veya masa modu kalıcı hareket/fare kilidi oluşturamaz.
Q, yürümek, Esc, odak kaybı ve yeniden başlatma ayrı ayrı sınanır.
Tamamlanmamış damga hareketi iz bırakmaz; tamamlanmış temas korunur.
Makasla yapılmış fiziksel kesik de korunur; bütün yarım eylemleri tek tip geri alma.

- Game/CampaignState yetkili durumdur; kurallar etkiler döndürür.
- Dünya konumu, çarpışma, görünürlük ve elde tutma aynı durumu anlatır.
- Tek kart ve tek ayrılan kupon korunur; her karede nesne yeniden yaratılmaz.
- Bırakma animasyonu sırasında restart, araç çarpışmasını kapalı bırakamaz.
- Eski tween/callback yeni müşterinin kâğıdını değiştiremez.
- Aynı belgeyi ikinci kez teslim etmek yeni sonuç veya hak oluşturmaz.
- Odak modu stok/ödeme katmanını çağırmadan belge incelemesini tamamlar.
- Mantıksal kayıt dönüşümü kesik/iz bilgisini korur; tam dünya kayıt/yüklemesi
  ayrıca uygulanmadıysa varmış gibi sunulmaz.

Ses basılan tuşta değil gerçek olayda çalsın: kâğıt yüzeye temas ederken,
makas kapandıkça, damga kâğıda değince. Başarı/hata melodileri temas sesini
örtmesin. Ses seviyesi ayarlansın; Dummy aygıtta test etmek gerçek dinleme değildir.

## 10. Zorunlu kabul senaryoları

Bunlar hedeflerdir; kutuların listelenmesi testlerin geçtiği anlamına gelmez.

- [ ] Müşteriden aynı fiziksel kart alınır, masaya yerleşir; uzaklaşınca masada kalır.
- [ ] Konuşmadan/masadan ayrılma ve geri dönme müşteri/karne durumunu korur.
- [ ] Üstten moda aynı kamera geçer; Q/WASD bakış, FOV, ebeveyn ve yürüyüşü geri verir.
- [ ] Pan/zoom erken kullanıldığında kamera yarım geçişte veya yanlış ölçekte kalmaz.
- [ ] Araçlar gerçek pencere içinde görülüp imleçle seçilir; offscreen test koordinatı kullanılmaz.
- [ ] Ön/arka yüz fiziksel olarak görünür; metin, mühür ve yama yakından okunabilir.
- [ ] Fiziksel kaynak/büyüteç baskıyı karşılaştırmaya yardım eder, cevabı söylemez.
- [ ] Yıpranmış-geçerli, eski ay, eksik onay, yanlış kurum ve değişmiş hak ayırt edilebilir.
- [ ] Oyuncu yanlış karar verebilir ve değerlendirmesi ayrıca kaydedilir.
- [ ] Ölçülen 2 cm kesik bütün kuponu yok etmez ve bırakınca/Q'da kaybolmaz.
- [ ] Çevirme/ele alma/geri dönme ve kayıt dönüşümü kısmi hasarı korur.
- [ ] Dört kenar ayrıldığında bir parça kopar; iki yüzde boşluk ve aynı parçada baskı vardır.
- [ ] Hız/bekleme/basınç farklı iz üretir; tek temas tekrar tekrar damga eklemez.
- [ ] Damga öncesi iptal izsizdir; temas sonrası çıkış mevcut izi ve tek kaldırma sesini korur.
- [ ] Araç bırakmak başka aracı kilitlemez; drop/restart sonrası araç tekrar alınabilir.
- [ ] Odak döngüsü ürün/paket gerektirmeden iade/alıkoyma ile biter; stok ve para değişmez.
- [ ] Tekrar teslim/yeniden başlatma çift hak, sonuç veya eski callback üretmez.
- [ ] Pencereli gerçek girdilerle okunabilirlik, imleç ve büyüteç görüntüsü kontrol edilmiştir.

Doğrulama komutları, repo kökünden:

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest
godot --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest --capture=/tmp/ration-focus-shots
```

Godot 4.7.2 standard/typed GDScript kullan; sistem binary'si farklıysa projenin
sabitlenmiş motorunu seç. Çıkış koduyla birlikte testlerin çalıştığını ve hata
çıktılarını kontrol et. Fixture konumları kullanıldıysa bütün yürüyüş rotasının
otomatik oynandığını iddia etme. Eski test sayısını yeni çalışmaya kopyalama.
Paylaşılan tam satış yolu değişirse onun ayrı selftest'ini de kontrol et;
onun başarılı olması odak sahnesinin kanıtı yerine geçmez.

## 11. Ekip ve teslimat

Önce çalışan mevcut akışı oku; gereksiz yere motor, sahne veya kural katmanını
yeniden yazma. Aynı dosyada Claude/Codex/insan çalışacaksa sahipliği paylaş.
Kullanıcı istemedikçe worktree açma. Toplu sahne üreticileri elle yapılmış işi ezebilir.

Kabul raporuna bu sürümde gerçekten değişen davranışı, komutları, sonuçları,
güncel görüntüleri ve açık sınırları yaz. Büyüteç/kaynak gibi bir aracın dosyasının
bulunması, sahnede bağlandığı ve optik olarak doğrulandığı anlamına gelmez.
Bitmiş olan, uygulaması süren ve gelecek hedefi olan işleri ayır.
Onaylanmış olağan düzeltmeleri gereksiz izin sorularıyla durdurma; dış erişim
engeli varsa kod yazmış gibi davranma. Yetki kapsamında çalışılan dala kaydet;
başkasının dalını ezme veya ana dala onaysız birleştirme yapma.

## 12. Korunan gelecek fikirleri — bu göreve ekleme

Büyük oyun 3D ve ileride yarı açık dünyadır. Belge etkileşimi yeterince iyi
olduktan sonra önceki kabul edilen döngü yeniden bağlanabilir: belge işlemleri
önce, sonra odadaki yasal erzakları bulup tezgâha taşıma; resmî veya gizli stoktan
verme konusunda bilinçli seçim; ürün ve kalan kartın tekilleştirilmiş teslimi.
Karne ödeme aracı veya stok garantisi değildir; bu gelecekte de ayrılmalıdır.

Yeni meslekler, aile adına alışveriş, ek kimlik/seri denetimi, çok ürünlü sipariş,
serbest tartım, para üstü, günler arası kampanya ve yarı açık dünya ayrıca ele alınır.
Bunları şimdiki karne masasını bitirmek için zorunlu işlere dönüştürme.

Her değişikliği şu soruyla denetle: **Oyuncu kâğıtta bir kanıtı bulabiliyor mu;
yaptığı küçük fiziksel hareket, kâğıtta ve araçta beklediği sonucu bırakıyor mu?**

## Güncel sıralı uygulama

Kullanıcının onayladığı ayrıntılı görevler: [CARD_INTERACTION_BACKLOG.md](CARD_INTERACTION_BACKLOG.md).
İlk dilim tek tuşla elde inceleme, ikinci dilim damga okunaklılığıdır.
Satıcı karar alanı belirgin basılıdır; alet eldeyken gerçek boy/açıda geçici
izdüşüm görünür. Bu kılavuz kalıcı mürekkebe veya kuponlara işlenmez.
İlk iki müşteride isteğe bağlı hedef yardımı vardır. Alan dışına fiziksel basmak
iz bırakır fakat karar kaydetmez; geçerli karar alanında oyuncu istediği kararı
verebilir. Bunu sahtecilik cevabını engelleyen bir sisteme dönüştürme.
