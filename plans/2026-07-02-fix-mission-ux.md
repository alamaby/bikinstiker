# Plan: Fix mission-related issues (ad loading, countdown, wallet refresh)

## Root Cause Analysis
1. **Ad loading state:** Tombol `Watch Ad` tidak masuk *pending state* saat loading iklan berlangsung, memicu *race condition*.
2. **Countdown statis:** `MissionsScreen` tidak *rebuild* per detik sehingga UI tidak menampilkan sisa waktu terbaru.
3. **Wallet refresh:** Tidak ada sinkronisasi antara `MissionBloc` dan `WalletBloc`. Pull-to-refresh di `HomeScreen` tidak menyertakan pembaruan saldo wallet.

## Plan Implementation
1. **MissionBloc**: Update `_onWatchAd` agar melakukan *emit* pending state sebelum memanggil `_adRepo.loadAndShow()`.
2. **MissionScreen**: Ubah menjadi `StatefulWidget` dengan `Timer.periodic` untuk *refresh* UI per detik.
3. **Wallet Sync**: Tambahkan listener untuk refresh wallet di `MissionsScreen` setelah misi sukses.
4. **Wallet Sync**: Tambahkan refresh wallet di `HomeScreen._onRefresh()`.

## Files to Modify
- `lib/presentation/blocs/mission/mission_bloc.dart`
- `lib/presentation/screens/missions/missions_screen.dart`
- `lib/presentation/screens/home/home_screen.dart`
- `PROJECT_MEMORY.md`

## Verification Commands
```bash
flutter analyze
dart format lib/
```

## Commit Message
```
fix(missions): ad loading state, cooldown ticker, and wallet synchronization
```
