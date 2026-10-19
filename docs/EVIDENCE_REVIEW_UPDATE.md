# Karne ve kimlik — kanıta dayalı inceleme güncellemesi

18 Ekim 2026. Bu güncelleme, [sıralı planın](CARD_INTERACTION_BACKLOG.md)
4. dilimindeki yeni belge senaryolarını ve fiziksel karşılaştırma araçlarını ekler.
Yalnız oda/masa/belge döngüsünü kapsar. Makas toplama cilası, yeni mürekkep pedi,
masa düzenleme, müşteri soruları ve son ASMR üretimi sonraki işlerdir.

Ana sahne `scenes/kiosk/ration_desk_focus.tscn` olur. Önceki sekiz müşterinin
ardından sekiz yeni inceleme gelir; odak sırası 16 müşteridir. Ayrı tutulan
`fps_kiosk.tscn` tam satış deneyi eski sekiz müşterisini korur.

Yeni vakaları beklemeden denemek için Esc menüsündeki **Belge karşılaştırma çalışma günü**
seçeneğini kullan veya `scenes/kiosk/ration_review_day.tscn` sahnesini F6 ile aç.
Bu giriş yalnız yeni sekiz vakayı başlatır; normal F5 sırası 16 müşteridir.

## Oyuncunun yapabildikleri

Müşteri karneyi uzattığında E ile aynı fiziksel kâğıdı ele alırsın. Yeni
senaryolarda yanında getirdiği kimlik masaya gelir. Kimlik; adı, numarası ve
fotoğrafı bulunan, ön/arka yüzlü ayrı bir 3D nesnedir. Elde alınır, yakın
incelenir ve masaya geri bırakılır. Ekranı kaplayan belge kontrol paneli açılmaz.

Karne bir elde, kimlik diğer eldeyken F ile yakın inceleme açılır. C, eldeki
iki belge arasında geçer. Böylece küçük bir numara farkını veya fotoğrafı
karşılaştırmak için belgeleri sürekli masaya bırakıp tekrar almak gerekmez.
Bu geçiş yeni belge oluşturmaz; kesikleri, mürekkebi veya kampanya durumunu değiştirmez.
İki belgenin inceleme dönüşü ve zoomu ayrı ayrı hatırlanır: arka fotoğrafı
incelerken C ile kimliğe bakıp döndüğünde yine aynı açıdaki arka yüzü görürsün.
İncelemeden tamamen çıkınca ikisi de önceki gerçek tutuşuna döner.

Kartın üzerindeki ayrıntılar belirli sorulara cevap verir:

- Ay alanındaki soluk eski baskı ile üstteki ay aynı mı?
- Fotoğrafın kenarından geçen mühür çizgisi kâğıt üzerinde devam ediyor mu?
- Karne sahibinin adı, kimlik numarası ve portresi ek belgeyle uyuşuyor mu?
- Kuponun seri numarası ana karneyle aynı mı?
- İstenen kuponda daha önce ürün verildiğini gösteren `WYDANO` izi var mı?

Oyuncu bu bilgiyi yorumlar. Yakından bakmak sahte belgenin çevresini
renklendirmez, doğruluk sesi çalmaz ve karar damgasını kendiliğinden seçmez.

## Kontroller ve önerilen akış

| Durum | Kontrol | Sonuç |
| --- | --- | --- |
| Müşterinin uzattığı karne | E / sol tık | Karneyi ele alma |
| Masadaki kimlik | E | Kimliği sağ ele alma |
| Elde belge | F | Yakın inceleme |
| Yakın inceleme | Sol tuşu tutup sürükle | Nesneyi döndürme |
| Yakın inceleme | Tekerlek | Sınırlı yakınlaşma/uzaklaşma |
| Yakın inceleme | Sağ tık | Ön/arka yüze geçme |
| Yakın inceleme | R | Okunabilir duruşa dönme |
| Karne ve kimlik birlikte elde, yakın inceleme açık | C | Diğer belgeyi yakından gösterme |
| Karne yakın inceleme | T | İnceleme ışığını açma/kapatma |
| Yakın inceleme | F / Esc / Q / WASD | İncelemeden çıkma |
| Elde karne, masaya bakarken | E / G | Yerleştirme önizlemesindeki yere bırakma ve üstten çalışma |
| Üstten masa | Sağ sürükle / tekerlek | Masayı kaydırma / kamerayı yaklaştırma |
| Üstten masa | Q / WASD | Birinci şahıs yürüyüşe dönme |
| Kitapçık elde, F inceleme açık | Tab | İki resimli kanıt sayfası arasında geçme |
| Kimlik/alet elde, uygun yüzeye bakarken | G | Nesneyi yüzeye bırakma |

Önerilen kısa akış:

1. Karneyi al; F ile ön ve arkasına bak. Ayı, ana seri numarasını ve hakları oku.
2. Kimliği de al. F ve C ile ad, kimlik numarası ve fotoğrafı karşılaştır.
3. İncelemeden çıkıp kimliği masaya bırak. Karneyi çalışma alanına koy.
4. Küçük bir alanı okumak için büyüteci kullan veya karneyi tekrar ele alıp yakınlaş.
5. Kitapçığı gerektiğinde al; F ve Tab ile resimli örneklere başvur.
6. Seçtiğin damgayı bas. Onayda istenen kuponu fiziksel olarak kes.
7. Karneyi ele alıp müşteriye iade et veya alıkoyma bölmesine koy.

Tamamlama hâlâ fiziksel damga ve gerçek belge teslimi gerektirir. Odak modunda
erzak arama, paket hazırlama, stok azaltma veya para alma yoktur. Kimlik, karneye
el konulsa da müşteriye geri gider; alıkoyma kararı karne içindir.

## Hangi iz ne anlama geliyor?

| Gözlenen durum | Oyun kuralı |
| --- | --- |
| Silinti altındaki ay üstteki aydan farklı | Değiştirilmiş ay; alıkoyma |
| Eski ay açıkça yazıyor, değiştirilme kanıtı yok | Süresi uygun değil; ret |
| Fotoğrafı kesen mühür parçaları birleşmiyor | Fotoğraf müdahalesi; alıkoyma |
| Karne ve kimlikte ad/numara/fotoğraf çelişiyor | Belge eşleşmiyor; alıkoyma |
| Görünen kupon serisi ana karne serisinden farklı | Başka karneden alınmış kupon; alıkoyma |
| İstenen kuponda önceki teslim tarihi var, seri tutarlı | Hak daha önce kullanılmış; ret |
| Başka ürünün kuponunda önceki teslim var | Kalan kullanılabilir ürün hakkını tek başına bozmaz |
| Aşınma, kazınma, soluk mürekkep, tutkal veya onarılmış kâğıt | Tek başına ret/alıkoyma nedeni değil |

Örneğin ay alanının kazınmış olması yeterli değildir: aynı ayın okunaklı şekilde
yeniden yazıldığı geçerli bir örnek de vardır. Yapıştırılmış fotoğraf normaldir;
asıl karşılaştırma fotoğrafın sınırından geçen mühürdür. Kuponun tutkal izi de
tek başına sahtelik sayılmaz; ana belgeyle çelişen seri okunmalıdır.

Damga tercihi bu kanıtlarla önceden engellenmez. Oyuncu hatalı onay, ret veya
alıkoyma yapabilir. Sonuç kaydı ancak belge tesliminden sonra kararı ve somut
uyuşmazlıkları değerlendirir. İade/alıkoyma işlemi tekrar çağrıldığında ikinci bir
sonuç veya para hareketi oluşmaz.

## Yeni sekiz vaka — geliştirici çözüm anahtarı

Bu tablo test ve içerik geliştirme içindir; oyun sırasında otomatik cevap olarak
gösterilmez. Mevcut ilk sekiz vaka değiştirilmez.

| Vaka | Müşteri / talep | Okunacak kanıt | Doğru işlem |
| --- | --- | --- | --- |
| `rc_09` | Irena Borkowska / 1 sabun | Ad, `AB 450101` kimlik numarası ve fotoğraf iki belgede aynı; kupon serileri tutarlı | Onay, sabun kuponunu kes, iade |
| `rc_10` | Tomasz Król / 1000 g şeker | Görünen `1982-02` ayının altında kazınmış `1982-01` baskısı | Alıkoy |
| `rc_11` | Barbara Sikora / 1 sabun | Kimlik tutarlı; fotoğrafı kesen mühür parçaları fotoğraf sınırında kaymış | Alıkoy |
| `rc_12` | Piotr Dudek / 1000 g şeker | Karnede Piotr Dudek / `AD 320660`; kimlikte Piotr Duda / `AD 320668` | Alıkoy |
| `rc_13` | Alicja Pawlak / 500 g et | Ana seri `T-03426`; yapıştırılmış et kuponundaki seri `T-03106` | Alıkoy |
| `rc_14` | Stefan Wrona / 1000 g şeker | Şeker kuponu seri bakımından tutarlı; `1982-02-08` tarihli önceki teslim mührü var | Ret ve iade; sahtelik diye alıkoyma |
| `rc_15` | Maria Górska / 1 sabun | Çok yıpranmış, onarılmış kâğıt ve soluk/düzensiz mühür; alt ve üst ay aynı, kimlik ve mühür sürekliliği tutarlı | Onay, sabun kuponunu kes, iade |
| `rc_16` | Andrzej Kaczmarek / 1 sabun | Ad ve numara aynı; karne ile kimlikteki fotoğraflar farklı kişileri gösteriyor | Alıkoy |

