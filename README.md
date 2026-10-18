# KIOSK '81

Varşova, 1981–1989. Bir Ruch kioskunun arkasında, birinci şahıs bir anlatı simülasyonu.

- **Motor:** Godot 4.7.2 (standart sürüm, GDScript)
- **Açmak için:** Godot'u başlat → Import → bu klasördeki `project.godot` dosyasını seç.
- **Durum:** **F5: karne inceleme masası** — müşteriden teslim alma, üstten 3D masa/elde inceleme, sahtecilik karşılaştırması, kalıcı kesikler ve temasla damga. Ürün/ekonomi döngüsü bu odak modunun dışında; prosedürel prototip.

## Klasörler

| Klasör | İçerik |
| --- | --- |
| `game/` | Oyunun çekirdek kodu: durum, sistemler, kayıt, içerik yükleyici |
| `scenes/` | Godot sahneleri: kiosk, ev, oyuncu, müşteri, arayüz, efektler |
| `content/` | Oyun içeriği (JSON): ürünler, belgeler, kurallar, karakterler, olaylar |
| `dialogue/` | Diyalog dosyaları |
| `localization/` | Çeviri tabloları |
| `assets/` | Modeller, dokular, malzemeler, sesler, yazı tipleri, shader'lar |
| `tests/` | Otomatik testler |
| `tools/` | Yardımcı betikler |
| `docs/` | Tasarım belgelerine bağlantılar |

## Kurallar

- Bütün kod tipli GDScript'tir; tipsiz değişken derleme hatası verir.
- Oyunun durumunu yalnızca `Game` değiştirir; sahneler yalnızca gösterir.
- Kod ve dosya adları İngilizce, tasarım belgeleri Türkçe.

## Testleri çalıştırmak

- **Godot'ta:** `tests/run_tests.tscn` sahnesini aç ve **F6**'ya bas. Yazılar yeşilse bütün testler geçmiştir, kırmızıysa en az biri kırılmıştır.
- **Komut satırında:** `godot --headless --path . res://tests/run_tests.tscn -- --ci` (bütün testler geçerse çıkış kodu 0).

## Karne inceleme masası (F5)

Ana sahne: `scenes/kiosk/ration_desk_focus.tscn` (`document_focus = true`).
Şimdiki görev **yalnızca müşteriden karne alma, masada/elde inceleme,
sahtecilik karşılaştırması, kesim ve damga**. Bu mod ürün toplamayı, stok
harcamayı veya ödeme almayı gerektirmez; oda/ekonomi genişletme kapsam dışıdır.

[Güncel kâğıt ve ışık incelemesi](docs/PAPER_INSPECTION_UPDATE.md) ·
[Elde inceleme ve damga](docs/CARD_INSPECTION_UPDATE.md) ·
[Sıralı geliştirme listesi](docs/CARD_INTERACTION_BACKLOG.md) ·
[Bağımsız master prompt](docs/RATION_FPS_MASTER_PROMPT.md) ·
[Etkileşim tasarımı](docs/RATION_DESK_DESIGN.md) ·
[Tarihli kabul raporu](docs/RATION_FPS_ACCEPTANCE.md).
Güncel kontroller, hareketli kayıt ve doğrulama sonuçları bağlantılardadır.

- **WASD / fare / Shift:** pencereye yürü, bak, hızlı yürü.
- Müşterinin uzattığı karneye **E / tek sol tık**: aynı 3D kartı eline al.
- Eldeki karta veya alete **F**: yakından incele. **Sol sürükle:** serbest döndür;
  **tekerlek:** zoom; **sağ tık:** ön/arka yüz; **R:** duruşu düzelt. **T:** karneyi ışığa tut/kaldır.
  **F / Esc / Q / WASD:** incelemeden çık. Esc ilk basışta menü açmaz.
- Masaya bakarken görünen çerçeve bırakılacak yeri gösterir. **E / G** ile
  yerleştir; aynı kamera otomatik olarak üstten çalışma açısına gelir.
- Masadaki karneye veya geniş masa yüzeyine **tık / E**: üstten çalışmaya geri dön.
  **Sağ sürükle:** masayı kaydır; **tekerlek:** yaklaş; **Q / WASD:** yürümeye dön.
- Masada boş elle **sol tut + sürükle:** kâğıdı kaldır ve taşı.
  Sol tutarken **sağ tuş + sürükle:** yerinde döndür. Bırakınca yüzeye oturur.
