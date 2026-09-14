# Fruit Merge Adventure — Dokumentasi Logika Game

Dokumen ini menjelaskan **seluruh logika** di balik game, file per file, sistem per sistem. Game ini bergenre *merge/drop* ala Suika Game / Watermelon Game: pemain menjatuhkan buah ke dalam wadah, dua buah dengan level sama yang bertabrakan akan melebur (*merge*) jadi satu buah dengan level lebih besar, dan permainan berakhir jika buah menumpuk melewati garis batas atas terlalu lama.

Tidak ada canvas — seluruh visual dirender sebagai elemen **DOM** (`div` dengan CSS), sedangkan simulasi tabrakan/gravitasi ditangani oleh library eksternal **Matter.js**. Setiap frame, posisi hasil simulasi fisika "disalin" ke posisi CSS elemen DOM.

---

## 1. Struktur File

| File | Peran |
|---|---|
| `index.html` | Shell HTML, memuat font, memuat `matter.min.js` (physics engine) dari CDN, lalu `fruit.js` → `audio.js` → `app.js` secara berurutan. |
| `fruit.js` | Modul **presentasional murni**: fungsi untuk membuat elemen DOM "wajah buah" (bulat, mata, pipi, mulut, topper). Tidak menyimpan state apa pun. |
| `audio.js` | Modul **audio sintesis**: semua efek suara & musik dibuat langsung lewat Web Audio API (osilator), tidak ada file `.mp3`/`.wav`. |
| `app.js` | **Otak game**: state, physics, UI, navigasi antar layar, skor, ekonomi koin, shop. Semua logika inti ada di sini (~750 baris). |
| `style.css` | Styling visual (tidak dibahas detail di sini karena bukan "logic"). |

Ketiga script JS dibungkus IIFE (`(function(){...})()`) dan saling berkomunikasi lewat objek global: `window.FruitUI`, `window.GameAudio`.

---

## 2. Data Model

### 2.1 Daftar Level Buah — `FRUITS` (app.js:5-16)

Array 10 elemen, index 0 = buah terkecil (Ceri), index 9 = terbesar (Semangka):

```js
{ name, size, colorA, colorB, topper }
```

- `size`: diameter buah dalam px — sekaligus dipakai sebagai diameter *collision circle* di physics engine.
- `colorA`/`colorB`: dua warna untuk `radial-gradient` badan buah (efek bulat mengkilap).
- `topper`: dekorasi opsional (`'leaf'`/`'crown'`/`'none'`) yang digambar oleh `fruit.js`.

Level dan urutan: Ceri → Stroberi → Anggur → Jeruk → Apel → Pir → Persik → Nanas → Melon → Semangka.

Index buah **adalah** "level" — logika merge, skor, dan ukuran collision semuanya mengacu ke index ini, bukan nama.

### 2.2 Daftar Skin — `SKINS` (app.js:18-23)

Kosmetik yang mengubah warna & topper buah (bukan gameplay). Tiap skin punya `price` koin. `classic` dan `crystal` gratis (`price: 0`), dua lainnya berbayar.

> **Catatan:** Skin di-*define* di sini tapi saat bermain, kode yang benar-benar menggambar buah di papan (`syncBoardDom`) memakai warna dari `FRUITS`, **bukan** dari `SKINS` yang sedang di-equip. Jadi secara fungsional, skin yang dibeli saat ini hanya terlihat efeknya di layar **Shop**, belum diterapkan ke buah in-game. Ini kemungkinan besar fitur yang belum selesai diimplementasikan (lihat bagian 12 "Catatan & Potensi Isu").

---

## 3. Konstanta Global (app.js:25-34)

```js
BOARD_WIDTH = 300      // lebar area permainan (px, unit internal)
BOARD_HEIGHT = 460
WALL = 8                // ketebalan dinding kiri/kanan
PW = BOARD_WIDTH - WALL*2   // lebar area main efektif (dalam dinding)
PH = BOARD_HEIGHT - WALL    // tinggi area main efektif
LINE_Y = 40             // garis batas atas — buah yang menumpuk di atas ini = bahaya
MERGE_SCORE = [0,20,40,70,110,160,230,320,440,600]  // skor per level hasil merge
SPAWN_ANIM = 300        // durasi animasi "squash & stretch" saat buah baru muncul (ms)
OVER_LIMIT = 1000       // batas waktu (ms) buah boleh diam di atas LINE_Y sebelum game over
DROP_COOLDOWN = 320     // jeda minimum antar drop (ms), anti-spam klik
```

