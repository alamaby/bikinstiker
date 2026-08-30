# Profile Screen Fixes Implementation Plan

Created: 2026-07-03 22:02:30

## Objective
Perbaiki layar profile untuk menampilkan informasi akun yang lengkap, perbaiki filter credit history, tambahkan tombol logout, dan pastikan change password sesuai kontrak yang ada.

## Scope
- Menampilkan email user yang sedang login di header profile
- Menampilkan info sign-in provider (email/google/anonymous) dengan jelas
- Perbaiki error Postgres 22P02 saat filter credit history (invalid enum value)
- Implementasi "View All" untuk credit history
- Tambahkan tombol logout dengan konfirmasi
- Pertahankan change password sebagai form modal (bukan one-time link)

## Tasks
- [ ] **Fix Credit History Filter**
  - Ubah `CreditTransactionRepository.fetchTransactions` untuk menggunakan snake_case value (`daily_reward`, `generate_sticker`, `mission_reward`) saat query ke Postgres
  - Perbaiki mapping enum di `CreditTransaction.fromJson` untuk handle semua nilai enum yang ada di DB
  - Pastikan filter chips (Earnings/Spent/Rewards) menggunakan nilai yang valid

- [ ] **Implement View All Credit History**
  - Ubah `CreditTransactionsBloc` untuk support limit yang lebih besar (atau unlimited)
  - Update `CreditTransactionRepository.fetchTransactions` untuk accept limit parameter
  - Implementasi action "View All" di `profile_screen.dart` untuk load semua transaksi

- [ ] **Display User Email in Profile Header**
  - Tambahkan field email di `UserProfile` model (jika perlu) atau ambil langsung dari `AuthBloc.state.user?.email`
  - Update `_buildHeader` di `profile_screen.dart` untuk menampilkan email user

- [ ] **Display Sign-in Provider Info**
  - Pastikan `_providerLabel` menampilkan info yang jelas (Email Account, Google Account, Guest Account)
  - Tambahkan ikon yang sesuai untuk masing-masing provider

- [ ] **Add Logout Button**
  - Tambahkan tombol logout di bagian Settings atau Danger Zone
  - Implementasi dialog konfirmasi sebelum logout
  - Dispatch `AuthSignOutRequested` event ke `AuthBloc`

- [ ] **Verify Change Password Implementation**
  - Pastikan change password hanya tersedia untuk user email (bukan Google/Guest)
  - Verifikasi flow: current password → re-authenticate → update password
  - Pastikan error handling yang baik untuk wrong password

- [ ] **Update PROJECT_MEMORY.md**
  - Catat semua perubahan yang dilakukan
  - Tambahkan command verifikasi yang disarankan
  - Propose commit message

## Technical Decisions
1. Change Password tetap menggunakan form modal (bukan one-time link) - sesuai keputusan user
2. Filter credit history akan menggunakan snake_case value untuk match dengan enum Postgres
3. View All akan load semua transaksi tanpa limit (atau dengan limit yang besar)
4. Logout akan menggunakan existing `AuthSignOutRequested` event dan flow

## Risks
- Perubahan mapping enum bisa mempengaruhi bagian lain yang menggunakan credit transaction
- View All dengan unlimited data bisa menyebabkan performance issue untuk user dengan banyak transaksi
- Perlu testing untuk memastikan filter bekerja dengan benar untuk semua tipe transaksi

## Notes
- Database enum: `transaction_type` mengandung: `topup`, `daily_reward`, `generate_sticker`, `refund`, `subscription_grant`, `mission_reward`, `expired`, `locked`, `admin_grant`
- Dart enum: `CreditTxType` sudah memiliki semua nilai yang sesuai
- Mapping saat ini menggunakan `type.name` yang menghasilkan camelCase, perlu diubah ke snake_case