- Masada **F:** kâğıdı çevir; **R:** ele al. Elde tekrar **F** ile yakın incele.
  Kesikler ve damgalar korunur. İade/alıkoyma için ilgili yere bakıp **E** kullan.
- Ön/arka yüzdeki ay, sınıf, kurum, hak, mühür ve müdahale izlerini karşılaştır.
  Yıpranmış kâğıt tek başına sahte değildir; sistem cevabı önceden göstermez.
- SATIŞ / RET / ALIKOY damgasını **E** ile al. İmleci **SATICI ONAYI / KARAR** alanına götür; geçici baskı önizlemesi yerini/açısını gösterir.
  İlk iki müşterinin hedef yardımı Esc menüsünden kapatılabilir;
  **sol tuş basılı + fare aşağı** ile indir/bastır. Hız, bekleme ve basınç izi
  değiştirir. Bırakınca kaldır; **Shift + tekerlek** açıyı değiştirir.
  Temas öncesi iptal iz bırakmaz; temas etmiş mürekkep kalır. Alan dışı fiziksel
  baskı kâğıtta kalır fakat işlem kararı kaydetmez.
- Makası **tık / E** ile al; kamera kesim için yaklaşır. **Sol tuş + sürükleme**
  sırasında bıçaklar görünür biçimde açılıp kapanır; yalnızca kapanırken keser.
  **2 cm kesik, bıraktıktan veya Q'dan sonra da 2 cm hasar olarak kalır.**
  Bir kısa kesik bütün kuponu tüketmez; dört kenarı ayrılınca tek parça kopar.
- Aracı uygun boş yüzeye **G** ile bırak. Karneyi **R** ile alıp müşteriye
  **E** ile iade et veya ALIKOY kararında belge bölmesine koy.
  Odak modunda bu, belge işlemini tamamlar; raftan ürün almak gerekmez.
- **Esc:** duraklatma/ses. Odak kaybı kontrolü bırakır; tamamlanmış izleri silmez.

Masadaki bez ciltli referans sınıfları, miktarları ve örnek kurum mühürlerini
birlikte gösterir. **Büyüteci E ile alıp kâğıt üzerinde gezdir**: altındaki gerçek
3D baskıyı yaklaşık 2,4 kat büyütür. **G** ile bırak; Q ile ayrılınca optik
render durur. Kitapçığı elde F ile inceleyip sağ tıkla arkasını çevir: resimli kâğıt/filigran/yama rehberi vardır.
Kâğıt iki yüzlü, 0,14 / 0,28 / 0,48 mm stoklarda, elde kalınlığına göre bükülen bir 3D yüzeydir;
yapıştırılmış kota değişikliğinin yükselen kenarı vardır.

Dört kenarı kesilen kupon, **damga öncesinde de fiziksel olarak kopar**.
Bunun ardından onay basılırsa istenen hak ayrıca işlenir. Yanlış kuponu kesmek
siparişi karşılamaz; tamamlanan incelemenin denetim kaydında hatalı hasar görünür.

Doğrulama komutları:

```sh
godot --headless --path . res://tests/run_tests.tscn -- --ci
godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest
# Grafik oturumunda; fare, okunabilirlik ve optik için de gerekli:
godot --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest --capture=/tmp/ration-focus-shots
```

Sistemdeki motor farklıysa Godot 4.7.2 binary'sini kullan. Pencereli kontrolde
araçların gerçekten görüntü içinde seçilebildiğini sınamak gerekir; offscreen
test koordinatı yeterli değildir. Dummy ses sürücüsü dinleme kontrolü sayılmaz.

Kâğıt/araç/eller ve foley prosedürel prototiplerdir; bitmiş AAA üretimi değildir.
Ana hedef kontrol, kanıt okuma ve temas hissidir. Ses üretimi:
`python3 tools/generate_ration_audio.py`, ardından Godot import.
WAV/PNG varlıkları Git LFS'dedir; yeni checkout'ta `git lfs pull` gerekir.

`scenes/kiosk/fps_kiosk.tscn` önceki erzak/ürün teslimli tam satış deneyini ayrı
korur; ortak kod değişirse onun selftest'i de çalıştırılır. İleride karne işi
bittikten sonra ürün toplama ve resmî/gizli stok seçimi yeniden bağlanabilir.
Yarı açık dünya, oda genişletme, terazi, para üstü ve kampanya şimdiki görev değildir.
Eski `ration_desk.tscn` 2D denemesi geliştirme referansıdır.

## Kiosk Simulator