`MERGE_SCORE[i]` dibaca berdasarkan **index buah hasil merge**. Karena index 0 tidak pernah menjadi hasil merge (buah terkecil tidak bisa dihasilkan dari merge), elemen pertama bernilai 0 (placeholder).

---

## 4. State & Persistence (app.js:36-77)

### 4.1 Struktur `state`

Satu objek tunggal menyimpan seluruh kondisi game:

```js
state = {
  screen,          // layar aktif: 'menu' | 'game' | 'pause' | 'gameover' | 'shop' | 'settings'
  score,           // skor run saat ini
  highScore,       // skor tertinggi sepanjang waktu
  currentIndex,    // index buah yang sedang dipegang/siap dijatuhkan
  nextIndex,       // index buah antrian berikutnya (preview)
  dropX,           // posisi X drop dalam persen (0-100)
  music, sfx, vibration,   // toggle pengaturan
  equippedSkin, ownedSkins, coins  // ekonomi & kosmetik
}
```

### 4.2 Load/Save — `loadSave()` & `persist()`

- `loadSave()` membaca `localStorage['fruitMergeAdventure.save']`, di-parse JSON. Kalau tidak ada/rusak → **fallback default** (`highScore: 1280, coins: 340, ...` — nilai awal yang sengaja "sudah terisi" supaya menu awal tidak terasa kosong).
- `persist()` dipanggil setiap kali ada perubahan yang perlu disimpan: toggle setting, beli/equip skin, atau game over (skor & koin baru).
- **Yang TIDAK dipersist**: `score` per-run, `currentIndex`/`nextIndex` — karena itu state sementara, direset tiap `startGame()`.

### 4.3 `randomDropIndex()` (app.js:61)

```js
Math.floor(Math.random() * 5)
```

Buah yang bisa **dijatuhkan pemain** (baik `currentIndex` maupun `nextIndex`) selalu diacak dari **5 level pertama saja** (Ceri..Apel). Buah level 6 ke atas hanya bisa didapat lewat hasil merge, sehingga kesulitan game terjaga (tidak tiba-tiba dapat buah besar dari langit).

---

## 5. Sistem Render Buah — `fruit.js`

Modul ini murni fungsi pembuat tampilan, dipanggil dari `app.js` setiap kali sebuah buah perlu digambar (di papan, preview, shop, dsb).

### 5.1 `createFruitEl(opts)`

Membuat satu `<div class="fruit-face">` bulat dengan:
- **Badan**: `radial-gradient(colorA → colorB)` + beberapa `box-shadow` inset untuk efek highlight/shadow 3D semu.
- **Topper** opsional: daun (`leaf`) atau mahkota segitiga (`crown`) memakai `clip-path`.
- **Kilau (shine)**: elips putih transparan di pojok atas kiri, memberi kesan glossy.
- **Mata**: dua varian —
  - Normal: bulatan gelap + kilau kecil putih.
  - `eyes: 'x'`: dua garis silang (mata "mati/pusing") — dipakai untuk state khusus (walau saat ini tidak terlihat dipanggil di `app.js` dengan `eyes:'x'`, jadi fitur tersedia tapi belum dipakai).
- **Pipi (blush)**: dua elips merah muda transparan.
- **Mulut**: lengkung senyum (`border-bottom` radius) atau mulut "X" kalau `eyes==='x'`.

Semua ukuran elemen (mata, pipi, mulut) dihitung **proporsional terhadap `size`** (mis. `eye = size * 0.10`), sehingga fungsi ini bisa dipakai untuk buah ukuran berapa pun (dari 20px preview kecil sampai 122px Semangka) dengan proporsi wajah tetap konsisten.

### 5.2 Ekspor

`window.FruitUI = { createFruitEl, applyStyle, el }` — `el()` dan `applyStyle()` adalah helper umum pembuat elemen + apply style object (dipakai luas juga di `app.js` untuk membangun UI, bukan cuma buah).

