# Kontrollü makas ve elde kupon toplama

19 Ekim 2026. Bu çalışma [sıralı planın](CARD_INTERACTION_BACKLOG.md)
5. dilimine odaklanır: kuponun sınırını kontrollü kesmek, kesilen parçayı masada
görmek, ele alıp incelemek ve kupon kabına gerçekten bırakmak. Kapsam yine
oda/masa/belge işlemidir. Yeni erzak, satış veya ekonomi sistemi eklenmez.

Denemek için GitHub Desktop'ta `codex/ration-card-desk` dalını seçip Pull
yap; Godot'ta F5 ile ana sahneyi başlat. İlk müşteri geçerli bir et kuponu
getirir ve aşağıdaki bütün akış denenebilir. Yeni belge karşılaştırma gününe
geçmek zorunlu değildir.

## Oyuncunun akışı

Müşterinin uzattığı karneyi E ile alıp masaya bakarak G/E ile bırakırsın.
Aynı kamera masanın üzerine geçer. Makası E ile aldığında kâğıdın kupon
sınırları okunabilir hâle gelir; rehber kalıcı baskı veya otomatik doğruluk
işareti değildir. Hangi kuponun işleneceğine oyuncu karar verir.

Sol tuşu basılı tutup makasın ucunu ilerletirsin. Bıçaklar yalnız kapanış
sırasında kesim üretir. Shift, ince kontrol için hareketi yavaşlatır. Kesik
imlecin bütün yolunu anında doldurmaz: fiziksel uç, bıçağın o anda yapabildiği
kadar ilerler. Köşede belirgin yön değiştirdiğinde uç yerinde durur, makas
açılır ve yeni yöne döner; ardından kesme devam eder.

İki santimetre ilerleyip bırakırsan iki santimetrelik kalıcı kesik kalır.
Masa açısından çıkmak, karneyi ele almak veya arkasına çevirmek bu kesiyi
iyileştirmez. Bir kısa kesi kuponun kalan kenarlarını kendiliğinden ayırmaz.
Dört kenarın bağlantısı kesildiğinde parça bağımsız olur ve masanın üzerine
kısa bir hareketle düşüp yerleşir. Otomatik olarak kupon kabına uçmaz.

Makası yerine bırakıp kupona E ile uzanabilirsin. Parça, ana karnenin basılı
içeriğini, kâğıt kalınlığını, mevcut mürekkebini ve kesiklerini taşır. Q ile
masa açısından ayrılıp F ile aynı küçük kâğıdı yakından inceleyebilirsin:
döndürme, yakınlaşma ve sağ tıkla ön/arka yüz burada da çalışır.

Kuponu boş masaya G ile bırakmak yalnızca bir yer değiştirmedir; hak işleme
ve dosyalama sayılmaz. Tekrar alıp kupon kabına bakarak E/G kullanırsın.
Dosyalama, parçanın kaba temas ettiği anda kaydedilir. İnceleme sırasında,
eldeyken veya kaba doğru giderken erken kayıt oluşmaz. Arşivlenen parça
kutu içinde kalır ve tekrar alınarak aynı kupon ikinci kez işlenemez.

Onaylı işlemde istenen kuponun hem fiziksel olarak kesilmiş hem de kutuya
konmuş olması gerekir. Damga ile kesim sırası serbesttir: önce kesip
dosyalayıp sonra onay basabilirsin. Karne ancak fiziksel olarak müşteriye
iade edildiğinde tamamlanmış karar olarak denetlenir. Odak modunda para
ve erzak stoğu değişmez.

RET/ALIKOY ile tamamlanmış bir işlemden kalan parça da temizlenip arşive
konabilir; sonraki müşteriyi çağırmak gerekmez. Bu, kapanmış denetim kaydını
veya aktif müşterinin hakkını değiştirmez. Önceki müşterinin kuponu yeni
karnenin kuponu olarak kaydedilemez.

Küçük kuponlarda ilk F duruşundan gerçekten yakınlaşmak mümkündür. Kamera
sınırı sabit bir küre mesafesi yerine dönen kâğıdın köşelerine göre hesaplanır;
yana çevirirken ve dönüşün ara karelerinde köşeler kamera düzlemini geçmez.

## Kontroller