Sıra önce tutarlı kimliği öğretir, sonra birer somut çelişki getirir. Sonlara
doğru geçerli ama yıpranmış bir belgeyle yanlış şüpheyi ve yalnız fotoğraf farkıyla
daha dikkatli karşılaştırmayı dener. Bu, henüz rastgele vaka üreticisi veya
oyuncuya göre zorluk ayarlayan bir sistem değildir.

## Dosyalar ve veri sözleşmesi

| Dosya | Görev |
| --- | --- |
| [review_cases.json](../content/ration/review_cases.json) | Ayrı `ration_review_case` türünde sekiz ek kayıt |
| [desk_cases.json](../content/ration/desk_cases.json) | Korunan ilk sekiz `ration_case` |
| [content_schema.gd](../game/content/content_schema.gd) | Yeni kayıt türünü içerik yükleyicisine tanıtma |
| [ration_evidence.gd](../game/systems/ration_evidence.gd) | Görünen alanlardan uyuşmazlıkları türetme; içerikten gizli sahtelik cevabı okumama |
| [ration_desk_rules.gd](../game/systems/ration_desk_rules.gd) | Mevcut işlem kurallarıyla kanıt sonuçlarını birleştirme ve tamamlanmış kararı denetleme |
| [ration_card_view.gd](../scenes/kiosk/ration_card_view.gd) | Alt tarih, silinti, fotoğraf/mühür, kupon serisi ve önceki teslim baskısı |
| [document_portrait.gd](../scenes/kiosk/document_portrait.gd) | Karne ve kimliğin kullandığı ortak portre çizim kaynağı |
| [identity_document_3d.gd](../scenes/kiosk/identity_document_3d.gd) | Ayrı fiziksel kimlik ve iki yüzündeki baskı |
| [desk_reference.gd](../scenes/kiosk/desk_reference.gd) | Tab ile değiştirilen iki resimli referans sayfası |
| [fps_kiosk.gd](../scenes/kiosk/fps_kiosk.gd) | Kimlik teslimi, iki belgeyi elde tutma, C/Tab kontrolleri ve odak modunda ek vaka yükleme |
| [ration_review_day.tscn](../scenes/kiosk/ration_review_day.tscn) | Yalnız yeni sekiz vakaya doğrudan giriş |
| [test_ration_evidence.gd](../tests/unit/test_ration_evidence.gd) | Kanıt, yanlış karar, geçerli yıpranma ve JSON/idempotence kontrolleri |

Kayıttaki `identity`, ek belgenin `holder`, `number`, `portrait_variant`
alanlarını taşır. Karttaki karşılıkları `holder`, `identity_number`,
`portrait_variant` olur. Kartın `evidence` sözlüğü şu basılı bilgileri taşır:

```json
{
  "date": {"underprint_month": "1982-02", "abrasion": 0.62},
  "portrait": {"seal_offset": [0, 0], "pasted": true},
  "coupons": {
    "soap": {"serial": "T-03438", "previous_issue": ""}
  },
  "ink_variation": {"density": 0.55, "unevenness": 0.72}
}
```

Bu örnek geçerli olabilir. `abrasion`, `pasted`, `ink_variation`, `paper_stock`
ve `paper_wear` suçluluk cevabı değildir. Değerlendirme farklı okunur ay,
birleşmeyen mühür, eşleşmeyen kimlik/fotoğraf, farklı kupon serisi ve önceki
teslim tarihi üzerinden yapılır. Yeni alanların olmadığı eski kayıtlara yeni
bir gizli uyuşmazlık eklenmez.

## Çalıştırılmış kontroller

| Kontrol | Durum / kanıt |
| --- | --- |
| Godot 4.7.2 headless editor import | Geçti; `/tmp/forgery-rules-import.log` |
| Birim testleri | 251 geçti, 0 başarısız; `/tmp/kiosk-evidence-release-unit.log`. Yeni 14 kanıt testi bu koşuya dâhil; aynı görünen portre varyantlarının gizli fark sayılmadığı da kontrol edildi |
| İçerik yükleme | 9 dosya, 43 kayıt, 0 hata; aynı birim koşusu |
| Odak sahnesi headless döngüsü | 16 müşteri geçti; `/tmp/kiosk-evidence-release-full.log`. Ürün/para değişimi yok |
| Yeni C/Tab/kimlik etkileşim regresyonları | Geçti; `/tmp/kiosk-evidence-parking-headless.log`. İki belgenin arka yüz/zoom hafızası, gerçek tutuşun geri gelmesi, dört köşenin kadraja sığması, boş damga yerine erişim ve eldeki kimliğin ışınlanmadan iadesi dâhil |
| Pencereli 16 müşteri ve okunabilirlik | Geçti; `/tmp/kiosk-evidence-gui.log`. Yeni kimlik/C/Tab/yerine bırakma kontrolleri ve önceki kâğıt, masa, büyüteç, ölçülü kesim ve damga kontrolleriyle birlikte; para/stok değişmedi |
| Eski tam satış sahnesi tekrar kontrolü | Kesinti kontrolleri ve sekiz müşteri geçti; `/tmp/kiosk-evidence-final-legacy.log` |
| Normal oyun girdisiyle görüntü/kayıt | Sekiz yeni vaka doğru tamamlandı; `/tmp/kiosk-evidence-normal.log`. F/C/Tab, gerçek imleçle damga/kesim/iade; selftest veya imleç override kullanılmadı. 109 kareden hareketli kayıt üretildi |