---

## 6. Sistem Audio — `audio.js`

Tidak ada aset audio eksternal. Semua suara **disintesis real-time** dengan Web Audio API.

### 6.1 `tone(freq, opts)` — primitif dasar

Membuat satu `OscillatorNode` + `GainNode`:
- `type`: bentuk gelombang (`sine`, `triangle`, `square`, `sawtooth`) — menentukan karakter suara (lembut vs tajam).
- **Envelope amplitudo manual**: gain naik cepat dari 0 → target dalam 0.01s (attack), lalu meluruh eksponensial ke ~0 (`exponentialRampToValueAtTime`) — meniru pluck/decay alami, mencegah klik/pop di awal-akhir suara.
- `glideTo`: opsional, frekuensi osilator "meluncur" naik/turun selama durasi bunyi (pitch bend) — dipakai untuk efek "pop" pada drop & merge.
- `delay`: menunda mulainya nada, dipakai untuk menyusun akor/arpeggio dari beberapa panggilan `tone()`.

### 6.2 Efek Suara (`SFX`)

| Efek | Logika |
|---|---|
| `drop()` | Satu nada segitiga turun 320→220Hz, pendek — kesan "plop" jatuh. |
| `merge(index)` | Frekuensi dasar naik seiring `index` (`260 + index*28`, dibatasi maks index 9) — **makin besar buah yang dihasilkan, makin tinggi & "megah" nadanya**. Terdiri dari 2 nada (dasar + 1.5x oktaf dengan delay) untuk kesan chime. |
| `gameOver()` | 4 nada sawtooth menurun (440→220Hz) berurutan dengan delay — kesan "turun/kalah" klasik. |
| `click()` | Nada square pendek, generic UI feedback. |
| `buy()` | 2 nada naik (520→780Hz) — kesan "cha-ching" positif. |

### 6.3 Musik Latar — `startMusic()`/`stopMusic()`

Loop sederhana: 4 not (`C4-E4-G4-E4`) dimainkan bergantian tiap 1.7 detik lewat `setInterval`, masing-masing dengan envelope gain naik-turun perlahan (fade in 0.4s, fade out ke 1.6s) supaya terdengar seperti pad lembut, bukan beep kasar. `master` gain node menjaga volume musik tetap pelan (`0.05`) relatif terhadap SFX.

`musicNodes` dipakai sebagai flag "musik sedang jalan" — `startMusic()` no-op kalau sudah ada, `stopMusic()` membersihkan interval + disconnect node.

### 6.4 `vibrate(ms)`

Wrapper tipis atas `navigator.vibrate()` (haptic feedback di device yang mendukung).

### 6.5 Wiring ke state di app.js (app.js:79-86)

`app.js` tidak memanggil `SFX`/`vibrate` langsung — dibungkus lagi lewat objek `Sfx` & fungsi `doVibrate()` yang **mengecek toggle setting user** (`state.sfx`, `state.vibration`) sebelum benar-benar membunyikan. Ini satu-satunya tempat pengecekan on/off dilakukan, jadi seluruh pemanggil di kode lain tidak perlu peduli soal setting.

---

## 7. Arsitektur UI & Navigasi (app.js)

### 7.1 Prinsip: "Build Once, Toggle Visibility"

Semua 6 layar (`menu`, `game`, `pause` overlay, `gameover`, `shop`, `settings`) **dibangun sekali** saat boot (`buildMenuScreen()`, dst dipanggil di bagian "Boot") dan ditambahkan semua ke `phoneScreen`. Navigasi antar layar **tidak** membuat/menghapus DOM, melainkan hanya toggle class `.active` lewat `renderScreenVisibility()` (app.js:471-479) berdasarkan `state.screen`.

Keuntungan pendekatan ini: transisi cepat (tidak ada re-render mahal), state internal tiap layar (misalnya posisi scroll shop) tidak hilang saat pindah layar.

### 7.2 Fungsi Navigasi (app.js:481-494)

```
goHome()      → stop musik, screen = 'menu'
goShop()      → render ulang grid shop + update tampilan koin, screen = 'shop'
goSettings()  → screen = 'settings'
pauseGame()   → stop musik, screen = 'pause'  (overlay di atas game, board tetap ter-render di belakang)
resumeGame()  → screen = 'game', lanjutkan musik jika toggle music aktif
```