| Durum | Kontrol | Sonuç |
| --- | --- | --- |
| Masadaki makas | E | Makası ele alma |
| Üstten masada, makas elde | Sol tuşu tutup ilerletme | Bıçağın gerçek ilerlemesi kadar kesme |
| Kesme sırasında | Shift | Daha yavaş, ince ilerleme |
| Kesme sırasında yönü değiştirme | İmleci yeni yöne götürme | Ucu sabit tutup açılma ve yeniden hizalanma |
| Kesme sırasında | Sol tuşu bırakma | Kesilen uzunluğu kâğıtta bırakma |
| Makas elde, kendi yerine bakarken | G | Makası yerine bırakma |
| Masadaki ayrılmış kupon | E | Aynı parçayı ele alma |
| Elde kupon | F | Yakın inceleme |
| Yakın inceleme | Sol sürükle / tekerlek / sağ tık | Döndürme / yakınlaşma / ön-arka |
| Yakın inceleme | F / Esc / Q / WASD | İncelemeden çıkma |
| Elde kupon, boş yüzeye bakarken | G | Parçayı yüzeye bırakma |
| Elde kupon, kupon kabına bakarken | E / G | Fiziksel temasla dosyalama |

## Fiziksel durum ile işlem kaydı

| Durum | Kâğıtta ve masada olan | İşlem kaydı |
| --- | --- | --- |
| Kısa kesi | Ana karne üzerinde gerçek uzunlukta açıklık | Kupon ayrılmış veya toplanmış sayılmaz |
| Dört kenar kesilmiş | Karne üzerinde delik, masada ayrı parça | Fiziksel ayrılma kaydedilir; otomatik dosyalama yok |
| Parça elde veya başka masada | Aynı kupon taşınır, izleri korunur | `collected` değişmez |
| Parça kaba temas etmiş | Kupon kutuda arşivlenir | Ürün tek kez `collected` listesine eklenir |
| Yanlış kupon kesilmiş | Yanlış parça da gerçekten ayrılabilir | Oyuncunun işlemi kendiliğinden düzeltilmez |
| Müşteriye iade | Karne fiziksel olarak teslim edilir | Seçilen karar, kesim ve dosyalama birlikte denetlenir |

Kesim rehberi kayıtlı bir “sahtelik cevabı” okumaz. Yıpranmış bir kâğıt
kesmek farklı bir suçluluk anlamı taşımaz. Rehber ve makasın duruşu kampanya
durumunu değiştirmez; kalıcı değişimler bıçak teması ve kupon kabı temasıyla
ilgili kurallardan geçer.

## Teknik sınırlar

Bu dilim kupon sınırlarını izleyen bir beceri mekaniğidir. Serbest biçimde
bütün karneyi küçük parçalara ayıran yumuşak gövde kâğıt simülasyonu değildir.
Kopup masaya yerleşme hareketi kontrollü animasyon kullanır; fizik motoruyla
her karede bükülen bir bez yüzey hesaplanmaz. Bırakma desteği, normal bir
masa işlemini güvenilir kılmak içindir.

Gerçek imleç ekran pikseline yuvarlanır. Yarım milimetrelik kenar toleransı
bu örneklemeyi karşılar; kayıtlı kesik yolu ve ölçülen uzunluk değişmez.
Köşe hizalaması eksik kesiyi tamamlamaz ve bir yüzdeki hasarı diğer yüzden
silmez. İnce ve kalın kâğıtların mevcut görsel malzemeleri korunur.

Prosedürel el/makas modelleri ve sesler prototiptir. Bu güncelleme bitmiş
AAA sanat üretimi, kapsamlı NPC animasyonu veya gerçek cihazda ASMR dinleme
kalitesi iddiası değildir. Mürekkep pedi ve yaş mürekkep 6. dilimde; genel
masa düzeni 7. dilimde; müşteri davranışları 8. dilimde kalır.

## Doğrulama ve görüntüler

Bu sonuçlar Godot 4.7.2 ile gerçekten çalıştırılan son koşulara aittir.

