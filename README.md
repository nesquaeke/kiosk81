# KIOSK '81

Varşova, 1981–1989. Bir Ruch kioskunun arkasında, birinci şahıs bir anlatı simülasyonu.

- **Motor:** Godot 4.7.2 (standart sürüm, GDScript)
- **Açmak için:** Godot'u başlat → Import → bu klasördeki `project.godot` dosyasını seç.
- **Durum:** **F5: Karne masası** — kart inceleme, damga, kupon kesme ve satış kararları. **Ürün tezgâhı** düğmesi kiosk simülatörünü, oradaki **Anlatı prototipi** düğmesi eski deneme gününü açar. Meslek kartları, miktarlar ve kurumlar bilerek kurmaca; fiyatlar geçici.

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

## Karne masası (F5)

Oyunun ana mekaniği için kalıcı tasarım ve sonraki görevler: [RATION_DESK_DESIGN.md](docs/RATION_DESK_DESIGN.md).

- `scenes/kiosk/ration_desk.tscn`: üç meslek sınıfı, sekiz müşteri, ön/arka yüz incelemesi, kurum mührü ve miktar karşılaştırması. Kural defteri masada açık; belge gerçekliği önceden açıklanmaz.
- Müşterinin uzattığı karta tıkla. **F / sağ tık:** çevir. **Tekerlek:** büyüt/küçült. **Q/E:** eğ. **EL / TAŞI:** kartı sürükle.
- SATIŞ, RET veya ALIKOY aracını seç; ön yüzdeki **KARAR** alanına kısa süre basılı tutup kaldır. Mühür ve işlem izi kalır.
- Satışta resmî veya gizli stoktan ürün hazırla. **MAKAS** ile uygun kuponun sol üstündeki kesik çizgiyi sağa doğru, sol tuş basılıyken izle ve bırak. Kısa veya çizgiden çıkan kesim kuponu tüketmez.
- **EL / TAŞI** ile kartı **MÜŞTERİYE İADE** veya **ALIKONULAN BELGELER** bölmesine sürükle. Sonraki müşteriyi çağır. Yanlış onay/alıkoyma mümkün; kararlar gün sonunda değerlendirilir.
- Et/şeker gram, sabun adet olarak hesaplanır. Kayıt dışı satış ayrı stoktan düşer, cebe gelir ve denetim riskini artırır.
- Kâğıt, makas, kupon düşüşü ve damga basış/kaldırma için sekiz özgün prosedürel ses vardır. Ses seviyesi ve hareket azaltma kontrolleri masadadır. Sesler prototiptir; gerçek foley kayıtları sonraki kalite adımıdır.
- Gerçek sahne kontrolü: `godot --headless --path . res://scenes/kiosk/ration_desk.tscn -- --selftest`. Pencereli/ses sürücülü kontrol için `--headless` olmadan çalıştır. `-- --selftest --capture=/tmp/ration-shots` seçeneği ekran görüntülerini de kaydeder.
- Sesleri tekrar üret: `python3 tools/generate_ration_audio.py`, ardından Godot import. WAV varlıkları Git LFS'dedir; yeni checkout'ta `git lfs pull` gerekir.
- Bütün testler: `godot --headless --path . res://tests/run_tests.tscn -- --ci` — bu teslimde **163 geçti, 0 başarısız**.

Henüz: ek belge diyalogu, çok ürünlü sipariş, serbest tartım ve günler arası ilişki devamlılığı yok. Üç demo sahnesi kendi gününü başlatır; birbirlerinin kampanya devamı değildir.

## Kiosk Simulator

- Sahne: `scenes/kiosk/simulator.tscn`, karne masasındaki **Ürün tezgâhı** düğmesinden açılır. Master prompt: [KIOSK_SIMULATOR_MASTER_PROMPT.md](docs/KIOSK_SIMULATOR_MASTER_PROMPT.md).
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