`pause` bukan layar terpisah dari game — ia adalah **overlay** yang muncul di atas `screen-game` (lihat `renderScreenVisibility`: kondisi `gameLike` membuat layar game tetap `.active` saat status `pause`, ditambah overlay pause `.active`). Ini penting: physics **tidak otomatis berhenti** hanya karena overlay muncul — lihat bagian 8.6.

### 7.3 `fitPhone()` (app.js:99-109)

Bukan logika gameplay, tapi logika **responsif**: menghitung skala mockup "phone frame" (didesain fixed 375×812, ala iPhone) supaya muat di viewport browser berapa pun ukurannya, dengan `Math.min(1, availW/375, availH/812)` — tidak pernah di-scale lebih besar dari 100%.

---

## 8. Physics Engine — Inti Gameplay (app.js:496-568)

Menggunakan **Matter.js**, sebuah 2D rigid-body physics engine.

### 8.1 Inisialisasi — `initPhysics()`

```js
engine.gravity.y = 1.9          // gravitasi lebih kuat dari default (1) → jatuh lebih cepat/tegas
engine.positionIterations = 14  // iterasi solver posisi — makin tinggi, makin akurat tapi makin berat CPU
engine.velocityIterations = 12
engine.constraintIterations = 4
```

Nilai iterasi solver dinaikkan cukup tinggi dari default Matter.js (biasanya 6/4) — ini pilihan sengaja supaya tumpukan buah **stabil** (tidak jitter/menembus satu sama lain) walau ditumpuk sampai puluhan buah.

**Dinding statis** dibuat dari 3 rectangle raksasa (lantai + dinding kiri + dinding kanan), `isStatic: true` dengan friksi tinggi (`0.75`/`0.9`) dan `restitution: 0` (tidak memantul dari dinding).

### 8.2 Deteksi Merge — `collisionStart` (app.js:515-524)

```js
M.Events.on(engine, 'collisionStart', (ev) => {
  for (const pair of ev.pairs) {
    const a = pair.bodyA, b = pair.bodyB;
    if (!a.plugin || !b.plugin || a.plugin.dead || b.plugin.dead) continue;
    if (a.plugin.index !== b.plugin.index) continue;
    if (a.plugin.index >= FRUITS.length - 1) continue;
    a.plugin.dead = true; b.plugin.dead = true;
    mergeBodies(a, b);
  }
});
```

Logika langkah demi langkah:
1. Setiap pasangan body yang baru mulai bersentuhan di frame ini dicek.
2. Abaikan jika salah satu bukan buah (`.plugin` tidak ada — dinding tidak punya plugin) atau **sudah ditandai mati** (`dead`) — penting untuk mencegah **double-merge** dalam satu event batch (kalau satu buah bertabrakan dengan 2 buah kembar sekaligus di frame yang sama, hanya pasangan pertama yang diproses).
3. Hanya merge jika **index sama** (level sama).
4. Tidak merge jika sudah di level maksimum (`Semangka` + `Semangka` = tidak terjadi apa-apa, karena tidak ada level 11).
5. Tandai `dead = true` **sebelum** memanggil `mergeBodies` — flag ini dicek lagi di iterasi pair berikutnya dalam loop yang sama untuk mencegah body yang sama diproses dua kali.

### 8.3 Spawn Buah — `spawnFruit(index, x, y, extra)` (app.js:532-550)

Membuat body lingkaran Matter.js dengan properti fisik **berbeda per level**:

```js
restitution: index <= 2 ? 0.16 : Math.max(0.02, 0.14 - index*0.02)
friction:    index <= 2 ? 0.42 : 0.58
```

Artinya: **buah kecil (Ceri, Stroberi, Anggur) memantul sedikit lebih kenyal dan licin**, sedangkan buah besar makin ke atas makin "berat/tidak memantul" dan makin bergesekan (grippy) — mensimulasikan kesan buah besar seperti Semangka lebih "mantap" saat mendarat, tidak menggelinding liar.

