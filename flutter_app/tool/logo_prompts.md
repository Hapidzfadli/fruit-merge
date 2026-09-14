# Prompt Nano Banana untuk logo aplikasi & splash

Dua gambar yang perlu dibuat, dipakai untuk hal yang berbeda:

| Gambar | Isi | Background | Dipakai di |
|---|---|---|---|
| **Ikon aplikasi** | satu buah besar, wajah kawaii | penuh, tanpa transparansi | ikon launcher Android/iOS, Play Store, favicon web |
| **Logo splash** | buah + ruang untuk nama app | transparan | layar pertama saat app dimuat |

Bedanya penting: ikon aplikasi **wajib** memenuhi kotak sampai ke tepi tanpa sudut membulat
— sistem operasi yang memotong bentuknya sendiri (lingkaran di satu HP, squircle di HP lain).
Logo splash justru sebaliknya: harus transparan dan mengambang di atas warna latar app.

---

## 0. Aturan wajib

### Ikon aplikasi

| Aturan | Alasan |
|---|---|
| **Tanpa sudut membulat, tanpa bingkai, tanpa bayangan di luar kotak** | launcher memotong bentuknya sendiri; sudut bawaan Anda akan terlihat dobel |
| **Tanpa transparansi**, warna penuh sampai ke tepi | App Store menolak ikon ber-alpha |
| Isi penting di **60% tengah** | Android adaptive icon memotong sampai ~61% dari sisi; apa pun di luar itu bisa hilang |
| **Tanpa teks/tulisan** | di 48px teks jadi bubur, dan model gambar hampir selalu salah mengeja |
| Satu subjek besar, kontras tinggi, detail minim | ikon dilihat pada 48px, bukan 1024px |
| Rasio 1:1, resolusi setinggi mungkin | dipakai turun sampai 512 dan 1024 |

### Logo splash

