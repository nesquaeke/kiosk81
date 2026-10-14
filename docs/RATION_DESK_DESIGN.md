# Karne masası — ana mekanik ve ortak geliştirme belgesi

## Tasarım kararı ve yetki

14 Ekim 2026: Kullanıcı, belge inceleme + dükkân işletme + zor kararlar fikrini
oyunun en önemli mekaniği olarak seçti. Tarihsel atmosfer korunacak; meslek
kartları, gramajlar, mühürler ve alıkoyma kuralları oyun için tasarlanabilir.
Bu belge Codex, Claude ve ekip arkadaşının ortak referansıdır. Tarihsel bir
mevzuat kaynağı değildir; önceki prototipteki basitleştirilmiş karne de gerçek
1982 belgesi sayılmaz. Bu kapsamda gıda, kurmaca tedarik tezgâhının parçasıdır;
gerçek Ruch kiosklarının et sattığı iddia edilmez.

Kullanıcı özellikle karttan bir bölge kesmenin, damga basmanın ve kâğıtla
çalışmanın ASMR gibi hissedilmesini istedi. Bu ayrıntılar ana oyun döngüsüdür;
sonradan eklenecek görsel süs değildir.

## Temel oyuncu soruları

1. Bu belge gerçek mi?
2. Bu müşteri ne satın alabilir?
3. Ben ne vereceğim, hangi sonuçları göze alacağım?

Satış hakkı, belge gerçekliği, ürünün tedarik yolu ayrı değerlendirilir.
Karne bedava mal veren bir ödeme aracı değildir. Kupon ve para gerekir;
geçerli kart stok garantisi değildir. Meslek kişinin ahlakını belirlemez.

## Ana döngü

Müşteri kartını uzatır → kartı al → yaklaştır/eğ/çevir → ön ve arka yüzü
kitapçıkla karşılaştır → gerekiyorsa açıklama/ek belge iste → karar damgası
bas → ürünü hazırla → uygun kuponu kes → kalan kartla ürünü teslim et veya
kartı alıkoy → sıradaki müşteri → gün sonunda hesap ve karar denetimi.

Görsel kart, müşteri ve tezgâh işlemleri aynı durumdan beslenir. Kartın ön
yüzü işlem sırasında hiçbir zaman başka müşterinin kartına dönüşmez.
Satış stok, para, kupon, günlük kayıt ve müşteri sırasını birlikte günceller.

## İlk oynanabilir dilim

- Tarih: 15 Şubat 1982; kural seti bilerek kurmaca.
- Üç sınıf: işçi, öğretmen, emekli.
- Ön yüzde ad, sınıf, seri, ay ve hak miktarı; arka yüzde kurum kodu,
  onay mührü ve kurcalama izleri.
- Üç ürün hakkı: et, şeker, sabun. Et gram, şeker gram, sabun adet olarak
  hesaplanır. Gramajın stok hesabında kaybolmasına izin verilmez.
- Referans: işçi et hakkı 750 g / kurum F14; öğretmen 500 g / S03;
  emekli 250 g / E02. Her birinde şeker 1000 g ve sabun 1 adet.
- İşlem damgaları: SATIŞ, RET, ALIKOY. Kurum mührü ile satıcının işlem
  damgası farklı görsel ve işlev taşır.
- Kartı sürükleme, büyütme, eğme, ön/arka yüz çevirme.
- Kesme: uygun kuponun üst çizgisi boyunca makası sürükle; kısa veya
  yanlış çizgi kesimi tamamlamaz. Tamamlanan kupon karttan ayrılır.
- Damga: uygun karar alanına basılı tutup bırak; basış/sökülüş hareketi,
  mürekkep izi ve ayrı sesler oluşur. Yanlış kararı sistem otomatik düzeltmez.
- Resmî stok ve sınırlı kayıt dışı et stoğu; oyuncu kaynağı seçer.
- Sekiz karşılaşma: geçerli işçi, yıpranmış öğretmen, eski ay kartı,
  yanlış kurumlu sahte kart, kullanılmış kupon, değiştirilmiş miktar,
  eksik onay ve resmî stok tükenince gelen geçerli müşteri.
- Gün sonunda doğru/yanlış kararlar, ciro ve kayıt dışı işlemler görülür.