`body.plugin` menyimpan metadata custom di luar sistem fisika standar Matter.js:
```js
{ isFruit: true, index, spawnAt, flash, overMs, dead }
```
- `spawnAt`: timestamp lahir, dipakai animasi squash-stretch (bagian 8.5) dan cegah false game-over pada buah yang baru saja spawn (bagian 8.4).
- `flash`: intensitas ring animasi "kilau merge" (1 → 0 mengecil tiap frame).
- `overMs`: akumulasi waktu buah ini berada "berbahaya" di atas garis (bagian 8.4).
- `dead`: flag sudah dihapus/di-merge, mencegah pemrosesan ganda.

Kecepatan angular awal diberi sedikit randomize (`(Math.random()-0.5)*0.06`) supaya buah tidak terlihat kaku/identik saat jatuh.

### 8.4 Deteksi Game Over — `postStep(now)` (app.js:552-568)

Dipanggil tiap frame setelah physics step. Untuk **setiap buah** di papan:

1. **Peredam rotasi buatan** (bukan bawaan Matter.js): kecepatan angular diredam lebih agresif kalau kecepatan linear rendah (`speed < 0.35` → damping `0.55`, else `0.9`) — mencegah buah "muter-muter" pelan tanpa henti di lantai, terlihat lebih natural/settle.
2. Kalau buah nyaris diam (`speed < 0.06` dan `angularVelocity` kecil) → **paksa berhenti total** (velocity & angular = 0). Ini trik umum di game fisika untuk mencegah jitter mikroskopis tak berujung akibat presisi floating point.
3. `flash` diturunkan bertahap (dipakai animasi ring, bagian 8.5).
4. **Logika inti game-over**:
   ```js
   const settled = speed < 0.6;
   const age = now - spawnAt;
   if (age > 500 && settled && position.y - radius < LINE_Y) overMs += 16.7;
   else overMs = 0;
   if (overMs > OVER_LIMIT) gameOver();
   ```
   - Buah dihitung "melanggar garis" hanya jika: **sudah berumur >500ms** (baru spawn tidak langsung dihitung — beri waktu jatuh), **sudah relatif diam** (`settled`), **dan** bagian atasnya (`position.y - radius`, yaitu titik teratas lingkaran) berada di atas `LINE_Y`.
   - Kalau salah satu syarat tidak terpenuhi, `overMs` **direset ke 0** (bukan berkurang pelan — reset total). Artinya timer bahaya hanya terus berjalan kalau buah itu **terus-menerus** diam dan melanggar garis; begitu bergerak sedikit saja atau turun di bawah garis, hitungannya nol lagi.
   - `overMs` bertambah `16.7`ms per panggilan (asumsi ~60fps), sampai melewati `OVER_LIMIT` (1000ms) → `gameOver()` dipanggil dan fungsi langsung `return` (stop cek buah lain di frame itu).

   > **Catatan penting**: timer ini per-body, bukan agregat papan. Game over terpicu begitu **ada satu buah saja** yang diam >1 detik menembus garis batas — bukan berdasarkan total tumpukan atau jumlah buah.

### 8.5 Sinkronisasi Fisika → DOM — `syncBoardDom()` (app.js:595-631)

Dipanggil tiap frame (dari `tick()`), untuk tiap body fisika aktif:

1. **Reuse elemen DOM**: `bodyEls` adalah `Map<bodyId, {wrap, ring}>`. Kalau body baru (belum ada di map), baru dibuat elemen `<div class="board-fruit">` isi `createFruitEl(...)` + elemen `<div class="ring">` (untuk efek flash merge). Body lama tinggal update posisi — **tidak membuat elemen baru tiap frame** (penting untuk performa).
2. **Animasi spawn (squash & stretch)**:
   ```js
   p = min(1, (now - spawnAt) / SPAWN_ANIM)         // progres 0..1 selama 300ms
   amp = 0.26 * (1-p) * cos(p * PI * 2.2)            // amplitudo osilasi meredam
   sx = 1 + amp; sy = 1 - amp;                       // scale X naik saat Y turun, bergantian
   ```
   Ini menghasilkan efek buah "bergoyang kenyal" sesaat setelah muncul (baik dari drop maupun hasil merge) — meniru jelly/squash animation khas game merge, lalu meredam ke ukuran normal (`amp → 0` saat `p → 1`).
