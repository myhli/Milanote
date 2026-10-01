# PRD: LocalBoard (Aplikasi Moodboard & Kanvas Lokal Mirip Milanote)

## 1. Introduction / Overview

**LocalBoard** adalah aplikasi kanvas visual tak terbatas (*infinite canvas*) berbasis *local-first* dan *offline-first* yang dirancang khusus untuk mahasiswa dan praktisi seni, desainer, serta pemikir visual (*visual thinkers*). 

Aplikasi ini menghadirkan pengalaman modular layaknya **Milanote** (kartu catatan, gambar moodboard, palet warna, link referensi web, garis penghubung, dan sub-board bersarang), namun dengan **100% data tersimpan di perangkat lokal pengguna**, tanpa langganan berbayar, tanpa batas kuota kartu (*unlimited cards*), dan dapat dijalankan tanpa ketergantungan koneksi internet maupun server *cloud*.

### Masalah yang Diselesaikan:
1. **Biaya & Batasan:** Layanan seperti Milanote membatasi jumlah kartu pada akun gratis (maks. 100 elemen) dan memerlukan biaya langganan bulanan yang mahal bagi mahasiswa seni.
2. **Privasi & Keamanan Data:** Karya seni, konsep orisinal, dan riset visual pengguna sering kali bersifat rahasia dan tidak ingin diunggah ke server pihak ketiga.
3. **Ketergantungan Internet:** Akses di studio, ruang pameran, atau tempat tanpa koneksi internet yang stabil sering menjadi kendala.
4. **Kemudahan untuk Orang Awam:** Mahasiswa seni membutuhkan aplikasi yang langsung dapat diunduh dan digunakan tanpa perlu instalasi runtime teknis (tanpa Docker, Node.js, atau setup database manual).

---

## 2. Goals

- **100% Local-First & Offline:** Seluruh proyek, gambar, dan data disimpan secara lokal di perangkat tanpa memerlukan koneksi internet atau login akun.
- **Kemudahan Penggunaan (*Zero-Friction*):** Ditujukan untuk pengguna awam; aplikasi berjalan instan (*ready-to-run*) di Windows, macOS, Android, iOS, dan Web (PWA offline).
- **Performa Kanvas Tinggi (60/120 FPS):** Navigasi *pan* dan *zoom* tetap mulus meskipun memuat ratusan gambar moodboard beresolusi tinggi.
- **Portabilitas & Berbagi Mudah:** Mendukung ekspor dan impor file berkas mandiri `.board` untuk dicadangkan atau dipindahkan antar perangkat (misal: dari Laptop ke Tablet/HP).
- **Hasil Presentasi Profesional:** Mendukung ekspor seluruh papan kanvas menjadi Gambar Resolusi Tinggi (PNG/JPG) dan dokumen PDF siap cetak atau presentasi.

---

## 3. Target User Persona

- **Nama Persona:** Rian (Mahasiswa Desain Komunikasi Visual & Seni Rupa)
- **Karakteristik:** Sangat visual, sering mengumpulkan ratusan referensi gambar dari web/Pinterest, membuat *character design sheet*, studi warna (*color swatches*), dan *storyboard*.
- **Kebutuhan:** Membutuhkan wadah menyusun ide secara spasial (bukan sekadar folder file biasa), bebas menaruh gambar di mana saja, menghubungkan ide dengan panah, dan mengekspor hasilnya untuk asistensi dosen atau presentasi studio.
- **Tingkat Teknis:** Orang awam; tidak ingin repot dengan konfigurasi server, terminal, atau perintah teknis.

---

## 4. User Stories

### US-001: Dashboard Galeri Papan & Manajemen Proyek
**Description:** Sebagai mahasiswa seni, saya ingin melihat galeri semua papan proyek saya saat membuka aplikasi sehingga saya bisa langsung melanjutkan proyek sebelumnya dengan 1 kali klik.

**Acceptance Criteria:**
- [ ] Menampilkan grid thumbnail visual dari seluruh papan lokal yang pernah dibuat.
- [ ] Thumbnail menampilkan pratinjau mini isi kanvas terakhir, judul papan, dan tanggal modifikasi.
- [ ] Tombol opsi pada setiap kartu papan: Buka, Ganti Nama (*Rename*), Duplikasi (*Duplicate*), Ekspor `.board`, dan Hapus (*Delete* dengan konfirmasi dialog).
- [ ] Kolom pencarian cepat (*search bar*) untuk menyaring nama papan.
- [ ] Typecheck/lint lolos tanpa error.
- [ ] Visual lolos uji responsif di desktop maupun tablet/mobile.

