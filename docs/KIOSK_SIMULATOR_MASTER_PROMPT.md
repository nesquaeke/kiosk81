# Kiosk Simulator — ortak master prompt

Güncel kapsam düzeltmesi: oyun hareket edilen birinci şahıs 3D'dir. Bu belge
ilk ürün prototipinin kaydıdır; sabit kamera önerisi artık ana oyun yönü
değildir. Yeni geliştirmede [FPS karne tasarımını](RATION_DESK_DESIGN.md) esas
al; nesneler elde veya gerçek 3D yüzeylerde incelenir, ayrı masa ekranı açılmaz.

Bu belge, kullanıcı isteğine göre Codex, Claude ve ekip arkadaşının aynı kapsamla
çalışması içindir. Mevcut anlatı prototipini koru; ilk aşamada kiosk işletme
mekaniklerini ayrı ve doğrudan oynanabilir bir sahnede geliştir.

## Amaç

1980'lerin Varşova'sındaki Ruch kiosku için basit Godot 4.7.2 / tipli GDScript
modelleri ve somut bir satış döngüsü oluştur. Öncelik görsel kalite değil,
ürünün depodan alınması, tezgâha yerleştirilmesi, tekrar alınması, müşteriye
hazırlanması ve satılmasıdır. Harici eklenti veya Blender gerekmesin.

## İlk ürün seçkisi

Trybuna Ludu ve Żołnierz Wolności gazeteleri, Przekrój dergisi, kibrit,
otobüs/tramvay bileti, zarf, sabun, ayakkabı bağı, jilet paketi, kurşun kalem,
defter ve ambalajlı sert şeker. Bunlar yasal ürünlerden oluşan prototip
seçkisidir. Günlük bulunabilirlik, marka/ambalaj, gramaj, fiyat ve özellikle
gıda tedarik kuralları tarihsel kaynaklarla ayrıca doğrulanmalıdır. Yeni
markalar uydurma; fiyatları geçici olarak işaretle. Kiosku manav veya kasaba
çevirme. Sigara yasal olsa da karne denetimi ayrı bir sonraki görevdir.
Yeraltı yayınları, kaçak ticaret ve karaborsa bu sahnenin ürünleri değildir.

## Etkileşim sözleşmesi

- Her ürüne ait görünür model ve ad olsun; küçük nesnelerin tıklama alanı
  kolay seçilebilsin. Sabit ilk şahıs kamera tezgâhı ve depoyu göstersin.
- Bir defada yalnızca bir ürün tutulabilir. Depoya tıkla: bir adet al.
- Tezgâhta dolu yere tıkla: ürünü al. Boş yere tıkla: tuttuğun ürünü yerleştir.
  Dolu yere ikinci ürün yerleştirilemez; stok kaybolmaz veya çoğalmaz.
- Elindeki ürünü kendi depo kutusuna geri bırakabil. Başka ürünün depo kutusu
  kabul etmesin. Sağ tık/Esc ürünü geldiği yere geri koysun.
- Satış tablasına tıkla: elindekini satış için bırak. El boşsa tabladakini
  geri alabil. Tabladaki ürün otomatik satılmasın.
- Müşteri istediği ürünü açıkça söylesin. “Satışı tamamla” düğmesi yalnızca
  doğru ürün hazırlanmışsa çalışsın. Yanlış ürün satılmasın.
- Satış atomik olsun: ürün azalır, para kasaya girer, deftere tek kayıt
  düşer, sıradaki müşteri gelir. Çift tıklama çift satış yaratmasın.
- Kısa müşteri sırası bitince satış adedi ve ciro gösterilsin; yeniden
  başlatma açık bir eylem olsun. Para üstü, pazarlık, karne, günler arası
  kampanya ve siyasi kararlar sonraki görevlerdir.

## Mimari ve ekip düzeni

Ürün/fiyat verisi ContentDB'de; işlem kuralları ayrı saf sistemde;
CampaignState tek gerçek durum; değişikliklerin sahibi Game olsun.
Tezgâh yerleri, eldeki ürün ve hazırlanmış satış kayıt/yüklemede korunabilsin.
Sahne stok veya parayı kendi başına değiştirmesin. Yeni ürünler mevcut
prototipin başlangıç stoklarını veya denge hesaplarını değiştirmesin.

Görev sahibi dosya kapsamını bildirsin. Aynı dosyaya iki kişi aynı anda
değişiklik yapmasın. Her teslimde değişen dosyaları, çalıştırılan kontrolleri
ve kalan işleri belirt. Kullanıcı oynanışı değerlendirir; görev dağılımı
kişilerin tercihine göre yapılır, Claude'a veya ekip arkadaşına bu belge
dışında kendiliğinden mesaj gönderilmez.

## Kabul ölçütleri

1. On iki ürünün ayırt edilebilir basit Godot modeli bulunur.
2. Depo → el → tezgâh → el → satış tablası → satış döngüsü çalışır.
3. Alma/geri bırakma para değiştirmez; toplam satılmamış stok korunur.
4. Yanlış ürün, boş depo, dolu el/yer ve tekrarlanan satış güvenli reddedilir.
5. Doğru satış stok, kasa ve defteri birlikte günceller.
6. Durum kopyası/kayıt döngüsü yerleşimi korur.
7. Var olan testler ve yeni işlem testleri geçer; sahne etkileşim kontrolü
   modelleri, ışınla seçimi ve satış döngüsünü gerçek sahnede sınar.

## Çalışma sırası

Ürün verisi ve modeller → stok/yerleşim kuralları → tıklama ve satış alanı →
müşteri sırası ve sonuç → testler → kullanıcı oynanış değerlendirmesi.
Sonrasında çok ürünlü sipariş, para üstü, karne ve gün sonu eklenir.
