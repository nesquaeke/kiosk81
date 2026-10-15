# KIOSK '81

Varşova, 1981–1989. Bir Ruch kioskunun arkasında, birinci şahıs bir anlatı simülasyonu.

- **Motor:** Godot 4.7.2 (standart sürüm, GDScript)
- **Açmak için:** Godot'u başlat → Import → bu klasördeki `project.godot` dosyasını seç.
- **Durum:** **F5: FPS karne sistemi** — yürüyerek cama gitme, müşteriden kart alma, elde/masada inceleme, fiziksel damga ve makas, ürün ve kart teslimi. Kurmaca kart kuralları, basit 3D modeller.

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

## FPS karne sistemi (F5)

Bağımsız görev ve kabul ölçütleri: [FPS master prompt](docs/RATION_FPS_MASTER_PROMPT.md).
Uygulanan dilim: [RATION_DESK_DESIGN.md](docs/RATION_DESK_DESIGN.md).
Doğrulama ve görüntüler: [Kabul raporu](docs/RATION_FPS_ACCEPTANCE.md).
Bu oyun birinci şahıs 3D'dir. Karne incelemesi için başka bir ekrana geçilmez.

- Sahne: `scenes/kiosk/fps_kiosk.tscn`. Odada **WASD** ile yürü, fareyle bak, **Shift** ile hızlı yürü. Duvar ve tezgâh çarpışmaları vardır.
- Cama yaklaş; müşterinin uzattığı karta **E** ile etkileş. Kart kısa hareketle masaya yerleşir.
- Masadaki karta **E** ile etkileşip eğil. **Q** veya yürümek incelemeden çıkar; karne masada kalır. **R** karneyi açık bir seçimle eline alır.
- **Sağ tuş basılı + fare:** eldeki kartı eğ. **F:** ön/arka yüz çevir. **Tekerlek:** yaklaştır/uzaklaştır. Kamera karakterin gözünde kalır.
- Masaya bakıp **G** ile kartı bırak. Sağ elinde başka nesne varsa G önce onu bırakır; çalışma alanına **E** ile de kartı bırakabilirsin.
- Karne; çift yüz baskısı, kurum mührü, sınıf/kota/ay/seri, yama ve yıpranma izleri içerir. Masada F ile çevirirken fiziksel olarak yükselir; gerçek arka yüz görünür.
- Masadaki SATIŞ/RET/ALIKOY damgasına bakıp **E** ile al. Kartın KARAR alanına yönelip sol tuşa kısa süre basılı tut ve bırak; fiziksel temasla mürekkep izi oluşur.
- Damga temasından önce **Q**, yürüme veya Esc işlemi iptal eder; temas etmiş mürekkep korunur. Araç alma/bırakma sesleri temas anındadır.
- Damgayı **G** ile yüzeye bırak; önce ilgili kuponu kes, sonra raflara git.
- Makası **E** ile al. Kuponun sol üst kesik çizgisine bak; sol tuş basılıyken bakışını çizgi boyunca sağa götür, tuşu bırak. Kısa veya çizgi dışı kesim kupon tüketmez. Kâğıtta gerçek boşluk kalır.
- Makası bırak; **Q** ile ayrıl. Sağdaki raftan istenen ürünü **E** ile alıp tezgâha taşı. **G** ile bırakıp tekrar alabilir veya müşteriye **E** ile uzatabilirsin. Kalan karneyi **R** ile alıp müşteriye E ile ver veya alıkoyma bölmesine koy.
- Etin kâğıt/sicim paketi, şekerin katlı torbası ve sabunun kılıfı ayrı 3D nesne görünümleridir. Her ürünün ayrı alma/bırakma sesi vardır.
- Talep fişi masadadır; E ile alıp okunabilir. Müşteriye boş elle E ile isteğini tekrar dinle. Altyazı odada sürekli açık kalmaz.
- Masadaki zile E ile basarak sonraki müşteriyi çağır. Sıra bitince soldaki yan masada bulunan gün sonu defterini eline alıp oku.
- Üç meslek sınıfı, sekiz müşteri, sınıf/kurum/miktar denetimi ve resmî/gizli stok vardır. Kart kuralları bilerek kurmaca; fiyatlar geçicidir. Yanlış karar mümkündür, gün sonunda değerlendirilir.
- **Esc:** duraklatma ve ses ayarı. Sesler kâğıt/makas/damga için özgün prosedürel prototiplerdir.
- Kural/işlem testleri: `godot --headless --path . res://tests/run_tests.tscn -- --ci` — **186 geçti, 0 başarısız**.
- FPS fiziksel etkileşim kontrolü (önce iptal/odak/yeniden başlatma regresyonları, ardından sekiz müşteri): `godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest`.
- Pencereli kontrol: aynı komutu `--headless` olmadan çalıştır. `-- --selftest --capture=/tmp/fps-shots` görüntü kaydeder.
- Sesleri yeniden üret: `python3 tools/generate_ration_audio.py`, sonra Godot import. WAV/PNG varlıkları Git LFS'dedir; yeni checkout'ta `git lfs pull` gerekir.

El/müşteri modelleri basittir; tam IK, büyük yarı açık dünya, terazi, para üstü,
çok ürünlü sipariş ve kampanya devamlılığı sonraki aşamalardır.
Eski `ration_desk.tscn` 2D denemesi yalnızca geliştirme referansıdır.
Ürün simülatörü ve anlatı prototipi ayrı sahneler olarak F6 ile açılabilir.

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
