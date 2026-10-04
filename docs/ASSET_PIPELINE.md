# Varlık hattı (v1): Blender'dan Godot'a

Yol Planı 1.13 · 4 Ekim 2026 · İlk deneme 1.14'te: senin dışa aktaracağın mühür.

## Dışa aktarma kuralları

| Konu | Kural |
| --- | --- |
| Biçim | `.glb` (glTF 2.0). Her nesne kendi dosyasında; kiosk iç mekânı tek dosyada |
| Ölçek | 1 birim = 1 metre. Dışa aktarmadan önce dönüşümler uygulanır (Apply All Transforms), ölçek 1 |
| Eksen | Blender'da +Z yukarı, ön yüz −Y; glTF dışa aktarıcı bunu Godot'nun +Y yukarı düzenine çevirir |
| Pivot | Nesnenin doğal tutulma ya da oturma noktası. Örnek: mühür tabanı ortası, defter sırtı ortası |
| Etkileşim noktaları | Empty nesneler, Yol Planı'ndaki adlarla |
| Çarpışma | Ayrı basit mesh, adı `-col` ile biter. Bu son ek kuralı ilk denemede 4.7 belgeleriyle doğrulanacak |
| Dokular | 2'nin kuvveti boyutlar. Kaynak yüksek çözünürlükte üretilir, oyuna küçültülerek alınır: dünya yüzeyi 128–256 px, küçük nesne 64–256 px, mühür ve defter 256 px, yüz 256–512 px |
| Malzeme adı | Nesne adıyla başlar. Örnek: `stamp_body`, `stamp_rubber` |
| Markalar | Gerçek marka ve logo yok. RUCH logosu ve Trybuna Ludu başlığı gibi durumlarda önce hukuki görüş alınır |

## Godot tarafında ne yapılır

1. `.glb` dosyası `assets/models/<grup>/<ad>/` klasörüne konur.
2. İçe aktarma ayarlarında dokular **en yakın komşu** süzgeçle ve mipmap açık alınır. Bu, Görsel Hedef'teki "kırık doku" görünümünü verir.
3. Malzemeler `lofi_world.gdshader` tabanlı malzemelerle değiştirilir. Belge, yüz ve el malzemelerinde `lofi_weight = 0` olur, böylece bozulma uygulanmaz.
4. Nesne bir sahneye (`scenes/interactables/...`) sarılır: çarpışma katmanı, etkileşim noktaları, yuva bilgisi eklenir.

## Teslim ve kontrol listesi

Her teslimde şunlar gelir: `.glb` dosyası, nesnenin üç açıdan ekran görüntüsü, varsa kullandığın referans fotoğraf.

Ben şunları kontrol ederim:

- [ ] Ölçek gerçek boyutla uyumlu
- [ ] Eksen ve pivot doğru
- [ ] Dönüşümler uygulanmış
- [ ] Çokgen sayısı hedefte
- [ ] Doku boyutu hedefte
- [ ] Malzeme adları kurala uygun
- [ ] Çarpışma mesh'i var
- [ ] Etkileşim noktaları var
- [ ] Marka ve logo yok
- [ ] Godot'ta içe alındı ve sahnede denendi

Bir varlık ancak Godot'ta içe alınıp sahnede denendikten sonra "test edildi" sayılır. Eksik ya da uyumsuz bir şey varsa sessizce düzeltmem: ne gördüğümü yazar, düzeltmeyi sana bırakırım ya da açıkça önerip onayını beklerim.