---

### US-002: Pembuatan Papan Baru & Pilihan Template
**Description:** Sebagai pengguna, saya ingin bisa membuat papan baru secara instan atau memilih template desain seni agar saya bisa langsung mulai bekerja tanpa penundaan.

**Acceptance Criteria:**
- [ ] Terdapat tombol mencolok `+ Buat Papan Baru` di Dashboard.
- [ ] Klik utama langsung membuka kanvas kosong bersih (*zero-distraction*).
- [ ] Terdapat menu sekunder `Gunakan Template` yang menyediakan template siap pakai khusus seni:
  - *Moodboard Karakter* (slot foto referensi anatomi, kostum, palet warna, catatan profil).
  - *Studi Gaya & Warna* (grid gambar estetika, palet swatch HEX, catatan tipografi).
  - *Storyboard 6-Panel* (wadah gambar berurutan dengan kotak dialog deskripsi adegan).
  - *Brainstorming Proyek* (pusat ide dengan konektor panah ke cabang ide).
- [ ] Papan baru langsung otomatis disimpan di database lokal.
- [ ] Typecheck/lint lolos.

---

### US-003: Navigasi Infinite Canvas (Pan, Zoom, Dot Grid)
**Description:** Sebagai pengguna, saya ingin menjelajahi kanvas tak terbatas dengan gerakan halus agar saya bisa menata ide seluas yang saya inginkan.

**Acceptance Criteria:**
- [ ] Kanvas mendukung *pan* (geser) tanpa batas ke segala arah (sumbu X dan Y).
- [ ] Kanvas mendukung *zoom in* dan *zoom out* (rentang 10% hingga 400%) dengan pusat perbesaran berada di posisi kursor/titik sentuh.
- [ ] Navigasi didukung melalui:
  - Mouse: Scroll wheel untuk zoom, klik tengah atau spasi + drag untuk pan.
  - Trackpad / Touch: *Pinch-to-zoom* dan gestur 2 jari untuk pan.
- [ ] Latar belakang kanvas memiliki motif titik (*dot grid*) halus yang skalanya menyesuaikan tingkat zoom.
- [ ] Tombol pintas navigasi di sudut layar: Reset Zoom (100%), Fit to View (zoom agar seluruh kartu terlihat), dan indikator persentase zoom.
- [ ] Performa rendering stabil pada minimal 60 FPS saat menggeser kanvas dengan >50 elemen.

---

### US-004: Kartu Catatan Teks & Daftar Tugas (Checklist)
**Description:** Sebagai mahasiswa seni, saya ingin menambahkan catatan teks dan to-do list di kanvas agar saya dapat mencatat konsep desain, jadwal asistensi, atau deskripsi karya.

**Acceptance Criteria:**
- [ ] Kartu teks dapat ditarik (*drag*) dari sidebar alat ke posisi kanvas mana pun.
- [ ] Mendukung pemformatan teks: Judul (*Heading*), Bold, Italic, Bullet List, dan Checklist kotak centang (*Todo item*).
- [ ] Kartu dapat diubah ukurannya (*resize width/height*) secara bebas dengan handle di sudut kartu.
- [ ] Pilihan warna latar belakang kartu catatan (putih, kuning pastel, hijau pastel, biru pastel, peach, abu-abu).
- [ ] Seluruh perubahan teks tersimpan secara otomatis (*auto-save*) saat pengguna mengetik.

---

### US-005: Kartu Gambar & Foto (Drag-and-Drop / Clipboard Paste)
**Description:** Sebagai mahasiswa seni, saya ingin memasukkan gambar secara mudah (seret file atau Ctrl+V) ke kanvas agar proses membuat moodboard sangat cepat.