İlk dilimde ek belge isteme, çok ürünlü sipariş, teraziyle serbest tartım,
telefonla sorgu, aile üyesi adına alışveriş ve kampanyaya kalıcı ilişki
sonuçları yol haritasındadır; uygulanmış gibi sunulmaz.

## Karar sözleşmesi

| Durum | Kurmaca oyun kuralı |
| --- | --- |
| Geçerli kart, uygun kupon, stok | Satış damgası, ürün hazırlama, kupon kesme, teslim |
| Tarih uygun değil / kupon bitmiş / onay eksik | Ret ve kartı iade |
| Kurum-sınıf çelişkisi / değişmiş hak miktarı | Sahtecilik; alıkoyma |
| Geçerli kart, resmî stok yok | Ret veya oyuncunun seçtiği kayıt dışı tedarik |
| Yanlış alıkoyma | Müşteri şikâyeti ve gün sonu hata |
| Usulsüz onay | Ürün kaybı, denetim riski ve gün sonu hata |

Müşterinin gerçekliğini UI yeşil/kırmızı etiketiyle önceden açıklama.
Eksik mühür, eski tarih ve kullanılmış hak tek başına sahtecilik değildir.
Referans verisi açık, kararın doğruluğu gün sonunda görünür olur.

Ürün hazırlanıp stok uygunluğu doğrulanmadan kupon kesilmez. Kesilmiş kupon
bir kez tüketilir; kart çevrilince veya yeniden alınca geri gelmez. İlk
dilimde hazırlanan ürün, satış tamamlanana kadar ayrılmış bir sipariştir;
iptalde stok düşmez. Tamamlamada miktar yeniden kontrol edilir.

## Dokunsal / ASMR sözleşmesi

| Hareket | Görsel davranış | Ses ve ritim |
| --- | --- | --- |
| Kartı alma | Kâğıt hafif yükselir, gölge açılır, ağırlıklı eğim | Kısa lifli kâğıt sürtünmesi |
| Sürükleme | Konum fareyi takip eder; eğim hareket hızından yumuşak etkilenir | Sürekli yüksek gürültü yerine seyrek hafif temas |
| Çevirme | Yüz daralır, ters yüz açılır; araç işlemleri kilitlenir | İnce kâğıt bükülmesi |
| Yaklaştırma | Yumuşak ölçek geçişi, okunabilir metin | Gereksiz UI bip sesi yok |
| Damga | Aşağı basış → kısa temas → kaldırma; hafif değişken iz | Tok düşük temas ve kısa mürekkep/pad ayrılma sesi |
| Kesme | Çizgi üzerinde ilerleme; makas ağızları ritmik kapanır | Aralıklı metal tık + kâğıt kesilmesi |
| Kupon ayrılması | Parça kopar, hafif döner, kupon kutusuna iner | Hafif düşme ve kâğıt teması |
| İade | Kart müşteri bölgesine kayar | Yumuşak masa sürtünmesi |
| Alıkoyma | Kart dosya bölmesine girer | Kâğıt ve çekmece teması |

Sesler yakın, kısa ve dinamik olmalı. Başarı/hata jingle'ı kâğıt sesini
örtmemeli. Ses seviyesi kontrolü ve sessiz oynama mümkün olmalı; bütün
işlemler ses olmadan da görülebilmeli. İlk sesler projede üretilen özgün
prosedürel prototiplerdir; gerçek kâğıt/makas/damga kayıtları sonraki kalite
adımıdır. “ASMR kalitesi tamamlandı” iddiası kullanıcı dinlemeden yapılmaz.

Animasyon temas anıyla eşlenir. Yeniden başlatma/sahne değişimi sürmekte olan
işlemleri iptal eder; eski müşteri için bekleyen callback yeni kartı kesmez.
Çift tıklama veya aynı kuponun tekrar kesilmesi çift satış yaratmaz.

## Erişilebilirlik ve öğrenme

Kartı çevirme için F, yakınlaştırma için tekerlek, eğme için Q/E; bütün
kritik işlemler görünür araçlarla da yapılabilir. Küçük kuponlar büyütülür.
Sınıf farkları yalnızca renkle anlatılmaz; başlık ve simge de bulunur.
İlk dilimde süre baskısı yoktur. Referans kitapçığı her an açık kalır.
Kesme toleransı fare titremesine izin verir; mikro hassasiyet gerektirmez.
Mekanik zorluk, açık görsel bilginin okunmasından doğar.