Tekrarlanabilir temel komutlar, repo kökünde:

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest --evidence-only
# Pencereli kontrol ve normal oyun kaydı, bir grafik oturumu içinde:
godot --rendering-method gl_compatibility --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest
godot --rendering-method gl_compatibility --path . --resolution 1600x1000 --fixed-fps 30 --script res://tools/capture_evidence_review.gd -- --capture=/tmp/evidence-shots
```

Bulutta bu komutlarda sistem Godot'u yerine
`/workspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64` kullanılır.
Headless sonuç, yazıların oyuncunun ekranında rahat okunabildiğinin kanıtı değildir.

Kontroller GL Compatibility/llvmpipe, 1600×1000 ve Dummy ses sürücüsünde yapıldı.
Motor/GDScript hatası olmayan son koşularda yazılım sürücüsünün V-Sync uyarısı
vardır. Hedef GPU performansı, Forward+ görünümü, gerçek ses aygıtıyla dinleme
ve insan oyuncunun eğlence değerlendirmesi bu otomasyonun sonucu değildir.

## Normal oyun penceresinden kayıt

109 karelik kısa kayıt, aynı dünyadaki kimliği alma, F/C karşılaştırması ve ay
alanına yakınlaşmayı gösterir. Tam kayıt betiği sekiz vakanın damga, kupon kesimi
ve teslim sonuçlarını da doğrular. Hareketsiz örnekler de aynı koşudan alınmıştır.

![Fiziksel kimlik ve karne inceleme akışı](images/evidence-workflow.webp)

![Karne ve kimlik aynı masada; belgenin dört köşesi de kadrajda](images/evidence-two-documents.png)

![Elde incelenen ayrı kimlik belgesi](images/evidence-identity.png)

![Görünen 1982-02 tarihinin altındaki 1982-01 baskısı](images/evidence-date.png)

![Fotoğraf kenarında birleşmeyen mühür](images/evidence-photo-seal.png)

![Ana karneyle farklı seri taşıyan yapıştırılmış kupon](images/evidence-coupon.png)

![Kuponun üzerindeki önceki WYDANO teslim izi](images/evidence-prior-issue.png)

![Yıpranmış geçerli belgedeki soluk ama devamlı mühür](images/evidence-worn-seal.png)

![Kitapçığın fiziksel belge karşılaştırma sayfası](images/evidence-reference.png)

Bu kontrolde damgaların yakın saplarının boş bırakma noktasını perdelediği de
görüldü. Damga aralığı 19 cm'ye çıkarıldı; her birinin alınıp kendi boş masa
noktasına bırakılması gerçek fizik ışınıyla kontrol ediliyor.

## Güncel sınırlar ve sonraki iş

Portreler ortak kaynaktan çizilen sekiz belirgin prosedürel örnektir; taranmış
arşiv fotoğrafları veya bitmiş karakter sanatı değildir. Silinti, fotoğrafın
yapıştırılması ve eski kupon yapıştırma izleri kâğıdın baskı katmanında çizilir;
ayrı bir tutkal/sökme simülasyonu yoktur. Kupon kesimi önceki fiziksel hasar
sistemini kullanır; bu güncelleme serbest biçimli kâğıt topolojisi eklemez.

Kimlik karşılaştırması ek belgeyle sınırlıdır. NPC yüzünden biyometrik kişi
tanıma, kimlik veri tabanı, sorgulama diyalogları veya otomatik yakalama sistemi
eklenmedi. Önceki teslim mührü kuponun baskısındadır; şehirdeki bütün satışları
izleyen merkezi bir kayıt değildir.

Bu dilimden sonra [5. dilimde](CARD_INTERACTION_BACKLOG.md) makasın kontrollü
kesim hissi, kuponun ele alınıp kapta biriktirilmesi ve ilgili küçük hareketler
iyileştirilecek. Yeni müşteriler veya dekor eklemek bu işin yerine geçmez.