- Eski ürün prototipi: `scenes/kiosk/simulator.tscn` sahnesini açıp **F6**. Master prompt: [KIOSK_SIMULATOR_MASTER_PROMPT.md](docs/KIOSK_SIMULATOR_MASTER_PROMPT.md).
- 12 basit ürün modeli: iki gazete, dergi, kibrit, ulaşım bileti, zarf, sabun, ayakkabı bağı, jilet, kalem, defter ve ambalajlı şeker. Fiyat, ambalaj ve günlük bulunabilirlik geçici; özellikle gıda tedarik/karne kuralları tarihsel doğrulama bekliyor. Sigara bu sahnede yok.
- **Sol tık:** tezgâhtan/depo kutusundan bir ürün al; boş tezgâh yerine veya satış tablasına bırak. Satış tablasındaki ürünü tekrar alabilirsin. Eldekini kendi depo kutusuna da bırakabilirsin.
- **Sağ tık / Esc:** eldeki ürünü geldiği yere geri bırak. Bir defada bir ürün tutulur; dolu yerlere bırakılamaz.
- Müşterinin istediği ürünü satış tablasına koy, **Satışı tamamla** düğmesine bas. Kasa ve defter güncellenir; 12 müşteri bitince ciro gösterilir. Fiyatlar grosze cinsinden tutulur, ekranda zł olarak gösterilir.
- Ürün modelleri `assets/models/kiosk_products/` içindeki ayrı `.tscn` dosyalarıdır. Yalnızca bu modelleri yeniden üretmek için: `godot --headless --path . --script res://tools/build_kiosk_products.gd`. Boyutlar metre cinsindedir; görsellerin kaynağı `scenes/kiosk/product_models.gd`.
- Etkileşim kontrolü: `godot --headless --path . res://scenes/kiosk/simulator.tscn -- --selftest`. Gerçek sahnede ışınla seçim, fare/Esc girdisi, alma, geri bırakma, satış ve stok yenileme kontrol edilir.
- Bu ilk dilimde müşteri tek adet ister. Para üstü, çok ürünlü sipariş ve karne akışı sonraki görevlerdir. Mevcut kayıt sistemi yerleşim/eldeki ürün verisini taşıyabilir; bu sahnede henüz kullanıcıya kayıt/yükleme düğmesi sunulmaz.

## Anlatı deneme günü

- **Açmak:** Simülatörde **Anlatı prototipi** düğmesi veya `scenes/kiosk/prototype.tscn` sahnesini açıp **F6**.
- **Ne var:** 15 Şubat 1982, 8 müşteri. Gazete, sigara (karneyle), kibrit satışı; rafları tezgâh altındaki kolilerden doldurma; karne kontrolü; deftere yazmak ya da parayı cebe atmak; komşu, milis ve Marek; gün sonu defteri (pencere + bütün gün: rutin satış, Ruch'a teslim, prim, ev gideri, şüphe) ve kayıt.
- **Tuşlar:** Fareyi ekran kenarına götür: etrafa bak · Kolilere tıkla: rafı doldur · Sağ tık: belgeyi incele · Q basılı: saat · 1–9: seçim · F2: English/Türkçe · F3: geliştirici paneli.
- **Sahneler kodla üretilir:** `godot --headless --path . res://tools/build_scenes.tscn` (dünya, görsel deneme ve deneme günü). Metinler: `localization/*.csv`; yeni metin eklenince `godot --headless --path . --script res://tools/extract_strings.gd`.

## Para ve risk simülasyonu

- `godot --headless --path . --script res://tools/simulate.gd -- --runs=200 --days=28`
- Dört oyun tarzını (dürüst, kasadan çalan, dikkatli, açgözlü) ekransız oynatır ve sonucu `docs/BALANCE_REPORT.md` dosyasına yazar. Sayılar `content/balance/balance.json` içindedir.

## Görsel deneme sahnesi

- **Açmak:** `scenes/sketch/visual_sketch.tscn` sahnesini aç ve **F6**'ya bas.
- **Tuşlar:** Bakmak için ekrana tıkla ve fareyi oynat (**Esc** fareyi bırakır). **1–4** retro seviyesini değiştirir (Kapalı, Hafif, Orta, Güçlü), **L** masa lambasını yakıp söndürür, **E** test belgesini açıp kapatır.
- Sahne gri kutulardan oluşur; ölçüler Yol Planı'ndan, renkler Görsel Hedef'ten gelir. Sahneyi elle değil, `tools/build_scenes.tscn` aracıyla yeniden üret.
