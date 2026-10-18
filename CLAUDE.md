# Shared project context

Read [AGENTS.md](AGENTS.md), [the master prompt](docs/RATION_FPS_MASTER_PROMPT.md)
and [the interaction design](docs/RATION_DESK_DESIGN.md) before continuing.
The latest task is ONLY customer handoff, card/table inspection, forgery
comparison, physical cutting and stamping. No room/stock/economy expansion.

F5 opens `scenes/kiosk/ration_desk_focus.tscn` with `document_focus = true`.
Paperwork finishes by returning or retaining the card, without gathering goods
or billing stock. `fps_kiosk.tscn` preserves the older full-sale experiment.

First-person movement/handheld inspection and the same Camera3D moving above
the 3D desk are both intended. In desk mode the cursor moves physical tools;
right-drag pans and the wheel zooms. Q/WASD restores walking. Do not restore the
rejected 2D document dashboard or an obsolete eye-camera-only restriction.

Every partial incision remains on the paper; 2 cm of cutting is not a whole
coupon or a gesture that heals on release. Stamp contact speed, dwell and
pressure affect persistent ink. Physical references/loupe serve evidence
comparison, not automatic authenticity grading. Class/quota rules are fictional.

Preserve Game/CampaignState ownership, contact-sound timing and other developers'
work. Run relevant checks; record actual results separately from targets.
Ordinary authorized fixes need no extra confirmation. Procedural prototype
geometry/foley must not be described as finished AAA production.

Güncel kontroller: müşteri kartına E/tık aynı karneyi ele alır. Elde F inceleme
modunu açar; sol sürükle döndürür, sağ tık ters yüzü gösterir, tekerlek yakınlaşır,
R düzeltir; F/Esc/Q/WASD çıkar. Masaya E/G bırakma önizlemesiyle yerleştirip
üstten kamera açar. Masada F kâğıdı çevirir. `docs/CARD_INTERACTION_BACKLOG.md`
onaylanmış sıralı listedir; ilk iki dilim uygulanıp doğrulandı. Geçici damga kılavuzu
kalıcı mürekkebe/kayda giremez. Alan dışına fiziksel baskı iz bırakır, karar vermez.

Yeni kâğıt dilimi: `docs/PAPER_INSPECTION_UPDATE.md`. Üç stok gerçek 0,14/0,28/0,48
mm kalınlıkta; stok/aşınma suçluluk cevabı değildir. F incelemede T geçirgen ışığı
açar; eğince geliş açısı değişir. Kapatma/odak kaybı/restart ışığı temizler.
Kopmuş kuponun baskısı, hasar snapshot'ı ve malzemesi korunur. Kitapçığın arka
sayfası ışık/yama/aşınma karşılaştırmasını öğretir; fotoğraf/tarih/kimlik temelli
yeni sahtecilik senaryoları henüz eklenmedi.