**Acceptance Criteria:**
- [ ] Pengguna dapat menyeret (*drag-and-drop*) file gambar (.jpg, .png, .webp) langsung dari File Explorer / Finder ke atas kanvas.
- [ ] Pengguna dapat menempelkan gambar langsung dari clipboard (Ctrl+V / Cmd+V) setelah menyalin gambar dari browser.
- [ ] File gambar otomatis disalin dan dikompresi secara aman ke dalam folder penyimpanan lokal aplikasi (tidak bergantung pada path file asli).
- [ ] Gambar dapat diatur ukurannya (*proportional resize* dengan mempertahankan aspek rasio).
- [ ] Opsi kartu gambar: Tambahkan teks keterangan (*caption*), buka pratinjau layar penuh (*lightbox*), dan tombol hapus.

---

### US-006: Kartu Tautan Web (Web Bookmark) dengan Cache Offline
**Description:** Sebagai periset visual, saya ingin menaruh tautan website referensi (Pinterest, ArtStation, YouTube, artikel) yang menampilkan gambar pratinjau dan tetap dapat dilihat saat offline.

**Acceptance Criteria:**
- [ ] Pengguna dapat menempelkan URL web ke kartu Link.
- [ ] Sistem otomatis mengambil metadata Open Graph (Judul halaman, deskripsi singkat, dan cover thumbnail image).
- [ ] Gambar cover thumbnail diunduh dan disimpan di memori lokal sehingga tetap muncul meskipun aplikasi sedang offline.
- [ ] Jika offline saat URL dimasukkan, sistem menyimpan URL mentah dan menyediakan tombol `Muat Ulang Pratinjau` saat terhubung kembali.
- [ ] Klik ganda pada kartu link membuka URL di browser bawaan sistem.

---

### US-007: Kartu Palet Warna (Color Swatch)
**Description:** Sebagai desainer seni, saya ingin menaruh sampel warna dengan kode HEX/RGB di kanvas untuk menjaga konsistensi skema warna karya saya.

**Acceptance Criteria:**
- [ ] Pengguna dapat menarik kartu Palet Warna dari sidebar.
- [ ] Menampilkan kotak warna visual yang dilengkapi kode HEX (contoh: `#2C3E50`) dan RGB.
- [ ] Dilengkapi *color picker* visual (roda warna, slider HSV/RGB, dan input manual kode HEX).
- [ ] Fitur 1-klik untuk menyalin kode HEX ke clipboard dengan pesan konfirmasi toast.
- [ ] Satu kartu dapat menampung deretan 1 hingga 8 warna sekaligus (*color palette row*).

---

### US-008: Garis Penghubung & Panah Antar Kartu (Connector Arrows)
**Description:** Sebagai perencana alur visual, saya ingin menarik garis atau panah antara dua kartu untuk menunjukkan relasi atau urutan ide.

**Acceptance Criteria:**
- [ ] Pengguna dapat menarik garis konektor dari titik jangkar (*anchor point*) pada satu kartu ke kartu lainnya.
- [ ] Garis secara dinamis mengikuti pergerakan kartu ketika salah satu kartu digeser di kanvas.
- [ ] Pilihan gaya garis: Lurus (*straight*), Lengkung halus (*curved/bezier*), atau Siku (*orthogonal*).
- [ ] Opsi ujung garis: Tanpa panah, Panah satu arah, atau Panah dua arah.
- [ ] Pilihan ketebalan garis dan warna garis.

---

### US-009: Papan Bersarang (Sub-Boards / Papan di Dalam Papan)
**Description:** Sebagai pengelola proyek besar, saya ingin membuat sub-board di dalam kanvas utama agar struktur proyek saya tetap rapi dan tidak bercampur aduk.

**Acceptance Criteria:**
- [ ] Pengguna dapat menarik elemen `Sub-Board` dari sidebar ke atas kanvas.
- [ ] Kartu sub-board menampilkan ikon folder/papan, judul sub-board, dan jumlah kartu di dalamnya.
- [ ] Klik ganda pada kartu sub-board membawa pengguna masuk ke dalam kanvas sub-board tersebut.
- [ ] Terdapat navigasi remah roti (*breadcrumb navigation*) di pojok kiri atas (contoh: `Proyek Akhir > Desain Karakter > Senjata`) untuk kembali ke papan induk dengan 1 klik.
- [ ] Sub-board memiliki kanvas tak terbatas mandiri dengan seluruh fitur kartu yang sama.

---