3. **Rotasi visual dibatasi**: sudut rotasi asli dari physics (`b.angle`) di-clamp ke rentang `-18°..18°` — buah divisualisasikan tidak pernah miring lebih dari itu meski secara fisika sebenarnya bisa berputar penuh (mencegah kesan aneh buah "guling-guling" di layar walau datanya valid secara fisika).
4. **Efek ring flash**: kalau `plugin.flash > 0.02`, ring ditampilkan dengan opacity = nilai flash dan scale membesar seiring flash meluruh — efek "gelombang kejut" saat dua buah baru saja merge.
5. **Cleanup**: body yang sudah tidak ada di world (di-merge/dihapus) tapi elemennya masih ada di `bodyEls` → dihapus dari DOM & map (`seen` Set dipakai untuk diff antara body aktif vs elemen DOM lama).

### 8.6 Game Loop — `tick(now)` (app.js:633-642)

```js
function tick(now) {
  if (engine && state.screen === 'game') {
    M.Engine.update(engine, 1000/120);   // substep 1
    M.Engine.update(engine, 1000/120);   // substep 2
    postStep(now);
    syncBoardDom();
  }
  raf = requestAnimationFrame(tick);
}
```

- Physics di-update **2× per frame** dengan step tetap `1000/120` detik (bukan langsung memakai delta time nyata dari `requestAnimationFrame`) — ini adalah **fixed timestep** dengan 2 substep, memberi presisi simulasi setara 120Hz meski render hanya di ~60fps layar. Ini membuat tumpukan buah lebih stabil dibanding 1 update per frame di `1000/60`.
- **Physics HANYA berjalan kalau `state.screen === 'game'`** — artinya saat `pause` (bukan `'game'`), tidak ada update fisika maupun sync DOM sama sekali; papan otomatis "membeku" secara visual karena tidak ada perubahan yang diproses. Ini kenapa `pauseGame()` tidak perlu logika eksplisit untuk "membekukan" body satu-satu — cukup mengganti `state.screen`.
- `raf` loop terus berjalan (request terus di-schedule) walau kondisi `if` gagal — hanya bagian dalam `if` yang di-skip, bukan seluruh loop `requestAnimationFrame`.

### 8.7 Reset Papan — `resetBoard()` (app.js:644-652)

Dipanggil di awal `startGame()`: menghapus semua body buah dari `engine.world` dan semua elemen DOM terkait dari `bodyEls`, mengembalikan papan ke keadaan kosong bersih.

---

## 9. Interaksi Drop — Input Pemain (app.js:669-729)

### 9.1 `handleBoardMove(e)` — mengikuti pointer

```js
pct = ((e.clientX - rect.left) / rect.width) * 100
pct = clamp(pct, 8, 92)
state.dropX = pct
```

Posisi drop disimpan sebagai **persentase lebar papan** (bukan pixel absolut) — membuatnya independen dari skala `fitPhone()`. Di-clamp ke 8%-92% supaya "pemandu drop" (`dropGuide`/`dropPreview`) tidak pernah keluar/menempel persis di tepi papan secara visual.

### 9.2 `dropFruit()` — eksekusi drop (dipicu klik/tap di papan)

1. Guard: tidak berlaku kalau bukan `state.screen === 'game'`.
2. **Cooldown check**: `Date.now() - lastDrop < DROP_COOLDOWN` → diabaikan. Mencegah pemain spam-klik menjatuhkan puluhan buah sekaligus.
3. Hitung posisi X aktual dalam koordinat physics dari persen `dropX`, lalu **clamp ulang** berdasarkan radius buah spesifik (`r = FRUITS[idx].size/2`) supaya buah besar tidak spawn menembus dinding kalau `dropX` dekat tepi.
4. `spawnFruit(idx, x, r+2, {vx:0, vy:2})` — spawn tepat di bawah garis (`y = r+2`, dekat puncak papan) dengan sedikit kecepatan jatuh awal (`vy: 2`) supaya animasi drop terasa "dilempar", bukan diam lalu jatuh.
5. Mainkan SFX `drop`, lalu **rotasi antrian**: `currentIndex = nextIndex`, `nextIndex = randomDropIndex()` baru — pola antrian "current + next" klasik ala Tetris/Suika, pemain selalu tahu buah setelah ini.
6. Update preview visual buah saat ini & berikutnya.