| Kontrol | Güncel durum |
| --- | --- |
| Godot 4.7.2 import ve tür denetimi | Geçti; `/tmp/kiosk-cutting-import.log`. Normal kayıt betiği ayrıca `--check-only` ile geçti |
| Birim testleri | 286 geçti, 0 başarısız; `/tmp/kiosk-cutting-final-unit.log`. Makas yön değiştirme, kare hızından bağımsız ilerleme, dosyalama kuralları ve küçük kuponun yakınlaşma/near-plane sınırları dâhil |
| Odak sahnesi 16 müşterilik döngü | Geçti; `/tmp/kiosk-cutting-final-full.log`. Kesim/toplama ve önceki kimlik/kâğıt/damga akışları birlikte, para/stok değişmeden tamamlandı |
| Pencereli 16 müşterilik odak döngüsü | Geçti; `/tmp/kiosk-cutting-final-gui.log`. Yeni kupon/toplama/kesinti ve önceki kimlik, ışık, büyüteç, masa, damga kontrolleri birlikte; para/stok değişmedi |
| Yeni köşe/kupon/kesinti regresyonları | Geçti; `/tmp/kiosk-coupon-completed-case.log`. İlk düz duruşta gerçek yakınlaşma, masa/zemin bırakma, eski müşterinin arşiv parçası, geçerli müşterinin fiziksel kap teması, yeniden başlatma ve RET sonrası zil çalmadan durum değiştirmeyen arşivleme sınandı |
| Pencereli gerçek imleç akışı | Geçti; `/tmp/kiosk-coupon-final-native.log`. Native imleçle 1,97 cm kalıcı kesik, açılarak köşe dönme, masaya düşme, E/F inceleme ve düz duruşta gerçekten yakınlaşma, boş masaya bırakıp yeniden alma, yalnız kap temasıyla dosyalama, fiziksel onay ve doğru iade. Para/stok değişmedi; selftest ve imleç override kullanılmadı. 169 kayıt karesi |
| Eski sekiz müşterilik tam satış sahnesi | Geçti; `/tmp/kiosk-cutting-legacy.log`. Kesinti regresyonları ve sekiz müşterinin ürün/satış döngüsü geçti |

Normal kayıt için `tools/capture_coupon_cutting.gd`, ilk geçerli et
kuponunu gerçek pencere girdileriyle işler. Kayıt; iki santimetrelik kesik,
köşede makasın açılması, masaya düşen parça, F inceleme, boş masaya yeniden
bırakma ve yalnız kaba temasla dosyalamayı sınar. Senaryo selftest imleç
override'ı veya hazırlanmış kampanya sonucu kullanmaz.

Pencereli kontroller 1600×1000 GL Compatibility/llvmpipe ve Dummy sesle yapıldı.
Son günlüklerde motor/GDScript hatası yok; yazılım sürücüsünün V-Sync uyarısı
var. İnsan oyuncu eğlence değerlendirmesi, gerçek ses aygıtıyla dinleme ve hedef
GPU performansı bu sonuçlara dâhil değildir.

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest
godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest
# Grafik oturumunda, normal pencere girdisiyle:
godot --rendering-method gl_compatibility --path . --resolution 1600x1000 --fixed-fps 30 --script res://tools/capture_coupon_cutting.gd -- --capture=/tmp/coupon-shots
```

Normal pencere kaydından alınan akış:

![Makas, köşe açılması ve fiziksel kupon toplama akışı](images/coupon-workflow.webp)

| Görüntü | Gösterdiği durum |
| --- | --- |
| [Kesim rehberi](images/coupon-guide.png) | Üstten masada makas ve fiziksel kupon sınırları |
| [Kısa kalıcı kesi](images/coupon-two-centimetres.png) | Bırakıldıktan sonra kâğıtta kalan yaklaşık 2 cm kesi |
| [Köşede açılma](images/coupon-corner.png) | Kesik uzamadan açılan ve yeni yöne dönen makas |
| [Masaya ayrılan kupon](images/coupon-loose.png) | Ana karne üzerindeki delik ve ayrı fiziksel parça |
| [Elde inceleme](images/coupon-inspect.png) | E/F ile yakına alınmış, döndürülmüş ve yakınlaştırılmış aynı parça |
| [Kuponun arkası](images/coupon-reverse.png) | Sağ tıkla çevrilen parçanın arka yüzü |
| [Dosyalanmış kupon](images/coupon-filed.png) | Gerçek kaba temas sonrası masadaki karne ve kutudaki kupon |