| Aturan | Alasan |
|---|---|
| Background **hijau chroma polos** (#00FF00) | dipotong pakai `cut_face.py` yang sudah ada |
| Isi penting di **⅔ tengah** kanvas | Android 12 memotong ikon splash jadi lingkaran 768px dari kanvas 1152px |
| Warna kontras terhadap krem **#FFF6EA** | itu warna layar boot di [main.dart](../lib/main.dart) |
| Tanpa teks | lihat catatan wordmark di bawah |

---

## 1. Konsep — dipakai di kedua prompt

Supaya ikon dan splash terasa satu keluarga, subjeknya harus sama. Saya pakai buah
teratas dari skin default, dengan wajah yang sama seperti di dalam game:

```
Subject: a glossy translucent gummy candy watermelon character — a perfectly round
ball with dark and light green vertical stripes and a tiny curled stem on top. It
has a big cheerful kawaii face: two large glossy oval near-black anime eyes with
white sparkle highlights, a small closed smile, and soft pink oval blush under each
eye. Bright, saturated, high-gloss candy finish.
```

Warna diambil langsung dari tema app di [theme.dart](../lib/ui/theme.dart):

| Peran | Hex |
|---|---|
| Coral terang → coral | `#FF8B6B` → `#FF6B4A` |
| Krem (latar app) | `#FFF6EA` |
| Kuning aksen | `#FFC845` |
| Mint aksen | `#C9F2E1` |

---

## 2. Prompt ikon aplikasi

```
A mobile game app icon for a fruit merge puzzle game.

Subject: a glossy translucent gummy candy watermelon character — a perfectly round
ball with dark and light green vertical stripes and a tiny curled stem on top. It has
a big cheerful kawaii face: two large glossy oval near-black anime eyes with white
sparkle highlights, a small closed smile, and soft pink oval blush under each eye.
Bright, saturated, high-gloss candy finish, lit from the upper left.

Composition: the watermelon is centered and large, filling about 60% of the square.
Two much smaller gummy fruits — a red cherry at the lower left and an orange at the
lower right — peek in from behind it, partly cropped by the edge. A few small white
sparkle stars float in the upper corners.

Background: a smooth warm coral gradient from #FF8B6B at the top to #FF6B4A at the
bottom, filling the entire square edge to edge with no border and no vignette.

Art style: high-end mobile game icon, clean vector-like shapes with soft 3D volume,
thick glossy highlights, chunky and readable, no fine detail or thin lines.

Technical: 1:1 square, full-bleed color to all four edges. NO rounded corners, NO
frame, NO border, NO outer drop shadow, NO transparency — the artwork must be a plain
opaque square. No text, no letters, no numbers, no watermark, no UI elements. Every
important element stays inside the central 60% of the square, because the outer band
gets cropped away.
```

**Uji sebelum lanjut:** kecilkan hasilnya jadi 48×48 px dan lihat. Kalau ceri dan
jeruknya jadi noda tak jelas, buang keduanya dari prompt dan pakai semangka saja.

### Varian foreground untuk Android adaptive icon (opsional)

Android bisa memisah ikon jadi lapisan depan + warna latar, lalu menganimasikannya
saat ditekan. Kalau mau itu, buat satu gambar lagi:

```
[prompt Subject dan Art style yang sama persis]

Composition: only the watermelon character, centered, filling about 55% of the
square. Nothing else — no other fruit, no sparkles.

Background: pure flat chroma green #00FF00, completely uniform, filling the whole
square. No shadow or glow spilling onto it.

Technical: 1:1 square. No text, no border, no rounded corners.
```

Potong hijaunya dengan script yang sudah ada:

```powershell
python tool/cut_face.py <folder>/icon_foreground.jpg --out assets/branding --size 1024
```

---

## 3. Prompt logo splash

```
A logo mark for the loading screen of a cute mobile fruit merge game.

Subject: a glossy translucent gummy candy watermelon character — a perfectly round
ball with dark and light green vertical stripes and a tiny curled stem on top. It has
a big cheerful kawaii face: two large glossy oval near-black anime eyes with white
sparkle highlights, a small closed smile, and soft pink oval blush under each eye.
Bright, saturated, high-gloss candy finish, lit from the upper left.

Composition: the watermelon sits centered, filling about 55% of the canvas height. A
smaller gummy cherry rests against its lower left and a smaller gummy orange against
its lower right, both overlapping it slightly so the three read as one cluster. Three
small white sparkle stars float above. The whole cluster stays inside the middle two
thirds of the canvas.

Colors must stay bright and saturated enough to read against a light cream #FFF6EA
background — no pale washed-out tones, no white outlines.

Background: pure flat chroma green #00FF00, completely uniform. No shadow, glow or
reflection spilling onto it.

Technical: 1:1 square, front view, no perspective. No text, no letters, no numbers,
no watermark, no frame.
```

Potong hijaunya:

```powershell
python tool/cut_face.py <folder>/splash_logo.jpg --out assets/branding --size 1152
```

### Soal tulisan "FRUIT MERGE"

Prompt di atas sengaja **melarang teks**. Model gambar hampir selalu salah mengeja
atau membuat huruf yang bengkok, dan Anda baru sadar setelah app terpasang. Nama app
lebih baik ditulis sebagai teks asli di Flutter — layar boot di
[main.dart](../lib/main.dart) sudah melakukannya, tinggal ganti `Text` jadi
`Column` berisi logo + nama.

Kalau tetap ingin wordmark jadi bagian gambar, tambahkan ini dan **periksa ejaannya
huruf per huruf**:

```
Below the fruit cluster, the words "FRUIT MERGE" in a thick rounded playful sans-serif
display font, bright coral #FF6B4A with a soft cream outline, all caps, correctly
spelled, on two lines.
```

---

## 4. Cara memasangnya

Belum ada tooling ikon di project ini, jadi tambahkan dulu:

```powershell
flutter pub add dev:flutter_launcher_icons dev:flutter_native_splash
```

Lalu di `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  image_path: assets/branding/app_icon.png
  android: true
  ios: true
  remove_alpha_ios: true
  web:
    generate: true
  # Kalau membuat varian foreground di §2:
  # adaptive_icon_background: "#FF6B4A"
  # adaptive_icon_foreground: assets/branding/icon_foreground.png

flutter_native_splash:
  color: "#FFF6EA"
  image: assets/branding/splash_logo.png
  android_12:
    color: "#FFF6EA"
    image: assets/branding/splash_logo.png
```

Warna `#FFF6EA` sengaja sama dengan layar boot di [main.dart](../lib/main.dart),
supaya perpindahan dari splash sistem ke layar Flutter tidak berkedip.

Generate:

```powershell
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Keduanya menulis langsung ke folder `android/`, `ios/` dan `web/` — bukan ke
`assets/` — jadi tidak perlu didaftarkan di `flutter:` `assets:`.

---

## 5. Cek terakhir

- Kecilkan ikon ke **48×48** dan lihat dari jarak sejengkal. Masih terbaca?
- Tempel ikon di atas kotak putih **dan** kotak hitam. Ada tepi terang yang aneh?
- Tumpuk logo splash di atas kotak **#FFF6EA**. Ada halo hijau sisa chroma?
  `cut_face.py` mencetak angka green-excess-nya; di bawah 10 aman.
- Potong ikon jadi lingkaran (simulasi launcher bulat). Ada bagian penting yang hilang?