### 9.3 Preview

- `renderCurrentFruitPreview()`: menggambar ulang buah besar di posisi drop guide (`dropPreview`), memakai ukuran asli buah (`FRUITS[currentIndex].size`).
- `updateNextPreview()`: menggambar buah kecil (fixed 34px, tidak proporsional ukuran asli — supaya slot "Next" di topbar konsisten ukurannya) untuk preview antrian.
- `updateDropPreview()`: menyinkronkan posisi CSS `left` tiga elemen (`dropGuide`, `dropShadow`, `dropPreview`) mengikuti `state.dropX`.

---

## 10. Sistem Skor & Ekonomi

### 10.1 Skor

Ditambahkan **hanya** saat merge terjadi (app.js:581): `state.score += MERGE_SCORE[newIndex]`. Tidak ada skor dari drop biasa — murni reward dari hasil merge, mendorong pemain menyusun strategi merge berantai (chain) untuk skor lebih tinggi.

`spawnScorePop(x,y,amount)` (app.js:588-593) menampilkan teks `+N` mengambang sesaat di lokasi merge (dihapus otomatis via `setTimeout` 750ms) — feedback visual instan.

### 10.2 Koin (mata uang shop)

Koin **hanya** didapat saat game over (app.js:656-657):
```js
earned = Math.floor(state.score / 10)
state.coins += earned
```
Konversi tetap 10 skor = 1 koin, dibulatkan ke bawah. Tidak ada cara mendapat koin lain (tidak ada iklan reward, tidak ada achievement) di kode saat ini.

### 10.3 `gameOver()` — Rangkuman Alur (app.js:654-667)

1. Update `highScore` jika skor run ini lebih tinggi.
2. Hitung & tambahkan koin.
3. `persist()` — simpan permanen.
4. Mainkan SFX game over + vibrasi (60ms, lebih panjang dari feedback lain — menegaskan momen penting).
5. Stop musik latar.
6. Update teks di layar Game Over (skor, best, baris "+N coins earned" — kosong string kalau `earned === 0`).
7. Pindah `state.screen = 'gameover'`.

---

## 11. Shop & Sistem Skin (app.js:349-429)

### 11.1 Render grid — `renderShopGrid()`

Untuk tiap skin di `SKINS`, kartu ditampilkan dalam 3 kemungkinan state:
- **Equipped** (skin ini sedang dipakai): badge "Equipped", tidak ada tombol aksi.
- **Owned tapi belum dipakai**: tombol "Equip" → `state.equippedSkin = sk.id`, persist, re-render grid.
- **Belum dimiliki**: tombol gembok menampilkan harga.
  - Kalau `state.coins < sk.price` → klik hanya memicu SFX klik + animasi `shake(card)` (CSS animation `bought .5s ease` dipicu ulang lewat trik `style.animation = 'none'; void offsetWidth; style.animation = '...'` — reset paksa animasi CSS supaya bisa retrigger meski class/nilai sama).
  - Kalau cukup koin → `coins -= price`, tambahkan ke `ownedSkins`, langsung **auto-equip** skin yang baru dibeli, SFX `buy`, vibrasi 20ms, persist, re-render grid + update tampilan koin.

### 11.2 Kombinasi harga & kepemilikan awal

Dari `loadSave()`: default `ownedSkins = ['classic', 'crystal']` dan koin awal `340`. Karena `crystal` harganya `0`, ia sebenarnya "gratis" bahkan tanpa perlu ada di `ownedSkins` default — tapi disertakan eksplisit agar konsisten muncul sebagai "owned" sejak awal tanpa pemain perlu "membeli" barang gratis.

---

## 12. Pengaturan (Settings) & Toggle (app.js:432-494)

Tiga toggle: `music`, `sfx`, `vibration` — direpresentasikan sebagai custom switch (`buildSwitch`) yang mensinkronkan class `.on`/`.off` berdasarkan getter state.

