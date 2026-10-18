# Tasarım belgeleri

Anlatı belgeleri aşağıdaki Claude Docs bağlantılarındadır. Kullanıcının güncel
FPS etkileşim kapsamı ve uygulanmış mekanikler bu depodaki tasarım belgesinde
ve README'de tutulur; eski prototip tarifleri güncel FPS kararının önüne geçmez.

- Üretim Yol Planı: https://claude.ai/code/artifact/9f81743d-dd6b-4d19-a1f9-b2c4f4501b96
- Proje İncili: https://claude.ai/code/artifact/d2f4600c-f4df-47e9-8a2a-4886802016b9
- Karakterler: https://claude.ai/code/artifact/d5dd8619-3158-498e-9155-2128a182a89a
- Görsel Hedef: https://claude.ai/code/artifact/9033d065-85a0-4eed-a0df-ec0b7d5546b6
- Aşama 0, GDD Denetimi: https://claude.ai/code/artifact/de709279-8522-4751-8bce-292d88520918

## Bu klasördeki teknik belgeler

Kodla birlikte değişen belgeler burada, depoda durur.

- [Teknik mimari](TECHNICAL_ARCHITECTURE.md): katmanlar, bir eylemin yolu, kayıt, dil, görüntü, testler.
- [Kiosk Simulator master prompt](KIOSK_SIMULATOR_MASTER_PROMPT.md): kullanıcı isteğine göre hazırlanan ilk ürün yerleştirme ve satış diliminin ortak görev/kabul sözleşmesi; yukarıdaki kanon belgelerine ek çalışma kapsamıdır.
- [FPS karne tasarımı](RATION_DESK_DESIGN.md): kullanıcının seçtiği ana mekanik; karakterin gözünden müşteri elinden alma, elde/3D masada inceleme, fiziksel makas ve damga, ürün teslimi ve yol haritası. Önceki 2D masa yaklaşımının yerine geçer; kart kuralları bilinçli oyun tasarımıdır.
- [Koşul ve efekt dili](CONDITION_LANGUAGE.md): içerik dosyalarında "ne zaman olur" ve "olunca ne değişir" nasıl yazılır.
- [ADR-001 Diyalog biçimi](adr/ADR-001-dialogue-format.md): diyaloglar neden JSON düğümleri.
- [Varlık hattı](ASSET_PIPELINE.md): Blender'dan Godot'a dışa aktarma kuralları ve kontrol listesi.

- [Elde inceleme ve damga: güncel sürüm](CARD_INSPECTION_UPDATE.md)
- [Onaylanmış sıralı geliştirme listesi](CARD_INTERACTION_BACKLOG.md)

- [Kâğıt çeşitleri, ışığa tutma ve fiziksel kanıt rehberi](PAPER_INSPECTION_UPDATE.md)