### US-010: Sistem Penyimpanan Otomatis (Local Auto-Save)
**Description:** Sebagai pengguna awam, saya tidak ingin khawatir kehilangan karya seni saya akibat lupa menekan tombol simpan atau aplikasi tertutup tiba-tiba.

**Acceptance Criteria:**
- [ ] Setiap aksi (menambah kartu, menggeser posisi, mengubah teks, meresize) otomatis tersimpan ke database lokal secara *debounced* (< 500ms setelah interaksi selesai).
- [ ] Tidak ada tombol "Save" manual yang membingungkan; status penyimpanan ditampilkan berupa indikator halus: "Semua perubahan tersimpan di lokal".
- [ ] Jika aplikasi tertutup mendadak, saat dibuka kembali kanvas berada pada kondisi terakhir persis sebelum tertutup.

---

### US-011: Ekspor & Impor File Proyek (.board Bundle)
**Description:** Sebagai mahasiswa seni, saya ingin memindahkan proyek saya dari laptop ke tablet iPad/Android atau membagikannya ke teman tanpa internet, cukup dengan 1 file arsip.

**Acceptance Criteria:**
- [ ] Opsi `Ekspor Proyek (.board)` membungkus seluruh data JSON papan beserta seluruh file gambar asli ke dalam satu file arsip terkompresi `.board`.
- [ ] Opsi `Impor Proyek (.board)` memungkinkan pengguna memilih file `.board` dari penyimpanan perangkat dan menambahkannya ke Galeri Papan.
- [ ] File `.board` bersifat mandiri (*standalone*), dapat dikirim via AirDrop, Bluetooth, Flashdisk, WhatsApp, atau Google Drive.
- [ ] Proses impor memvalidasi keutuhan file dan menampilkan pesan sukses atau pesan kesalahan yang ramah pengguna jika file rusak.

---

### US-012: Ekspor Dokumen ke Gambar Hi-Res & PDF
**Description:** Sebagai mahasiswa yang harus mengumpulkan tugas asistensi, saya ingin mengekspor moodboard saya ke file gambar resolusi tinggi atau PDF siap cetak.

**Acceptance Criteria:**
- [ ] Menu `Ekspor Hasil Karya` menyediakan 2 pilihan format utama:
  1. **Gambar (PNG / JPG):** Otomatis menghitung batas terluar (*bounding box*) dari semua kartu dan merender seluruh karya ke satu gambar beresolusi tinggi (opsi 1x, 2x, 3x scale).
  2. **Dokumen PDF:** Opsi ekspor Poster 1 halaman utuh (vektor/hi-res) atau PDF multi-halaman berorientasi lanskap/potret.
- [ ] Pengguna dapat melihat pratinjau sebelum berkas disimpan.
- [ ] Dialog penyimpanan file standar OS muncul untuk memilih lokasi penyimpanan berkas hasil ekspor.

---

## 5. Functional Requirements