## Mimari

- `content/ration/`: müşteri/kart verisi, tarihsel iddia taşımayan senaryo.
- `RationDeskRules`: saf kararlar ve miktar hesabı; UI'yi tanımaz.
- `Game` / `CampaignState`: işlemleri atomik uygular; masa durumu flags
  üzerinden kayıt/kopyalama yolundan geçer.
- `RationCardView`: kartın çizimi, sürükleme, yüz çevirme ve kesme girdisi.
- `RationDesk`: araçlar, tezgâh, referans, müşteri akışı ve animasyonlar.
- `RationFoley`: kâğıt, makas ve damga seslerinin çalınması.

Mevcut ürün simülatörü ve anlatı prototipi erişilebilir kalır. Yeni ana sahne
karne masasıdır. Sahne geçişleri ayrı demo günlerini başlatır; ilk dilimde
tek kampanyanın devamı oldukları varsayılmaz.

## Kabul ölçütleri

1. Ön/arka yüz aynı fiziksel kartta; kimlik ve kurcalama izleri okunabilir.
2. Gerçek fare girdisiyle alma, sürükleme, çevirme, damga ve kesme çalışır.
3. Kısa kesim kupon tüketmez; tamamlanan kesim yalnızca bir kez tüketir.
4. Damga basış ve kaldırma sesleri temas anlarında tetiklenir.
5. Stok yoksa ürün hazırlanamaz ve kupon kesilemez.
6. Sahte karta yanlış karar verilebilir; bu gün sonunda değerlendirilir.
7. Eksik/eskimiş belge, sahte belgeden ayrı değerlendirilir.
8. Kayıt dışı stok resmî stoktan ayrı azalır; risk ve gelir ayrı kaydedilir.
9. Çift tamamlamada stok/para/kayıt tekrar değişmez.
10. Masa durumu JSON kayıt/kopyasında korunur.
11. Var olan testler, yeni kural testleri ve gerçek sahne kontrolleri geçer.

## Sonraki geliştirme sırası

1. Kullanıcının oynayıp kesme toleransı, okunabilirlik ve sesleri değerlendirmesi.
2. Gerçek foley kayıtları; farklı kâğıt kalınlığı ve makas hareketleri.
3. İki alanı işaretleyip çelişki sorma ve ek belge uzatma.
4. Aile adına alışveriş, yeni kart sınıfları ve birden fazla ürün talebi.
5. Fiziksel terazi, para üstü ve müşteriye tek tek teslim.
6. Günler arası güven, aile ihtiyacı, denetim ve tanıdık müşteriler.
7. İçerik editörü; rastlantısal ama çözülebilir sahtecilikler.

Her görev için tek dosya sahibi, kabul ölçütü ve test sonucu kaydedilir.
Bu belge kapsam kararlarını korur; uygulama durumu README'de güncellenir.

## İlk uygulamanın doğrulanmış durumu

Godot 4.7.2 ile 163 test geçti. Ürün simülatörünün 12 model / 25 ışın hedefi
kontrolü de geçti. Karne masası hem headless hem pencereli OpenGL yazılım
çizicisinde gerçek fare/klavye olaylarıyla doğrulandı: sekiz müşteri, kısa
kesimin reddi, tam kesim, damga, ön/arka yüz, sürükleyerek iade/alıkoyma,
gün sonu denetimi ve çevirme sırasında yeniden başlatma.

Ses dosyalarının dalga biçimleri sıfır olmayan, kırpılmayan çıkış açısından
kontrol edildi; temas olaylarının doğru tetiklenmesi sahnede doğrulandı.
Sanal görüntü kontrolünde ses sürücüsü Dummy idi; duyusal kalite ve gerçek
ses aygıtında dinleme kullanıcı değerlendirmesini bekliyor.

![Kartın ön yüzü ve referans defteri](images/ration-front.png)

![Arka yüzde kurum kodu ve mühür](images/ration-back.png)

![Kesilmiş kupon ve satış damgası](images/ration-cut.png)
