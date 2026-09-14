# Prompt Nano Banana (Gemini) untuk bikin skin buah baru

Pendekatan: **badan buah dan wajah dipisah jadi layer berbeda.**

```
10 badan buah (polos, tanpa wajah)  ×  2 wajah (idle + mata X)  =  20 tampilan
```

Keuntungannya: mau ubah bentuk mata tinggal regenerate 1 file wajah, bukan 10 (atau 20)
gambar buah. Dan karena wajahnya file yang sama persis ditempel di semua buah, ekspresinya
otomatis konsisten — tidak ada buah yang matanya kegedean sendiri.

Prompt ditulis dalam bahasa Inggris — model gambar jauh lebih patuh dengan bahasa Inggris.

> Prompt jadi siap copy-paste (10 badan + 2 wajah) ada di [skin_prompts_ready.md](skin_prompts_ready.md).

---

## 0. Aturan wajib

### Untuk badan buah

`tool/prepare_skin.py` yang akan memotong background dan mengukur badan buah. Supaya lolos:

| Aturan | Alasan |
|---|---|
| Background **putih polos rata** (#FFFFFF), tanpa gradasi | script hapus background dari warna 4 sudut, toleransi 30 |
| **Tanpa drop shadow / pantulan / alas** | bayangan ikut kepotong jadi noda abu-abu di tepi sprite |
| **Bulat sempurna**, siluet seperti bola, memenuhi frame | radius tabrakan = lingkaran terbesar di dalam gambar; makin bulat makin pas art dengan physics |
| **Tanpa wajah sama sekali** | wajah datang dari layer terpisah |
| Area tengah-bawah buah relatif bersih | itu tempat wajah ditempel; kalau ada highlight terang atau tekstur ramai, wajahnya tenggelam |
| Tanpa teks, watermark, border, angka | akan ikut terbawa jadi sprite |
| Rasio **1:1**, resolusi tertinggi yang bisa | script resize sendiri ke 128–512px |
| Batang/daun boleh menonjol ke **atas** saja | overhang atas didukung, samping/bawah bikin buah "melayang" |

### Untuk file wajah

| Aturan | Alasan |
|---|---|
| Background **hijau chroma polos** (#00FF00) | wajah tidak punya unsur hijau, jadi aman dipotong tanpa memakan blush pink |
| Kanvas **1:1**, wajah persis di tengah kanvas | ditempel ke buah pakai satu offset yang sama untuk semua buah |
| Wajah menempati **±55% lebar kanvas** | skalanya nanti relatif terhadap diameter buah |
| Mata X **dibuat dengan mengedit file idle**, bukan digambar ulang | posisi & ukuran mata harus persis sama supaya pergantiannya tidak "meloncat" |
| Datar, menghadap depan, tanpa perspektif | akan ditempel ke banyak buah dengan lengkung berbeda |

`prepare_skin.py` **tidak bisa** memproses file wajah — script itu mencari "lingkaran
terbesar di dalam gambar", logika khusus buah. Gunakan [cut_face.py](cut_face.py):

```powershell
python tool/cut_face.py <folder>/face_idle.jpg <folder>/face_x.jpg --out assets/skins/<skin>
```

Script itu memakai green-ness tiap piksel sebagai alpha (bukan ambang warna), lalu
membatalkan pencampuran terhadap background — jadi tepi blush yang semi-transparan pulih
jadi pink, bukan pink-di-atas-hijau. Kanvasnya sengaja **tidak** di-trim supaya `face_idle`
dan `face_x` tetap satu kerangka koordinat.

---

## 1. Blok STYLE — ini yang menentukan skin barunya

Pilih **satu**, pakai blok yang sama persis di kesepuluh buah. Konsistensi blok ini =
konsistensi skin.

### Preset 1 — `gummy_kawaii` (permen jelly)

```
Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside,
thick glossy specular highlight in the upper-left, saturated candy colors,
smooth rounded volume, high-end mobile game icon quality, soft studio lighting
from the upper left.
```

### Preset 2 — `clay_kawaii` (clay / stop-motion)

```
Art style: handmade polymer clay claymation prop, soft matte plasticine surface
with subtle fingerprint dents and tiny lint specks, chunky rounded volume, warm
soft studio lighting from the upper left, cute stop-motion animation prop,
high-end mobile game icon quality.
```

### Preset 3 — `pixel_kawaii` (retro arcade)

```
Art style: crisp 32x32 pixel art upscaled with hard nearest-neighbor edges, no
anti-aliasing, limited 12-color palette per fruit with clear light/mid/dark/
highlight ramps, black 1px outline, dithered shading on the lower right,
retro arcade sprite look, perfectly readable at small size.
```

> Mau tema lain? Tulis ulang blok ini saja (mis. `watercolor storybook`, `chrome
> metallic`, `crochet amigurumi`, `origami paper craft`). Sisanya biarkan sama.
>
> Kalau ganti tema buah, **wajahnya juga ikut diganti** supaya materialnya nyambung —
> mata jelly mengkilap di badan clay yang matte akan terlihat seperti stiker tempelan.

---

## 2. Blok SUBJECT — 10 buah, urut level 0→9

Nama file input harus sesuai nama ini supaya `prepare_skin.py` memetakan levelnya benar.

| # | File | SUBJECT |
|---|---|---|
| 0 | `Ceri.png` | `a single round red cherry with a thin curved green stem and one small leaf on top` |
| 1 | `Stroberi.png` | `a plump ball-shaped strawberry with tiny golden seeds and a small green calyx on top` |
| 2 | `Anggur.png` | `a single large round grape, deep purple fading to green near the top, with a tiny stem nub` |
| 3 | `Jeruk.png` | `a round orange with dimpled citrus peel texture and a small green leaf on top` |
| 4 | `Apel.png` | `a round red apple with a short brown stem and one small green leaf` |
| 5 | `Pir.png` | `a round yellow-green pear with freckled skin, a slender brown stem and one leaf on top` |
| 6 | `Persik.png` | `a round peach, blushing red-orange fading into soft yellow, with a subtle vertical crease` |
| 7 | `Nanas.png` | `a round pineapple with a golden diamond-lattice rind and a spiky green leaf crown on top` |
| 8 | `Melon.png` | `a round green cantaloupe melon with a pale netted web pattern over its rind` |
| 9 | `Semangka.png` | `a round whole watermelon with dark and light green vertical stripes` |

Ukuran badan buah **tidak** perlu diatur di prompt — semua digambar memenuhi frame,
`prepare_skin.py` yang menskalakan ke ukuran level masing-masing.

---

## 3. Blok ROUND — bikin semua buah bulat

Blok ini yang menjawab "bentuknya agak pada bulet". Tempel di setiap prompt badan buah.

```
Shape: the fruit is exaggerated into an almost perfect sphere, like a ball —
a chubby, plump, symmetrical round silhouette with no pointed tip, no taper and
no flat side. Real-world proportions are deliberately ignored in favor of a
round mascot shape. The sphere touches all four edges of the frame; only the
stem, leaf or crown may stick out above it.
```

---

## 4. Blok NO-FACE — supaya modelnya tidak iseng menambah mata

Model gambar cenderung menambahkan wajah sendiri kalau konteksnya terasa "karakter".
Blok ini wajib, dan jangan sebut kata *character* atau *mascot* di prompt badan buah.

```
Important: this is a plain fruit with NO face at all — no eyes, no mouth, no
eyebrows, no blush, no facial features of any kind, not even faint ones. Keep
the lower-center area of the fruit clean and evenly lit: no bright specular
highlight, no dark shading and no busy texture there, because a separate face
layer will be placed over that area later.
```

---

## 5. Blok TECHNICAL — selalu ditempel paling akhir

```
Technical: single fruit centered, filling the frame edge to edge, front view at
eye level, 1:1 square composition. Pure flat white #FFFFFF background. No drop
shadow, no ground plane, no reflection, no gradient in the background. No text,
no watermark, no border, no extra objects. Clean sharp cut-out silhouette.
```

---

## 6. Prompt wajah

### Wajah idle (mata diam)

```
A flat 2D kawaii face sheet for a game character, drawn as a standalone overlay.

Composition: only the facial features on an empty background — two eyes, a mouth
and two blush patches. Nothing else: no head, no face outline, no circle, no
fruit, no skin, no background shapes.

Layout: the two eyes sit side by side on the upper half, horizontally centered
as a pair, with a gap between their inner edges equal to about one eye width.
The mouth is centered directly below and between them. One blush patch sits
below and slightly outside each eye. The whole cluster is centered in the canvas
and spans about 55% of the canvas width.

Eyes: large glossy oval anime eyes, near-black, each with two white sparkle
highlights — one big at the upper left, one tiny four-point star at the lower
right — and short eyelashes at the outer corner.

Mouth: a small closed smile, a simple thin dark upward curve with rounded ends.

Blush: a soft pink oval, semi-transparent, with soft edges.

Technical: pure flat chroma green #00FF00 background, completely uniform. Front
view, perfectly straight on, no perspective, no tilt, no drop shadow, no glow
onto the background. 1:1 square. Crisp clean edges. No text, no watermark.
```

### Wajah panik (mata X) — **edit dari file idle**

Lampirkan PNG wajah idle, lalu:

```
Edit this image. Keep the canvas size, the chroma green #00FF00 background, and
the exact position and scale of every feature identical to the original — this
is frame 2 of a two-frame animation and it must register perfectly over frame 1.

Replace each eye with a bold dark X cross: two thick crossed strokes with
rounded ends, like a knocked-out cartoon character. Each X must be centered on
exactly the same point as the eye it replaces, and span the same width and
height as that eye.

Replace the smile with a small open worried mouth shaped like an upside-down U,
centered on the same point as the original mouth.

Fade both blush patches to a pale washed-out pink. Add a single large anime
sweat drop at the upper right of the cluster.

No other change.
```

---

## 7. Cara memasang wajah ke badan buah

Ada dua jalan. Keduanya butuh perubahan kode — sekarang
[fruit_sprites.dart](../lib/game/fruit_sprites.dart) hanya menggambar satu gambar per buah
dan menangani state bahaya dengan memucatkan warnanya lewat `ColorFilter.matrix`
(lihat baris 47-59), bukan menukar art.

**Jalan A — wajah sebagai gambar (sesuai prompt di atas).**
`FruitSprites` memuat 10 badan + 2 wajah. Saat menggambar: gambar badan dulu, lalu gambar
wajah di atasnya dengan lebar = `bodyDiameter × 0.55`, pusatnya digeser ke bawah sekitar
`bodyDiameter × 0.08`. Pilih file wajah idle atau X sesuai `FruitExpression`.

**Jalan B — wajah digambar oleh kode.** Wajahnya sederhana: dua elips, dua garis silang,
satu kurva mulut, dua blush. Versi web di proyek ini sudah melakukannya persis begitu
([fruit.js](../../fruit.js) — lihat `createFruitEl`, ada opsi `eyes: 'normal' | 'x'`).
Porting ke `Canvas` di Dart artinya nol asset tambahan, ekspresi bisa diubah lewat angka,
dan mata bisa dibikin ikut animasi (kedip, melirik ke arah gerak buah).

Kalau tujuannya "biar bisa di edit-edit", Jalan B lebih lincah; Jalan A menang kalau
gaya wajahnya ingin ikut material skin (mata jelly, mata clay, mata piksel). Bilang saja
mau yang mana, nanti saya kerjakan kodenya.