| Kode | Kebutuhan Fungsional |
| :--- | :--- |
| **FR-1** | Sistem wajib menampilkan Dashboard Galeri yang memuat seluruh papan proyek pengguna saat aplikasi dijalankan. |
| **FR-2** | Sistem wajib menyediakan tombol pembuatan papan baru instan dan opsi pemilihan template seni. |
| **FR-3** | Kanvas wajib bersifat tak terbatas (*infinite*) dengan dukungan *pan* dan *zoom* (10% - 400%) yang mulus. |
| **FR-4** | Sistem wajib menyediakan *Dock/Toolbar* mengambang yang berisi alat penambahan: Catatan Teks, Gambar, Tautan Web, Palet Warna, Garis Panah, dan Sub-Board. |
| **FR-5** | Seluruh elemen kartu di kanvas wajib dapat dipindahkan posisinya (*free dragging*) dan diubah ukurannya (*resizing*). |
| **FR-6** | Kartu catatan wajib mendukung pemformatan teks (*Heading, Bold, Italic, Bullet, Checklist*). |
| **FR-7** | Sistem wajib menerima penyisipan gambar melalui *drag-and-drop* dari sistem operasi dan *paste* langsung dari *clipboard*. |
| **FR-8** | Seluruh aset gambar lokal wajib dikelola di direktori data aplikasi lokal secara aman tanpa bergantung pada lokasi berkas awal. |
| **FR-9** | Sistem wajib mengekstrak metadata tautan web (*title, description, cover image*) saat online dan menyimpan *cache* gambar cover untuk penggunaan offline. |
| **FR-10** | Kartu palet warna wajib menyediakan *color picker* visual, input kode HEX/RGB, dan tombol salin ke *clipboard*. |
| **FR-11** | Garis konektor wajib dapat menghubungkan antar kartu dan posisinya otomatis mengikuti pergerakan kartu. |
| **FR-12** | Sistem wajib mendukung struktur papan bersarang (*Sub-Board*) dengan navigasi remah roti (*breadcrumb*). |
| **FR-13** | Sistem wajib melakukan penyimpanan otomatis (*auto-save*) lokal setiap kali terjadi perubahan data. |
| **FR-14** | Sistem wajib menyediakan fitur ekspor proyek ke dalam format berkas arsip mandiri `.board` (berisi JSON & gambar). |
| **FR-15** | Sistem wajib menyediakan fitur impor berkas `.board` untuk memulihkan atau memindahkan proyek. |
| **FR-16** | Sistem wajib menyediakan fitur ekspor kanvas ke format gambar resolusi tinggi (PNG/JPG) dengan batas otomatis seluruh elemen. |
| **FR-17** | Sistem wajib menyediakan fitur ekspor kanvas ke dokumen PDF (format poster 1 lembar atau multi-halaman). |
| **FR-18** | Sistem wajib menyediakan fitur *Undo* (Ctrl+Z) dan *Redo* (Ctrl+Y / Ctrl+Shift+Z) untuk riwayat interaksi kartu di kanvas. |
| **FR-19** | Sistem wajib mendukung tema Gelap (*Dark Mode*) dan tema Terang (*Light Mode*) yang ramah mata bagi perupa seni. |
| **FR-20** | Aplikasi tidak boleh memerlukan pembuatan akun, kata sandi, ataupun pengiriman data telemetri/proyek ke server luar. |

---

## 6. Non-Goals (Batasan Ruang Lingkup v1 / MVP)

Berikut adalah hal-hal yang **TIDAK** termasuk dalam lingkup pengembangan versi awal (v1):
- **Bukan Cloud Multi-user Real-time:** Tidak ada fitur kursor bersamaan layaknya Google Docs / Figma Live Collaboration melalui internet (fokus utama adalah privasi 100% lokal).
- **Bukan Aplikasi Gambar Raster/Kuas (Photoshop/Procreate Drawing Engine):** Tidak menyediakan kuas lukis rumit dengan sensitivitas tekanan tinggi untuk melukis digital dari nol; fokus aplikasi adalah *moodboarding*, kurasi visual, dan perancangan ide.
- **Bukan Akun Pengguna / Cloud Sync Server:** Tidak ada backend server terpusat yang memerlukan login email/password.
- **Bukan Sistem Komentar Tim Berbayar:** Tidak ada sistem tag komentar bergaya enterprise.

---

## 7. Design Considerations (UI/UX)

- **Estetika Studio Kreatif:** Tampilan bergaya minimalis modern dengan warna netral (abu-abu gelap arang untuk Dark Mode, off-white untuk Light Mode) agar tidak mengalihkan perhatian dari warna karya seni pengguna.
- **Sidebar Alat Mengambang (*Floating Tool Dock*):** Terinspirasi dari Milanote, diletakkan di sisi kiri atau bawah kanvas dengan ikon yang jelas (Catatan, Gambar, Link, Warna, Panah, Papan).
- **Interaksi Alami untuk Orang Awam:**
  - Klik ganda di area kosong kanvas langsung memunculkan kartu catatan cepat.
  - Seret gambar langsung lepas di kanvas (*drop anywhere*).
  - Sentuhan jari intuitif di layar sentuh tablet (iPad / Android Tablet).
- **Indikator Visual Non-Intrusif:** Status auto-save hanya berupa titik hijau atau teks kecil di pojok tanpa pop-up yang mengganggu alur konsentrasi berkarya.

---

## 8. Technical Architecture & Considerations (Flutter)

### 8.1. Arsitektur Multi-Platform Flutter
- **Bahasa & Framework:** Dart & Flutter 3.x.
- **Dukungan Platform:**
  - Desktop: Windows (`.exe` mandiri / installer MSIX) & macOS (`.dmg` / `.app`).
  - Mobile: Android (`.apk` / Play Store ready) & iOS (`.ipa`).
  - Web: Flutter Web PWA (dapat di-cache untuk penggunaan offline di browser).