- `toggleMusic()`: selain flip state, **langsung** memulai/menghentikan `startMusic()`/`stopMusic()` **hanya jika** `state.screen === 'game'` — supaya toggle musik di menu pause/menu tidak salah memicu musik main padahal harusnya diam.
- `toggleSfx()`/`toggleVibration()`: murni flip flag + persist — efeknya baru terasa di pemanggilan SFX/vibrate berikutnya (via wrapper `Sfx`/`doVibrate` di bagian 6.5).
- Switch yang sama dipakai di 2 tempat (`Settings` screen dan `Pause` overlay untuk `music`) — makanya ada `refs.switches` array + `syncSwitches()` global, supaya kalau salah satu diubah, kedua tempat (kalau keduanya ter-render) tetap konsisten.

---

## 13. Ringkasan Alur Satu Sesi Bermain (End-to-End)

```
Boot
 └─ loadSave() → state awal
 └─ Build semua 6 screen (sekali saja)
 └─ initPhysics() setelah Matter.js siap (polling window.Matter tiap 60ms jika belum load)
 └─ requestAnimationFrame(tick) mulai berjalan (tapi idle karena screen='menu')

Menu → tekan PLAY
 └─ startGame(): resetBoard(), score=0, currentIndex & nextIndex baru random,
    render preview, screen='game', mulai musik jika toggle aktif

Selama 'game':
 └─ tick() aktif: physics update 2×/frame → postStep (redam gerak + cek overLimit) → syncBoardDom
 └─ Pemain gerak pointer → handleBoardMove → update posisi preview
 └─ Pemain klik/tap → dropFruit() (dengan cooldown) → spawnFruit() body baru + majukan antrian
 └─ Matter.js mendeteksi collision → jika index sama → mergeBodies()
     → hapus 2 body lama, spawn 1 body baru (index+1), tambah skor, SFX, vibrasi, score pop
 └─ Jika sebuah buah diam >1 detik menembus LINE_Y → gameOver()

Pause (opsional, via tombol atau app di-background):
 └─ screen='pause' → tick() skip update fisika (papan beku) → overlay muncul
 └─ Resume → screen='game', musik lanjut jika toggle aktif

Game Over:
 └─ update highScore, hitung & tambah koin, persist, SFX+vibrasi, stop musik
 └─ screen='gameover' → tombol "Main Lagi" (restartGame ≡ startGame) atau "Home"

Shop (kapan saja dari menu):
 └─ Beli/pasang skin kosmetik pakai koin hasil game over
```

---

## 14. Catatan & Potensi Isu (Observasi, bukan permintaan perbaikan)

Bagian ini murni observasi teknis dari membaca kode — bukan bug yang sudah dikonfirmasi merusak gameplay, hanya hal yang mungkin perlu diperhatikan kalau ingin mengembangkan lebih lanjut:

1. **Skin yang di-*equip* tidak memengaruhi tampilan buah in-game** — `syncBoardDom()` (app.js:606) selalu memakai `FRUITS[b.plugin.index]` untuk warna/topper, tidak pernah mengecek `state.equippedSkin`/`SKINS`. Sistem shop saat ini murni kosmetik-di-shop-saja.
2. **Game over per-body, bukan agregat** — dijelaskan di 8.4. Ini valid sebagai desain (mirip game Suika asli), tapi berarti tumpukan buah kecil-kecil yang penuh sesak namun terus "bergoyang" sedikit secara teoritis bisa menghindari game over lebih lama dari yang terlihat intuitif.
3. **`eyes: 'x'`** di `fruit.js` (ekspresi "pusing/kalah") tersedia sebagai opsi fungsi tapi tidak pernah dipanggil dengan opsi tersebut di `app.js` — kemungkinan fitur visual yang direncanakan (misal buah "goyah" sebelum game over) tapi belum disambungkan.
4. **`Ranking`** di menu (app.js:195) hanya memicu `Sfx.click()`, tidak ada layar/fungsi navigasi nyata di belakangnya — tombol placeholder.
5. **`Privacy Policy` & `Rate Us`** di Settings juga hanya memicu SFX klik tanpa aksi nyata — placeholder untuk integrasi store/legal di kemudian hari.
6. **Tidak ada limit atas jumlah body fisika** — teorinya kalau pemain drop sangat banyak tanpa merge (skenario ekstrem), jumlah body terus bertambah dan bisa memberatkan performa; tidak ada pooling/limit eksplisit di kode.
