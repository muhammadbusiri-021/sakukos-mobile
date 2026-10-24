# SakuKos — Smart & Tactile Expense Tracker for College Students

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Database](https://img.shields.io/badge/Offline--First-Hive%20NoSQL-E53935)](https://pub.dev/packages/hive)
[![Tests](https://img.shields.io/badge/Tests-100%2F100%20Passed-10B981)](#)
[![Code Quality](https://img.shields.io/badge/flutter%20analyze-0%20Issues-10B981)](#)
[![Security](https://img.shields.io/badge/Security-Hybrid%20SHA--256%20%2B%20Biometrics-3B82F6)](#)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%26%20Modular-slate)](#)

> **SakuKos** adalah aplikasi pencatatan keuangan dan manajemen talangan (*split-bill*) yang dirancang khusus untuk mahasiswa dan anak kos. Mengusung filosofi desain modern ala *fintech*, **100% offline-first**, bebas *AI-slop*, tanpa elemen berlebih, dan didukung mesin grafis **Impeller Vulkan (120 FPS)**.

---

## 🎯 Masalah yang Dipecahkan (The Problem)
Bagi anak kos, aplikasi keuangan konvensional sering kali:
1. Terlalu rumit dengan puluhan form input yang melelahkan.
2. Memerlukan koneksi internet dan login akun, padahal anak kos butuh mencatat instan dalam hitungan detik.
3. Sering lupa siapa yang berhutang atau menalangi saat makan bersama (*split-bill*).
4. Khawatir data privasi keuangan bocor ke pihak ketiga.

**SakuKos** memecahkan masalah ini dengan sistem **Catat Cepat berbasis Heuristik Alami**, **Pencatatan Talangan Taktil**, dan **Arsitektur Penyimpanan Lokal Terenkripsi**.

---

## ✨ Fitur Utama (Key Features)

### 1. ⚡ Catat Cepat (Natural Language Parser)
- Cukup ketik layaknya berbicara: *"makan 15k"* atau *"uang saku 500rb"*.
- Heuristic Regex Parser secara otomatis mengekstrak nominal, tipe transaksi (pemasukan/pengeluaran), serta menebak kategori secara cerdas dengan opsi *override* instan.

### 2. 🤝 Tracker Talangan (Split-Bill & Hutang-Piutang)
- Memisahkan catatan uang harian dengan uang talangan teman.
- Tabulasi tegas: **Belum Lunas** vs **Riwayat Lunas**.
- Tidak menggunakan *swipe accidental gestures* (menggunakan tombol hapus eksplisit dengan dialog konfirmasi aman).

### 3. 🛡️ Keamanan Hybrid (PIN 6-Digit SHA-256 + Biometrik)
- **Kunci Induk (Master Key)**: PIN 6 Digit yang di-hash dengan enkripsi **SHA-256** di penyimpanan lokal (tidak pernah disimpan dalam plaintext).
- **Buka Cepat**: Integrasi sensor Sidik Jari (*Android BiometricPrompt*).
- **Anti-Race Condition**: Dirancang dengan *lifecycle guard* dan jeda waktu (*grace period*) 2 detik serta timer guard 600 ms, sehingga bebas dari masalah *double-prompt* atau *infinite loop* saat penutupan dialog sistem.
- **Emergency Bypass**: Mencegah pengguna terkunci jika belum mengatur kombinasi PIN.

### 4. 📊 Laporan & Riwayat Fleksibel
- Filter kategori bergaya horizontal chip ala WhatsApp diawali chip permanen `[ Semua ]`.
- Pencarian transaksi instan berdasarkan judul maupun catatan tambahan.
- Warna teks nominal terstandardisasi: **Rose** (`#F43F5E`) untuk pengeluaran dan **Emerald** (`#10B981`) untuk pemasukan.
- **Ekspor CSV**: Ekspor transaksi dan riwayat talangan ke format spreadsheet dengan standar UTF-8 BOM (`\uFEFF`) terintegrasi langsung ke *Android Share Sheet*.

### 5. 🎨 Desain Presisi Tinggi (High-Contrast Fintech Aesthetics)
- Menggunakan tipografi **Plus Jakarta Sans**.
- Palet warna: **Dark Slate** (`#0F172A`), **Soft Cloud Light** (`#F8FAFC`), **Emerald** (`#10B981`), dan **Rose** (`#F43F5E`).
- *ThemeNotifier* responsif (Toggle Gelap & Terang dalam 1 sentuhan).
- Logo khas Dual-Arc SakuKos yang dilukis presisi menggunakan `CustomPainter`.

---

## 🏛️ Arsitektur & Teknologi (Tech Stack)

- **Framework**: Flutter SDK (Channel Stable)
- **Language**: Dart 3
- **Local Persistence**: Hive NoSQL (Box: `transactions_box`, `debts_box`, `categories_box`, `settings_box`)
- **Security & Crypto**: `crypto` (SHA-256 Hashing), `local_auth` (Biometrics), `FlutterFragmentActivity`
- **Sharing & Export**: `share_plus`, `path_provider`
- **Timing & Lifecycle**: `clock`
- **Rendering Engine**: Impeller with Vulkan Backend
- **Test Coverage**: 100 Automated Tests (Unit & Widget Tests passing 100%)
- **Static Analysis**: 0 Issues (`flutter analyze` clean)

---

## 📁 Struktur Folder Proyek (Project Structure)

```text
lib/
├── core/
│   ├── formatters.dart          # Currency (Rupiah), date, and title-case formatters
│   └── theme.dart               # High-contrast Dark & Light theme (Plus Jakarta Sans)
├── models/
│   ├── debt_item.dart           # Model data talangan / hutang-piutang
│   └── transaction_item.dart    # Model transaksi pemasukan & pengeluaran
├── screens/
│   ├── dashboard_screen.dart    # Tab 1: Hero budget card, cashflow summary, recent list
│   ├── debt_screen.dart         # Tab 2: Tracker talangan (Belum Lunas & Riwayat Lunas)
│   ├── lock_screen_wrapper.dart # Hybrid Lock Screen: Numpad 6-digit PIN + Sidik Jari
│   ├── main_screen.dart         # Bottom navigation scaffold & dynamic FAB controller
│   └── report_screen.dart       # Tab 3: Riwayat transaksi, search, filter chip, ekspor CSV
├── services/
│   ├── biometric_service.dart   # Adapter kompatibilitas lokal autentikasi biometrik
│   ├── budget_service.dart      # Pengelolaan budget harian dan uang saku bulanan
│   ├── category_service.dart    # Manajemen kategori standar & kustom dinamis
│   ├── csv_export_service.dart  # Generator CSV UTF-8 BOM untuk transaksi & talangan
│   ├── debt_service.dart        # Database talangan berbasis Hive
│   ├── security_service.dart    # Manajemen keamanan inti (PIN SHA-256 & Biometrics)
│   ├── smart_text_parser.dart   # Heuristic NLP parser untuk fitur Catat Cepat
│   └── transaction_service.dart # Database transaksi pengeluaran/pemasukan berbasis Hive
├── widgets/
│   ├── add_debt_bottom_sheet.dart        # Modal tambah & edit talangan
│   ├── add_transaction_bottom_sheet.dart # Modal input manual & Catat Cepat
│   ├── budget_settings_bottom_sheet.dart # Pengaturan jatah budget & switch keamanan
│   ├── cashflow_summary_card.dart        # Ringkasan pemasukan & pengeluaran 50/50
│   ├── transaction_detail_bottom_sheet.dart # Detail & opsi hapus transaksi
│   └── weekly_expense_chart.dart         # Grafik bar pengeluaran 7 hari interaktif
└── main.dart                    # Entry point aplikasi & inisialisasi Hive Box
```

---

## 🚀 Cara Menjalankan Proyek (Getting Started)

### Prasyarat:
- Flutter SDK (>= 3.22.x)
- Android SDK dengan dukungan Java 17
- Editor: VS Code atau Android Studio dengan ekstensi Flutter & Dart
- Perangkat Android (Fisik atau Emulator dengan sensor biometrik aktif)

### Langkah Instalasi:

1. **Clone repositori**:
   ```bash
   git clone https://github.com/username/sakukos.git
   cd sakukos
   ```

2. **Pasang seluruh dependensi**:
   ```bash
   flutter pub get
   ```

3. **Verifikasi kualitas kode**:
   ```bash
   flutter analyze
   ```
   *Output yang diharapkan: `No issues found!`*

4. **Jalankan pengujian otomatis**:
   ```bash
   flutter test
   ```
   *Output yang diharapkan: `100/100 All tests passed!`*

5. **Jalankan aplikasi di perangkat**:
   ```bash
   flutter run
   ```

---

## 📦 Build & Unduh Release APK (Release Deployment)

### 1. Build File APK Mandiri
Untuk menghasilkan file installer APK Release yang teroptimasi:
```bash
flutter build apk --release
```

Hasil kompilasi APK akan berada di lokasi:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### 2. Penamaan File Rilis
Anda dapat mengganti nama file tersebut menjadi format rilis resmi:
```text
SakuKos-v1.0.0.apk
```

### 3. Petunjuk Instalasi di HP Android:
1. Salin file `SakuKos-v1.0.0.apk` ke penyimpanan HP Android Anda.
2. Buka aplikasi File Manager, lalu ketuk file `SakuKos-v1.0.0.apk`.
3. Izinkan opsi *"Install from Unknown Sources"* (jika diminta oleh sistem).
4. Tekan **Install** dan buka **SakuKos**.
5. Buka menu pengaturan budget untuk mengaktifkan **Kunci PIN 6 Digit** dan **Kunci Sidik Jari** untuk perlindungan maksimal.

---

## 🧪 Hasil Pengujian Kualitas (Testing & Verification)

Semua fungsionalitas inti telah melalui pengujian otomatis komprehensif:

| Modul Pengujian | Deskripsi Skenario | Status |
| :--- | :--- | :---: |
| `security_service_test.dart` | SHA-256 Hashing, PIN Verification, Biometrics & Emergency Bypass | **PASSED** (9/9) |
| `biometric_service_test.dart` | Compatibility adapter & local_auth exception handling | **PASSED** (7/7) |
| `category_service_test.dart` | Dynamic category CRUD, reserved keywords, auto-cleaning | **PASSED** (7/7) |
| `csv_export_service_test.dart` | UTF-8 BOM encoding & CSV delimiter formatting | **PASSED** (5/5) |
| `debt_service_test.dart` | Debt model serialization & Hive state management | **PASSED** (5/5) |
| `smart_text_parser_test.dart` | Indonesian natural language regex & nominal parser | **PASSED** (34/34) |
| `theme_test.dart` | Dark & Light Theme palette, typography, and contrast | **PASSED** (6/6) |
| `widget_test.dart` | Complete UI flows, Numpad interactions, charts, and lifecycle | **PASSED** (23/23) |
| **Total** | **Seluruh Rangkaian Pengujian SakuKos** | **100/100 PASSED** |

---

## 📄 Lisensi (License)
Proyek ini didistribusikan di bawah lisensi MIT. Silakan gunakan dan kembangkan secara bebas untuk kemaslahatan komunitas mahasiswa dan anak kos di seluruh Indonesia.