- **Performa Mesin Grafis:** Memanfaatkan akselerasi perangkat keras bawaan Flutter (Impeller di iOS/macOS/Android, Skia di Windows/Web) untuk menjamin 60–120 FPS pada kanvas tak terbatas.

### 8.2. Struktur Penyimpanan Lokal & Format Berkas
- **Database Lokal:** SQLite (via `sqflite` / `drift`) atau Key-Value berkecepatan tinggi (`hive` / `isar`) untuk menyimpan data papan, posisi kartu, koordinat, dan relasi.
- **Manajemen Berkas Media:** Gambar disimpan di direktori dokumen lokal aplikasi (`path_provider`).
- **Format Pertukaran Data (`.board`):**
  - Menggunakan format arsip ZIP standar dengan ekstensi khusus `.board`.
  - Struktur di dalam `.board`:
    ```
    my_artwork.board (ZIP)
    ├── manifest.json       # Metadata versi, nama papan, tanggal dibuat
    ├── canvas_data.json    # Daftar kartu, posisi X/Y, ukuran, warna, teks, panah
    └── assets/             # Folder seluruh gambar asli yang digunakan di kanvas
        ├── img_01.png
        └── img_02.jpg
    ```

### 8.3. Pustaka & Paket Rekomendasi
- **Kanvas Interaktif:** `interactive_viewer_2` atau implementasi kustom `CustomPainter` + `GestureDetector` untuk presisi koordinat tanpa batas.
- **Pengambilan Gambar & File:** `file_picker`, `desktop_drop`, `pasteboard` (dukungan copy-paste gambar dari clipboard OS).
- **Metadata Web:** `http` dan parser Open Graph HTML (untuk desktop/mobile).
- **Pewarnaan:** `flex_color_picker` untuk UI pemilih warna seniman.
- **Ekspor Dokumen:** `pdf` & `printing` untuk konversi papan ke PDF; `render_repaint_boundary` / `image` untuk ekspor gambar resolusi tinggi.
- **Manajemen Status (*State Management*):** `flutter_riverpod` untuk performa reaktif yang bersih dan mudah diuji.

---

## 9. Success Metrics

1. **Kecepatan Memulai Karya:** Pengguna dapat membuat papan baru dan menaruh gambar pertama dalam waktu < 5 detik sejak aplikasi pertama kali dibuka.
2. **Kestabilan Performa Kanvas:** Kanvas tetap merespons *pan/zoom* tanpa *stuttering* (tetap di atas 50 FPS) saat menampung minimal 100 kartu dan gambar di desktop maupun tablet.
3. **Keandalan Data (Zero Data Loss):** 100% data tersimpan otomatis; tidak ada laporan kehilangan kartu saat aplikasi ditutup secara paksa.
4. **Kemudahan Berbagi Antar Perangkat:** File `.board` berhasil diekspor dari satu platform (misal Windows) dan dibuka di platform lain (misal Android atau Mac) dengan tata letak 100% identik.
5. **Kepuasan Pengguna Awam:** Mahasiswa seni dapat mengoperasikan aplikasi tanpa perlu membaca buku panduan teknis.

---

## 10. Open Questions & Future Roadmap (v2)

### Open Questions:
1. *Batas Ukuran File Proyek:* Apakah perlu ada fitur kompresi otomatis gambar (opsi kualitas gambar asli vs kualitas terkompresi) agar ukuran file `.board` tidak membengkak saat memuat puluhan foto resolusi 4K?
2. *Dukungan Web PWA:* Karena Flutter Web di browser memiliki batas kuota IndexedDB (biasanya beberapa ratus MB tergantung browser), apakah pengguna web harus diarahkan untuk lebih sering mengekspor `.board` ke disk lokal?

### Rencana Fitur Masa Depan (v2):
- Fitur sinkronisasi langsung antar perangkat via Wi-Fi lokal (*Local P2P Sync*) tanpa kabel.
- Dukungan tagar (*tags*) dan pencarian teks global di seluruh papan.
- Integrasi meja gambar stylus dengan pengenalan coretan catatan (*handwritten notes to text*).
