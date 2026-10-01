# 🎨 LocalBoard — Infinite Canvas for Art Students & Visual Creators

> **Aplikasi kanvas visual tak terbatas (Milanote alternatif) berbasis *Local-First* dan *Offline-First* yang dirancang khusus untuk mahasiswa seni, desainer, dan praktisi visual.**

100% data, berkas gambar, dan metadata tersimpan secara lokal di perangkat tanpa telemetri atau dependensi cloud server.

---

## 🌟 Fitur Inti (MVP Selesai)

1. **Infinite Canvas Navigation (US-003):**
   - Panning tanpa batas dan zoom halus (10% s/d 400%) berpusat pada kursor.
   - Motif titik (*dot-grid*) dinamis yang beradaptasi dengan skala perbesaran.
   - Kontrol overlay: Indikator zoom %, Reset Zoom (100%), dan Fit-to-View.

2. **Sistem Kartu Visual Inti (US-004, US-005, US-007):**
   - **Kartu Catatan (NoteCard):** Pemformatan teks, to-do list checklist, dan warna pastel studio.
   - **Kartu Gambar (ImageCard):** Drag-and-drop dari OS (`desktop_drop`) dan paste langsung dari clipboard (Ctrl+V via `pasteboard`).
   - **Kartu Palet Warna (ColorCard):** 1–8 swatch warna, visual color picker, dan salin kode HEX 1-klik ke clipboard.
   - **Floating Toolbar Dock:** Alat melayang untuk menarik kartu baru ke kanvas.

3. **Garis Penghubung & Panah Dinamis (US-008):**
   - Garis lurus (*straight*), lengkung halus (*curved bezier*), dan siku (*orthogonal*).
   - Titik jangkar interaktif di 4 sisi kartu yang otomatis tersinkronisasi saat kartu digeser.

4. **State Machine, Undo/Redo & Autosave Sync (US-010, FR-18):**
   - **Undo / Redo Command Pattern:** Riwayat hingga 50 aksi atomik dengan shortcut keyboard (Ctrl+Z / Ctrl+Y).
   - **Autosave Engine (Debounce 400ms):** Jaminan *zero data loss* dengan flush seketika saat aplikasi diminimalkan atau ditutup.

5. **Dashboard Galeri & Template Seni (US-001, US-002):**
   - Grid galeri seluruh proyek lokal dengan pencarian instan berdasarkan judul.
   - Manajemen papan: Buka, Ganti Nama (*Rename*), Duplikasi (*Duplicate*), dan Hapus (*Delete*).
   - **4 Starter Template Seni:**
     - *Moodboard Karakter*
     - *Studi Gaya & Warna*
     - *Storyboard 6-Panel*
     - *Brainstorming Proyek*

6. **Ekspor Gambar Resolusi Tinggi (US-012 Part 1):**
   - Perhitungan batas terluar (*bounding box*) otomatis seluruh elemen.
   - Pratinjau kanvas interaktif sebelum diekspor.
   - Pilihan resolusi skala **1x (Standar)**, **2x (Retina)**, dan **3x (Ultra HD)** disimpan ke format PNG.

7. **Desain & Estetika Studio (FR-19):**
   - Tema Studio Dark (*Charcoal / Deep Slate*) dan Studio Light (*Soft Off-White*).

---

## 🛠️ Tech Stack & Arsitektur

- **Framework:** Flutter 3.x (Desktop macOS/Windows/Linux, Web, Mobile)
- **State Management:** `flutter_riverpod` (v3.x `Notifier`)
- **Penyimpanan Lokal:** `hive_flutter`, `path_provider` (sandboxed image assets)
- **Desain & Interaksi:** `InteractiveViewer`, `CustomPainter`, `desktop_drop`, `pasteboard`, `file_picker`
- **Ekspor Gambar:** `ui.PictureRecorder` offscreen rasterizer

---

## 🧪 Pengujian Otomatis

Proyek ini dilengkapi dengan 67 unit & widget tests dengan cakupan menyeluruh:
```bash
# Analisis statis (0 warnings / lint errors)
flutter analyze

# Menjalankan seluruh test suite
flutter test
```
