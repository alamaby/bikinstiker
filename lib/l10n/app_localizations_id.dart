// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'BikinStiker';

  @override
  String get languageTitle => 'Pilih bahasa Anda';

  @override
  String get continueLabel => 'Lanjutkan';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get delete => 'Hapus';

  @override
  String get remove => 'Hapus';

  @override
  String get retry => 'Coba lagi';

  @override
  String get share => 'Bagikan';

  @override
  String get dismiss => 'Tutup';

  @override
  String get all => 'Semua';

  @override
  String get error => 'Error';

  @override
  String get errorOccurred => 'Terjadi kesalahan';

  @override
  String get unknown => 'Tidak diketahui';

  @override
  String get back => 'Kembali';

  @override
  String get next => 'Lanjut';

  @override
  String get skip => 'Lewati';

  @override
  String get done => 'Selesai';

  @override
  String get preparingGuestSession => 'Menyiapkan sesi tamu Anda...';

  @override
  String get createAccount => 'Buat akun';

  @override
  String get missions => 'Misi';

  @override
  String get myPacks => 'Pack Saya';

  @override
  String get history => 'Riwayat';

  @override
  String get profile => 'Profil';

  @override
  String get myStickerPacks => 'Pack Stiker Saya';

  @override
  String get typePromptFirst => 'Ketik deskripsi singkat dulu';

  @override
  String promptTooLong(Object count) {
    return 'Deskripsi maksimal $count karakter';
  }

  @override
  String get chooseValidStyle => 'Pilih gaya yang valid';

  @override
  String get typeYourText => 'Ketik teks Anda';

  @override
  String get describeYourSticker => 'Deskripsikan stiker Anda';

  @override
  String get failedToLoadStyles => 'Gagal memuat gaya';

  @override
  String get inputHintTextOnly => 'contoh: HELLO, YUM, WOW';

  @override
  String get inputHintSubject =>
      'contoh: kucing oren memakai blangkon sambil minum kopi';

  @override
  String get useLast => 'Pakai terakhir';

  @override
  String get captionOptional => 'Caption (opsional)';

  @override
  String get captionExample => 'contoh: READY';

  @override
  String get position => 'Posisi';

  @override
  String get top => 'Atas';

  @override
  String get bottom => 'Bawah';

  @override
  String get guestCredits => 'Kredit Tamu';

  @override
  String get creditsPlus => 'Kredit (Plus)';

  @override
  String get credits => 'Kredit';

  @override
  String get createAccountForCredits => 'Buat akun untuk 5 kredit';

  @override
  String get lowBalance => 'Saldo rendah';

  @override
  String get low => 'Rendah';

  @override
  String get chooseStyle => 'Pilih gaya';

  @override
  String get chooseStyleTitle => 'Pilih gaya';

  @override
  String get notEnoughCredits => 'Kredit tidak cukup';

  @override
  String get generating => 'Membuat…';

  @override
  String generateSticker(Object count) {
    return 'Buat Stiker ($count kredit)';
  }

  @override
  String failedToShare(Object error) {
    return 'Gagal membagikan stiker: $error';
  }

  @override
  String exportFailed(Object message) {
    return 'Ekspor gagal: $message';
  }

  @override
  String get conjuringSticker => 'Meramu stiker Anda…';

  @override
  String get nextAddToPack => 'Berikutnya: tambahkan stiker ini ke pack';

  @override
  String get addToPack => 'Tambahkan ke Pack';

  @override
  String get notEnoughCreditsToGenerate =>
      'Kredit tidak cukup untuk membuat stiker.';

  @override
  String get generationFailed => 'Pembuatan stiker gagal';

  @override
  String get createAccountSaveShare =>
      'Buat akun untuk menyimpan atau membagikan stiker ini.';

  @override
  String get createAccountKeepSticker => 'Buat akun dan simpan stiker';

  @override
  String get signInExistingAccount => 'Masuk ke akun yang sudah ada';

  @override
  String get guestDiscardWarning =>
      'Jika Anda masuk ke akun yang sudah ada, stiker tamu ini akan dibuang.';

  @override
  String get tooManyRequests =>
      'Terlalu banyak permintaan. Coba lagi dalam beberapa menit.';

  @override
  String tooManyRequestsWait(Object seconds) {
    return 'Terlalu banyak permintaan. Tunggu $seconds detik.';
  }

  @override
  String generationRunning(Object seconds) {
    return 'Pembuatan sedang berjalan. Tunggu $seconds detik.';
  }

  @override
  String get generationInProgress => 'Pembuatan stiker sudah berjalan.';

  @override
  String get noStylesAvailable => 'Tidak ada gaya tersedia saat ini';

  @override
  String get pullToRefresh => 'Tarik ke bawah untuk memuat ulang';

  @override
  String get tagline => 'Pembuat stiker WhatsApp bertenaga AI';

  @override
  String get signIn => 'Masuk';

  @override
  String get signUp => 'Daftar';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Masukkan email yang valid';

  @override
  String get password => 'Kata sandi';

  @override
  String get passwordMin => 'Minimal 6 karakter';

  @override
  String get displayNameOptional => 'Nama Tampilan (opsional)';

  @override
  String get sendTips => 'Kirim saya tips dan promo';

  @override
  String get pleaseWait => 'Mohon tunggu...';

  @override
  String get or => 'atau';

  @override
  String get continueWithGoogle => 'Lanjutkan dengan Google';

  @override
  String get continueWithGoogleKeep =>
      'Lanjutkan dengan Google dan simpan stiker';

  @override
  String get alreadyHaveAccount => 'Sudah punya akun? Masuk';

  @override
  String get newHere => 'Baru di sini? Buat akun';

  @override
  String get saveYourSticker => 'Simpan stiker Anda';

  @override
  String get guestSaveWarning =>
      'Anda membuat stiker sebagai tamu. Buat akun untuk menyimpan dan membagikannya.';

  @override
  String get guestCreateAccountDesc =>
      'Buat akun untuk menyimpan dan membagikan stiker Anda.';

  @override
  String get guestSignInDesc =>
      'Masuk ke akun Anda untuk mengakses stiker Anda.';

  @override
  String get guestWallWarning =>
      'Stiker tamu tidak dapat dipindahkan ke akun yang sudah ada. Jika Anda melanjutkan masuk, stiker tamu ini akan dibuang.';

  @override
  String get privacyPolicy => 'Kebijakan Privasi';

  @override
  String get termsOfService => 'Ketentuan Layanan';

  @override
  String get legalTitle => 'Ketentuan Layanan & Kebijakan Privasi';

  @override
  String get legalConsentText =>
      'Saya telah membaca dan menyetujui Ketentuan Layanan dan Kebijakan Privasi';

  @override
  String get createMyFirstSticker => 'Buat Stiker Pertama Saya';

  @override
  String get onboardingCreateTitle => 'Buat stiker Anda';

  @override
  String get onboardingCreateDesc =>
      'Tulis ide singkat, pilih gaya, lalu buat stiker Anda.';

  @override
  String get onboardingPackTitle => 'Tambahkan ke pack';

  @override
  String get onboardingPackDesc =>
      'Pilih atau buat pack, lalu tambahkan 1-3 emoji agar stiker mudah ditemukan di WhatsApp.';

  @override
  String get onboardingWhatsAppTitle => 'Tambahkan pack Anda ke WhatsApp';

  @override
  String get onboardingWhatsAppDesc =>
      'Tambahkan minimal 3 stiker ke pack, lalu ketuk Ekspor ke WhatsApp.';

  @override
  String get anonymousUser => 'Pengguna Anonim';

  @override
  String get editDisplayName => 'Ubah nama tampilan';

  @override
  String get subscription => 'Langganan';

  @override
  String get plusMember => 'Anggota Plus';

  @override
  String get freeTier => 'Tier Gratis';

  @override
  String validUntil(Object date) {
    return 'Berlaku hingga $date';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get creditHistory => 'Riwayat Kredit';

  @override
  String get failedToLoadTransactions => 'Gagal memuat transaksi';

  @override
  String get noTransactionsYet => 'Belum ada transaksi';

  @override
  String get viewAll => 'Lihat semua';

  @override
  String get earnings => 'Pendapatan';

  @override
  String get spent => 'Pengeluaran';

  @override
  String get rewards => 'Hadiah';

  @override
  String get emailMarketing => 'Email Pemasaran';

  @override
  String get receiveTips => 'Terima tips dan promo';

  @override
  String get changePassword => 'Ubah Kata Sandi';

  @override
  String get updatePassword => 'Perbarui kata sandi akun Anda';

  @override
  String get howItWorks => 'Cara Kerja';

  @override
  String get logout => 'Keluar';

  @override
  String get signOutDevice => 'Keluar dari perangkat ini';

  @override
  String get deleteAccount => 'Hapus Akun';

  @override
  String get deleteAccountWarning =>
      'Tindakan ini menghapus akun Anda beserta semua data terkait secara permanen. Tidak dapat dibatalkan.';

  @override
  String get language => 'Bahasa';

  @override
  String get english => 'English';

  @override
  String get bahasaIndonesia => 'Bahasa Indonesia';

  @override
  String get emailAccount => 'Akun Email';

  @override
  String get googleAccount => 'Akun Google';

  @override
  String get guestAccount => 'Akun Tamu';

  @override
  String get externalAccount => 'Akun Eksternal';

  @override
  String get creditTopup => 'Isi Ulang Kredit';

  @override
  String get dailyReward => 'Hadiah Harian';

  @override
  String get stickerGeneration => 'Pembuatan Stiker';

  @override
  String get refund => 'Pengembalian';

  @override
  String get subscriptionGrant => 'Hibah Langganan';

  @override
  String get missionReward => 'Hadiah Misi';

  @override
  String get expired => 'Kedaluwarsa';

  @override
  String get locked => 'Terkunci';

  @override
  String nextMonthlyCredits(Object amount, Object date) {
    return 'Kredit bulanan berikutnya (+$amount) pada $date';
  }

  @override
  String creditsRemaining(Object count) {
    return '$count tersisa';
  }

  @override
  String get takePhoto => 'Ambil foto';

  @override
  String get chooseFromGallery => 'Pilih dari galeri';

  @override
  String get currentPassword => 'Kata sandi saat ini';

  @override
  String get enterCurrentPassword => 'Masukkan kata sandi saat ini';

  @override
  String get newPassword => 'Kata sandi baru';

  @override
  String get confirmNewPassword => 'Konfirmasi kata sandi baru';

  @override
  String get passwordsDoNotMatch => 'Kata sandi tidak cocok';

  @override
  String get change => 'Ubah';

  @override
  String get editDisplayNameHint => 'Masukkan nama Anda';

  @override
  String get howItWorksSubtitle =>
      'Buat stiker, susun pack, lalu tambahkan ke WhatsApp';

  @override
  String get deleteAccountSubtitle =>
      'Hapus akun dan data Anda secara permanen';

  @override
  String get comingSoon => 'Segera Hadir';

  @override
  String get comingSoonBody => 'Upgrade langganan Plus akan segera tersedia!';

  @override
  String get ok => 'OK';

  @override
  String get logoutConfirmBody =>
      'Anda perlu masuk lagi untuk menggunakan aplikasi di perangkat ini.';

  @override
  String get yourStickers => 'Stiker Anda';

  @override
  String get clear => 'Bersihkan';

  @override
  String get failedToLoad => 'Gagal memuat';

  @override
  String get status => 'Status';

  @override
  String get preset => 'Gaya';

  @override
  String get date => 'Tanggal';

  @override
  String get dateFilter => 'Filter tanggal';

  @override
  String get noMatchFilters => 'Tidak ada stiker yang cocok dengan filter';

  @override
  String get clearFilters => 'Bersihkan filter';

  @override
  String get historyNoStickersYet => 'Belum ada stiker — buat yang pertama!';

  @override
  String get success => 'Berhasil';

  @override
  String get pending => 'Menunggu';

  @override
  String get failed => 'Gagal';

  @override
  String get regenerateSamePrompt => 'Buat ulang dengan prompt sama';

  @override
  String get plusOnly => 'Khusus Plus';

  @override
  String get regeneratePlusFeature => 'Buat ulang adalah fitur Plus';

  @override
  String featurePlusOnly(Object feature) {
    return '$feature adalah fitur Plus';
  }

  @override
  String get searchPlusFeature => 'Pencarian teks adalah fitur Plus';

  @override
  String get searchStickers => 'Cari stiker...';

  @override
  String get shareFailed => 'Gagal membagikan stiker';

  @override
  String get sortNewest => 'Terbaru dulu';

  @override
  String get sortOldest => 'Terlama dulu';

  @override
  String get sortPresetAZ => 'Gaya A-Z';

  @override
  String get allTime => 'Semua waktu';

  @override
  String get last7d => '7 hari terakhir';

  @override
  String get last30d => '30 hari terakhir';

  @override
  String get last90d => '90 hari terakhir';

  @override
  String get signInRequired => 'Perlu masuk';

  @override
  String get claimFailed => 'Klaim gagal';

  @override
  String get checkInSuccessful => 'Check-in berhasil!';

  @override
  String get missionCompleted => 'Misi selesai!';

  @override
  String get shareRewardClaimed => 'Hadiah berbagi diklaim!';

  @override
  String get dailyRewards => 'Hadiah Harian';

  @override
  String get quickRewards => 'Hadiah Cepat';

  @override
  String get achievements => 'Pencapaian';

  @override
  String get waitingShareOpened => 'Menunggu tautan berbagi Anda dibuka';

  @override
  String shareMissionDesc(Object minutes) {
    return 'Buka tautan yang Anda bagikan dari WhatsApp / IG / dll untuk klaim kredit Anda. Tautan kedaluwarsa sekitar $minutes menit.';
  }

  @override
  String get copyLink => 'Salin tautan';

  @override
  String get linkCopied => 'Tautan disalin';

  @override
  String get claim => 'Klaim';

  @override
  String get watchAd => 'Tonton Iklan';

  @override
  String get completed => 'Selesai';

  @override
  String get requiresPlus => 'Perlu Plus';

  @override
  String get awaitingLinkClick => 'Menunggu tautan diklik';

  @override
  String get dailyLimitReached => 'Batas harian tercapai';

  @override
  String get cycleComplete => 'Siklus selesai!';

  @override
  String nextIn(Object duration) {
    return 'Berikutnya dalam $duration';
  }

  @override
  String get startNewCycle => 'Mulai siklus baru';

  @override
  String get checkedIn => 'Sudah check-in';

  @override
  String get checkIn => 'Check-in';

  @override
  String missionRewardCredits(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count kredit',
      one: '+$count kredit',
    );
    return '$_temp0';
  }

  @override
  String get missionFirstStickerLabel => 'Buat stiker pertama Anda';

  @override
  String get missionFirstStickerDesc => 'Buat stiker pertama Anda';

  @override
  String get missionDailyLoginLabel => 'Check-in harian';

  @override
  String get missionDailyLoginDesc => 'Buka aplikasi hari ini';

  @override
  String get missionTryAllPresetsLabel => 'Penjelajah gaya';

  @override
  String get missionTryAllPresetsDesc => 'Coba semua 4 preset gratis';

  @override
  String get missionPlusFirst3dLabel => 'Plus: render 3D pertama';

  @override
  String get missionPlusFirst3dDesc => 'Buat stiker chibi_3d pertama Anda';

  @override
  String get missionPlusStreak7Label => 'Plus: streak mingguan';

  @override
  String get missionPlusStreak7Desc => 'Buat stiker 7 hari berturut-turut';

  @override
  String get missionWatchAdLabel => 'Tonton iklan video';

  @override
  String get missionWatchAdDesc =>
      'Tonton iklan berhadiah untuk mendapat kredit';

  @override
  String get missionShareLabel => 'Bagikan BikinStiker';

  @override
  String get missionShareDesc => 'Bagikan aplikasi ke media sosial';

  @override
  String get newPack => 'Pack Baru';

  @override
  String get noPacksYet => 'Belum ada pack';

  @override
  String get packOrgGuidance =>
      'Buat pack untuk mengatur stiker Anda, lalu ekspor ke WhatsApp.';

  @override
  String get failedCreatePack => 'Gagal membuat pack';

  @override
  String get newStickerPack => 'Pack Stiker Baru';

  @override
  String get packName => 'Nama pack';

  @override
  String get enterName => 'Masukkan nama';

  @override
  String get nameTooLong => 'Nama maksimal 128 karakter';

  @override
  String get whatsAppPackGuidance =>
      'Pack tersinkron ke WhatsApp dengan nama, ikon tray, dan kata kunci emoji.';

  @override
  String get packNameHint => 'mis. Kucing Lucu Saya';

  @override
  String get packCreateGuidance =>
      'Anda dapat menambahkan stiker ke pack ini setelah membuatnya. Anda perlu minimal 3 stiker untuk mengimpor pack ke WhatsApp.';

  @override
  String get createPack => 'Buat Pack';

  @override
  String get pack => 'Pack';

  @override
  String get rename => 'Ubah nama';

  @override
  String get errorLoadingPack => 'Gagal memuat pack';

  @override
  String get packNotFound => 'Pack tidak ditemukan';

  @override
  String get exportToWhatsApp => 'Ekspor ke WhatsApp';

  @override
  String addMoreStickers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tambahkan $count stiker lagi',
      one: 'Tambahkan 1 stiker lagi',
    );
    return '$_temp0';
  }

  @override
  String get openingWhatsApp => 'Membuka WhatsApp...';

  @override
  String get whatsAppNotInstalled =>
      'WhatsApp tidak terpasang di perangkat ini.';

  @override
  String get renamePack => 'Ubah Nama Pack';

  @override
  String get deletePackQuestion => 'Hapus Pack?';

  @override
  String get removeStickerQuestion => 'Hapus Stiker?';

  @override
  String get packLockedMessage =>
      'Pack ini terkunci. Upgrade ke Plus untuk membukanya.';

  @override
  String get upgradeToPlus => 'Upgrade ke Plus';

  @override
  String get packReadyCallout => 'Pack Anda siap diekspor ke WhatsApp!';

  @override
  String get packNoStickersYet => 'Belum ada stiker';

  @override
  String get searchEmojis => 'Cari emoji...';

  @override
  String get createNewPack => 'Buat pack baru';

  @override
  String get selectEmoji => 'Pilih minimal satu emoji';

  @override
  String get packSlots => 'Slot pack';

  @override
  String packSlotsUsed(num count, Object total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dari $total terpakai',
      one: '1 dari $total terpakai',
    );
    return '$_temp0';
  }

  @override
  String get packLimitReached =>
      'Anda telah mencapai batas pack. Hapus pack untuk membuat yang baru.';

  @override
  String get thanksForFeedback => 'Terima kasih atas masukan Anda';

  @override
  String get surpriseMe => 'Kejutkan saya';

  @override
  String get goodResult => 'Hasil bagus';

  @override
  String get poorResult => 'Hasil kurang bagus';

  @override
  String get rateThisResult => 'Beri nilai';

  @override
  String get choosePackEmojis =>
      'Pilih pack dan pilih 1-3 emoji untuk WhatsApp.';

  @override
  String emojiCount(Object count) {
    return 'Emoji ($count/3)';
  }

  @override
  String get noRecentEmojis => 'Belum ada emoji terbaru';

  @override
  String noEmojisMatch(Object query) {
    return 'Tidak ada emoji yang cocok dengan \"$query\"';
  }

  @override
  String get packLimitReachedTitle => 'Batas pack tercapai';

  @override
  String get noPacksYetTitle => 'Belum ada pack';

  @override
  String get packLimitReachedDesc => 'Hapus pack untuk membuat yang baru.';

  @override
  String get noPacksYetDesc => 'Buat pack pertama Anda untuk mengatur stiker.';

  @override
  String get createNewPackButton => 'Buat pack baru';

  @override
  String get createPackButton => 'Buat Pack';

  @override
  String get selectEmojiError => 'Pilih minimal satu emoji';

  @override
  String packReadyExport(Object name) {
    return '\"$name\" siap diekspor ke WhatsApp.';
  }

  @override
  String addedToPack(Object count, Object name) {
    return 'Ditambahkan ke \"$name\". Tambah $count stiker lagi untuk ekspor.';
  }

  @override
  String get presetKawaiiLabel => 'Kawaii';

  @override
  String get presetKawaiiDesc => 'Chibi pastel yang lucu';

  @override
  String get presetPixelArtLabel => 'Pixel Art';

  @override
  String get presetPixelArtDesc => 'Piksel retro 16-bit';

  @override
  String get presetVectorFlatLabel => 'Vektor Datar';

  @override
  String get presetVectorFlatDesc => 'Ilustrasi datar tegas';

  @override
  String get presetChibi3dLabel => '3D Chibi';

  @override
  String get presetChibi3dDesc => 'Render 3d mengkilap';

  @override
  String get presetRetroStickerLabel => 'Retro';

  @override
  String get presetRetroStickerDesc => 'Nuansa halftone 90an';

  @override
  String get consentErrorTitle => 'Tidak dapat mengonfirmasi persetujuan';

  @override
  String get consentErrorBody =>
      'Kami tidak dapat mengonfirmasi dokumen hukum Anda saat ini. Periksa koneksi Anda dan coba lagi.';

  @override
  String get consentDocsChanged =>
      'Dokumen hukum telah diperbarui. Harap perbarui aplikasi untuk melanjutkan.';

  @override
  String get withdrawPrivacy => 'Cabut Persetujuan Privasi';

  @override
  String get withdrawPrivacySub =>
      'Hentikan pemrosesan berbasis persetujuan (Ketentuan tetap berlaku).';

  @override
  String get withdrawPrivacyBody =>
      'Ini menghentikan pemrosesan yang bergantung pada persetujuan Anda.';

  @override
  String get withdrawPrivacyConfirm => 'Cabut';
}
