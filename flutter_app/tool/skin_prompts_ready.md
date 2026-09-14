# Prompt siap pakai — 10 badan buah + 2 wajah

Turunan dari [skin_prompts.md](skin_prompts.md), sudah dirakit penuh. Salin satu blok,
tempel ke Nano Banana.

**Tema yang dipakai di sini: Preset 1 — gummy jelly.** Paragraf `Art style:` sama persis
di kesepuluh prompt, jadi ganti tema = find-replace satu paragraf.

**Urutan kerja:**
1. §A — buat 10 badan buah polos. Simpan dengan nama file yang tertera; `prepare_skin.py` memetakan level dari nama itu.
2. §B — buat 1 wajah idle, lalu 1 wajah mata-X dengan **mengedit** file idle (bukan gambar baru).
3. §C — proses jadi asset.

**Tips konsistensi:** setelah Ceri (#0) jadi dan Anda suka hasilnya, untuk buah #1–#9
lampirkan PNG Ceri sebagai style reference dan tambahkan kalimat ini di awal prompt:
```
Use the attached image as the exact style reference: identical art style, material,
lighting, gloss and roundness. Only the fruit changes.
```

---

# §A — 10 badan buah (polos, tanpa wajah)

## 0 · Ceri → `Ceri.png`

```
A translucent gummy candy cherry for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a single round red cherry, deep ruby red jelly body, with a thin curved green
stem and one small leaf on top.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette with no pointed tip, no taper and no flat side.
Real-world proportions are deliberately ignored in favor of a round mascot shape. The
sphere touches all four edges of the frame; only the stem and leaf stick out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 1 · Stroberi → `Stroberi.png`

```
A translucent gummy candy strawberry for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a plump strawberry, bright scarlet jelly body, with tiny golden seeds dotted
evenly over the surface and a small green calyx of leaves on top.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette with NO pointed tip and no cone taper at the bottom;
this strawberry is a ball, not a heart or a cone. Real-world proportions are deliberately
ignored in favor of a round mascot shape. The sphere touches all four edges of the frame;
only the green calyx sticks out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 2 · Anggur → `Anggur.png`

```
A translucent gummy candy grape for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a single large grape, deep purple jelly fading to yellow-green near the top, with
a tiny brown stem nub at the very top. One single fruit only, not a bunch.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette with no pointed tip, no taper and no flat side.
Real-world proportions are deliberately ignored in favor of a round mascot shape. The
sphere touches all four edges of the frame; only the stem nub sticks out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 3 · Jeruk → `Jeruk.png`

```
A translucent gummy candy orange for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: an orange with dimpled citrus peel texture across the whole surface, vivid orange
jelly body, a small brown navel at the top and one small green leaf.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette with no pointed tip, no taper and no flat side.
Real-world proportions are deliberately ignored in favor of a round mascot shape. The
sphere touches all four edges of the frame; only the leaf sticks out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 4 · Apel → `Apel.png`

```
A translucent gummy candy apple for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a red apple, glossy crimson jelly body, with a shallow dimple at the top, a short
brown stem and one small green leaf.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette with no pointed tip, no taper and no flat side.
Real-world proportions are deliberately ignored in favor of a round mascot shape. The
sphere touches all four edges of the frame; only the stem and leaf stick out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 5 · Pir → `Pir.png`

```
A translucent gummy candy pear for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a yellow-green pear with faint brown freckles speckled over the skin, a slender
brown stem and one leaf on top.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette. This pear is a BALL, not the classic tall
narrow-shouldered pear silhouette: no taper, no neck, no pointed top. Real-world
proportions are deliberately ignored in favor of a round mascot shape. The sphere touches
all four edges of the frame; only the stem and leaf stick out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 6 · Persik → `Persik.png`

```
A translucent gummy candy peach for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a peach blushing red-orange at the top left and fading into soft warm yellow,
with a subtle vertical crease down the center, a soft velvety fuzz along the rim and a
tiny green leaf at the top.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette with no pointed tip, no taper and no flat side.
Real-world proportions are deliberately ignored in favor of a round mascot shape. The
sphere touches all four edges of the frame; only the leaf sticks out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 7 · Nanas → `Nanas.png`

```
A translucent gummy candy pineapple for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a pineapple with a golden diamond-lattice rind pattern and a spiky green leaf
crown standing straight up on top.

Shape: the body is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette, NOT the tall barrel shape of a real pineapple.
Real-world proportions are deliberately ignored in favor of a round mascot shape. The
sphere touches all four edges of the frame; only the crown sticks out above it, pointing
strictly upward in a narrow tuft and never spreading sideways past the sphere.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 8 · Melon → `Melon.png`

```
A translucent gummy candy melon for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a green cantaloupe melon with a pale raised netted web pattern spreading evenly
over its rind, and a tiny curled stem at the top. Whole and uncut.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette with no pointed tip, no taper and no flat side.
Real-world proportions are deliberately ignored in favor of a round mascot shape. The
sphere touches all four edges of the frame; only the stem sticks out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

## 9 · Semangka → `Semangka.png`

```
A translucent gummy candy watermelon for a mobile game icon set.

Art style: translucent gummy candy, semi-transparent jelly material with visible
sugar-crystal coating on the surface, deep internal glow as if lit from inside, thick
glossy specular highlight in the upper-left, saturated candy colors, smooth rounded
volume, high-end mobile game icon quality, soft studio lighting from the upper left.

Subject: a whole watermelon with dark and light green vertical stripes curving over its
surface, and a tiny curled stem at the top. Whole and uncut, no visible red flesh.

Shape: the fruit is exaggerated into an almost perfect sphere, like a ball — a chubby,
plump, symmetrical round silhouette with no pointed tip, no taper and no flat side.
Real-world proportions are deliberately ignored in favor of a round mascot shape. The
sphere touches all four edges of the frame; only the stem sticks out above it.

Important: this is a plain fruit with NO face at all — no eyes, no mouth, no eyebrows, no
blush, no facial features of any kind, not even faint ones. Keep the lower-center area of
the fruit clean and evenly lit: no bright specular highlight, no dark shading and no busy
texture there, because a separate face layer will be placed over that area later.

Technical: single fruit centered, filling the frame edge to edge, front view at eye level,
1:1 square composition. Pure flat white #FFFFFF background. No drop shadow, no ground
plane, no reflection, no gradient in the background. No text, no watermark, no border, no
extra objects. Clean sharp cut-out silhouette.
```

---

# §B — 2 file wajah

## Wajah idle → `face_idle.png`

Kirim sebagai prompt baru (bukan edit).

```
A flat 2D kawaii face sheet for a game character, drawn as a standalone overlay.

Composition: only the facial features on an empty background — two eyes, a mouth and two
blush patches. Nothing else: no head, no face outline, no circle, no fruit, no skin, no
background shapes.

Layout: the two eyes sit side by side on the upper half, horizontally centered as a pair,
with a gap between their inner edges equal to about one eye width. The mouth is centered
directly below and between them. One blush patch sits below and slightly outside each eye.
The whole cluster is centered in the canvas and spans about 55% of the canvas width.

Eyes: large glossy oval anime eyes, near-black, each with two white sparkle highlights —
one big at the upper left, one tiny four-point star at the lower right — and short
eyelashes at the outer corner.

Mouth: a small closed smile, a simple thin dark upward curve with rounded ends.

Blush: a soft pink oval, semi-transparent, with soft edges.

Technical: pure flat chroma green #00FF00 background, completely uniform. Front view,
perfectly straight on, no perspective, no tilt, no drop shadow, no glow onto the
background. 1:1 square. Crisp clean edges. No text, no watermark.
```

## Wajah mata X → `face_x.png`

**Lampirkan `face_idle.png`**, lalu kirim ini sebagai edit.

```
Edit this image. Keep the canvas size, the chroma green #00FF00 background, and the exact
position and scale of every feature identical to the original — this is frame 2 of a
two-frame animation and it must register perfectly over frame 1.

Replace each eye with a bold dark X cross: two thick crossed strokes with rounded ends,
like a knocked-out cartoon character. Each X must be centered on exactly the same point as
the eye it replaces, and span the same width and height as that eye.

Replace the smile with a small open worried mouth shaped like an upside-down U, centered
on the same point as the original mouth.

Fade both blush patches to a pale washed-out pink. Add a single large anime sweat drop at
the upper right of the cluster.

No other change.
```

**Cek sebelum lanjut:** tumpuk `face_idle.png` dan `face_x.png` di Photopea, atur layer
atas ke blend mode *Difference*. Kalau blush dan area kosongnya jadi hitam pekat,
registrasinya benar. Kalau ada bayangan tepi di mana-mana, mintakan ulang editnya.

---

# §C — Proses jadi asset

**Badan buah** lewat script yang sudah ada:

```powershell
python tool/prepare_skin.py <folder_badan_buah> gummy_kawaii --dry-run
python tool/prepare_skin.py <folder_badan_buah> gummy_kawaii
```

Jalankan `--dry-run` dulu dan periksa baris pemetaannya (`00 ceri <- Ceri.png` dst).

**File wajah** lewat script terpisah — `prepare_skin.py` tidak bisa memprosesnya, script
itu mencari "lingkaran terbesar di dalam gambar" yang khusus logika buah:

```powershell
python tool/cut_face.py <folder_wajah>/face_idle.jpg <folder_wajah>/face_x.jpg --out assets/skins/gummy_kawaii
```

Hasil akhirnya:

```
assets/skins/gummy_kawaii/
  00_ceri.png … 09_semangka.png   (dari script)
  manifest.json                    (dari script)
  face_idle.png                    (manual)
  face_x.png                       (manual)
```

Lalu daftarkan foldernya di `pubspec.yaml` dan tambah entri di
[skin_data.dart](../lib/models/skin_data.dart).

Terakhir, kodenya perlu diubah supaya mau menggambar layer wajah — sekarang
[fruit_sprites.dart](../lib/game/fruit_sprites.dart) satu gambar per buah dan state bahaya
cuma dipucatkan lewat `ColorFilter.matrix`. Lihat bagian 7 di
[skin_prompts.md](skin_prompts.md) untuk dua pilihan cara memasangnya.
