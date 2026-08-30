// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BikinStiker';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get retry => 'Retry';

  @override
  String get share => 'Share';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get all => 'All';

  @override
  String get error => 'Error';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get unknown => 'Unknown';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get preparingGuestSession => 'Preparing your guest session...';

  @override
  String get createAccount => 'Create account';

  @override
  String get missions => 'Missions';

  @override
  String get myPacks => 'My Packs';

  @override
  String get history => 'History';

  @override
  String get profile => 'Profile';

  @override
  String get myStickerPacks => 'My Sticker Packs';

  @override
  String get typePromptFirst => 'Type a short prompt first';

  @override
  String promptTooLong(Object count) {
    return 'Prompt must be $count characters or less';
  }

  @override
  String get chooseValidStyle => 'Choose a valid style';

  @override
  String get typeYourText => 'Type your text';

  @override
  String get describeYourSticker => 'Describe your sticker';

  @override
  String get failedToLoadStyles => 'Failed to load styles';

  @override
  String get inputHintTextOnly => 'e.g. HELLO, YUM, WOW';

  @override
  String get inputHintSubject => 'e.g. a smiling boba tea cup waving hello';

  @override
  String get useLast => 'Use last';

  @override
  String get captionOptional => 'Caption (optional)';

  @override
  String get captionExample => 'e.g. READY';

  @override
  String get position => 'Position';

  @override
  String get top => 'Top';

  @override
  String get bottom => 'Bottom';

  @override
  String get guestCredits => 'Guest Credits';

  @override
  String get creditsPlus => 'Credits (Plus)';

  @override
  String get credits => 'Credits';

  @override
  String get createAccountForCredits => 'Create an account for 5 credits';

  @override
  String get lowBalance => 'Low balance';

  @override
  String get low => 'Low';

  @override
  String get chooseStyle => 'Choose a style';

  @override
  String get chooseStyleTitle => 'Choose style';

  @override
  String get notEnoughCredits => 'Not enough credits';

  @override
  String get generating => 'Generating…';

  @override
  String generateSticker(Object count) {
    return 'Generate Sticker ($count credit)';
  }

  @override
  String failedToShare(Object error) {
    return 'Failed to share sticker: $error';
  }

  @override
  String exportFailed(Object message) {
    return 'Export failed: $message';
  }

  @override
  String get conjuringSticker => 'Conjuring your sticker…';

  @override
  String get nextAddToPack => 'Next: add this sticker to a pack';

  @override
  String get addToPack => 'Add to Pack';

  @override
  String get notEnoughCreditsToGenerate => 'Not enough credits to generate.';

  @override
  String get generationFailed => 'Generation failed';

  @override
  String get createAccountSaveShare =>
      'Create an account to save or share this sticker.';

  @override
  String get createAccountKeepSticker => 'Create account and keep sticker';

  @override
  String get signInExistingAccount => 'Sign in to existing account';

  @override
  String get guestDiscardWarning =>
      'If you sign in to an existing account, this guest sticker will be discarded.';

  @override
  String get tooManyRequests =>
      'Too many requests. Please try again in a few minutes.';

  @override
  String tooManyRequestsWait(Object seconds) {
    return 'Too many requests. Please wait ${seconds}s.';
  }

  @override
  String generationRunning(Object seconds) {
    return 'A generation is already running. Please wait ${seconds}s.';
  }

  @override
  String get generationInProgress =>
      'A sticker generation is already in progress.';

  @override
  String get noStylesAvailable => 'No styles available right now';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String get tagline => 'AI-powered WhatsApp sticker generator';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordMin => 'Min 6 characters';

  @override
  String get displayNameOptional => 'Display Name (optional)';

  @override
  String get sendTips => 'Send me tips and promotions';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get or => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithGoogleKeep => 'Continue with Google and keep sticker';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get newHere => 'New here? Create account';

  @override
  String get saveYourSticker => 'Save your sticker';

  @override
  String get guestSaveWarning =>
      'You\'ve generated a sticker as a guest. Create an account to save and share it.';

  @override
  String get guestCreateAccountDesc =>
      'Create an account to save and share your stickers.';

  @override
  String get guestSignInDesc =>
      'Sign in to your existing account to access your stickers.';

  @override
  String get guestWallWarning =>
      'Guest stickers cannot be moved to an existing account. If you continue signing in, this guest sticker will be discarded.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get legalTitle => 'Terms of Service & Privacy Policy';

  @override
  String get legalConsentText =>
      'I have read and accept the Terms of Service and Privacy Policy';

  @override
  String get createMyFirstSticker => 'Create My First Sticker';

  @override
  String get onboardingCreateTitle => 'Create your sticker';

  @override
  String get onboardingCreateDesc =>
      'Write a short idea, choose a style, then generate your sticker.';

  @override
  String get onboardingPackTitle => 'Add it to a pack';

  @override
  String get onboardingPackDesc =>
      'Choose or create a pack, then add 1-3 emojis so the sticker is easy to find in WhatsApp.';

  @override
  String get onboardingWhatsAppTitle => 'Add your pack to WhatsApp';

  @override
  String get onboardingWhatsAppDesc =>
      'Add at least 3 stickers to a pack, then tap Export to WhatsApp.';

  @override
  String get anonymousUser => 'Anonymous User';

  @override
  String get editDisplayName => 'Edit display name';

  @override
  String get subscription => 'Subscription';

  @override
  String get plusMember => 'Plus Member';

  @override
  String get freeTier => 'Free Tier';

  @override
  String validUntil(Object date) {
    return 'Valid until $date';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get creditHistory => 'Credit History';

  @override
  String get failedToLoadTransactions => 'Failed to load transactions';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get viewAll => 'View all';

  @override
  String get earnings => 'Earnings';

  @override
  String get spent => 'Spent';

  @override
  String get rewards => 'Rewards';

  @override
  String get emailMarketing => 'Email Marketing';

  @override
  String get receiveTips => 'Receive tips and promotions';

  @override
  String get changePassword => 'Change Password';

  @override
  String get updatePassword => 'Update your account password';

  @override
  String get howItWorks => 'How It Works';

  @override
  String get logout => 'Logout';

  @override
  String get signOutDevice => 'Sign out of this device';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'This action permanently deletes your account and all associated data. This cannot be undone.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get bahasaIndonesia => 'Bahasa Indonesia';

  @override
  String get emailAccount => 'Email Account';

  @override
  String get googleAccount => 'Google Account';

  @override
  String get guestAccount => 'Guest Account';

  @override
  String get externalAccount => 'External Account';

  @override
  String get creditTopup => 'Credit Top-up';

  @override
  String get dailyReward => 'Daily Reward';

  @override
  String get stickerGeneration => 'Sticker Generation';

  @override
  String get refund => 'Refund';

  @override
  String get subscriptionGrant => 'Subscription Grant';

  @override
  String get missionReward => 'Mission Reward';

  @override
  String get expired => 'Expired';

  @override
  String get locked => 'Locked';

  @override
  String nextMonthlyCredits(Object amount, Object date) {
    return 'Next monthly credits (+$amount) on $date';
  }

  @override
  String creditsRemaining(Object count) {
    return '$count remaining';
  }

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get enterCurrentPassword => 'Enter current password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get change => 'Change';

  @override
  String get editDisplayNameHint => 'Enter your name';

  @override
  String get howItWorksSubtitle =>
      'Generate stickers, build a pack, then add it to WhatsApp';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and data';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get comingSoonBody =>
      'Plus subscription upgrade will be available soon!';

  @override
  String get ok => 'OK';

  @override
  String get logoutConfirmBody =>
      'You will need to sign in again to use the app on this device.';

  @override
  String get yourStickers => 'Your stickers';

  @override
  String get clear => 'Clear';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get status => 'Status';

  @override
  String get preset => 'Preset';

  @override
  String get date => 'Date';

  @override
  String get dateFilter => 'Date filter';

  @override
  String get noMatchFilters => 'No stickers match your filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get historyNoStickersYet =>
      'No stickers yet — generate your first one!';

  @override
  String get success => 'Success';

  @override
  String get pending => 'Pending';

  @override
  String get failed => 'Failed';

  @override
  String get regenerateSamePrompt => 'Regenerate with same prompt';

  @override
  String get plusOnly => 'Plus only';

  @override
  String get regeneratePlusFeature => 'Regenerate is a Plus feature';

  @override
  String featurePlusOnly(Object feature) {
    return '$feature is a Plus feature';
  }

  @override
  String get searchPlusFeature => 'Text search is a Plus feature';

  @override
  String get searchStickers => 'Search stickers...';

  @override
  String get shareFailed => 'Failed to share sticker';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortPresetAZ => 'Preset A-Z';

  @override
  String get allTime => 'All time';

  @override
  String get last7d => 'Last 7 days';

  @override
  String get last30d => 'Last 30 days';

  @override
  String get last90d => 'Last 90 days';

  @override
  String get signInRequired => 'Sign in required';

  @override
  String get claimFailed => 'Claim failed';

  @override
  String get checkInSuccessful => 'Check-in successful!';

  @override
  String get missionCompleted => 'Mission completed!';

  @override
  String get shareRewardClaimed => 'Share reward claimed!';

  @override
  String get dailyRewards => 'Daily Rewards';

  @override
  String get quickRewards => 'Quick Rewards';

  @override
  String get achievements => 'Achievements';

  @override
  String get waitingShareOpened => 'Waiting for your share to be opened';

  @override
  String shareMissionDesc(Object minutes) {
    return 'Open the link you shared from WhatsApp / IG / etc to claim your credits. Link expires in about $minutes min.';
  }

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get claim => 'Claim';

  @override
  String get watchAd => 'Watch Ad';

  @override
  String get completed => 'Completed';

  @override
  String get requiresPlus => 'Requires Plus';

  @override
  String get awaitingLinkClick => 'Awaiting link click';

  @override
  String get dailyLimitReached => 'Daily limit reached';

  @override
  String get cycleComplete => 'Cycle complete!';

  @override
  String nextIn(Object duration) {
    return 'Next in $duration';
  }

  @override
  String get startNewCycle => 'Start new cycle';

  @override
  String get checkedIn => 'Checked in';

  @override
  String get checkIn => 'Check-in';

  @override
  String missionRewardCredits(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count credits',
      one: '+$count credit',
    );
    return '$_temp0';
  }

  @override
  String get missionFirstStickerLabel => 'Create your first sticker';

  @override
  String get missionFirstStickerDesc => 'Generate your very first sticker';

  @override
  String get missionDailyLoginLabel => 'Daily check-in';

  @override
  String get missionDailyLoginDesc => 'Open the app today';

  @override
  String get missionTryAllPresetsLabel => 'Style explorer';

  @override
  String get missionTryAllPresetsDesc => 'Try all 4 free presets';

  @override
  String get missionPlusFirst3dLabel => 'Plus: first 3D render';

  @override
  String get missionPlusFirst3dDesc => 'Generate your first chibi_3d sticker';

  @override
  String get missionPlusStreak7Label => 'Plus: weekly streak';

  @override
  String get missionPlusStreak7Desc => 'Generate a sticker 7 days in a row';

  @override
  String get missionWatchAdLabel => 'Watch video ad';

  @override
  String get missionWatchAdDesc => 'Watch a rewarded ad to earn credits';

  @override
  String get missionShareLabel => 'Share BikinStiker';

  @override
  String get missionShareDesc => 'Share the app to social media';

  @override
  String get newPack => 'New Pack';

  @override
  String get noPacksYet => 'No packs yet';

  @override
  String get packOrgGuidance =>
      'Create packs to organize your stickers, then export them to WhatsApp.';

  @override
  String get failedCreatePack => 'Failed to create pack';

  @override
  String get newStickerPack => 'New Sticker Pack';

  @override
  String get packName => 'Pack name';

  @override
  String get enterName => 'Please enter a name';

  @override
  String get nameTooLong => 'Name must be 128 characters or less';

  @override
  String get whatsAppPackGuidance =>
      'Packs sync to WhatsApp with a name, tray icon, and emoji keywords.';

  @override
  String get packNameHint => 'e.g., My Cute Cats';

  @override
  String get packCreateGuidance =>
      'You can add stickers to this pack after creating it. You need at least 3 stickers to import the pack to WhatsApp.';

  @override
  String get createPack => 'Create Pack';

  @override
  String get pack => 'Pack';

  @override
  String get rename => 'Rename';

  @override
  String get errorLoadingPack => 'Error loading pack';

  @override
  String get packNotFound => 'Pack not found';

  @override
  String get exportToWhatsApp => 'Export to WhatsApp';

  @override
  String addMoreStickers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count more stickers',
      one: 'Add 1 more sticker',
    );
    return '$_temp0';
  }

  @override
  String get openingWhatsApp => 'Opening WhatsApp...';

  @override
  String get whatsAppNotInstalled =>
      'WhatsApp is not installed on this device.';

  @override
  String get renamePack => 'Rename Pack';

  @override
  String get deletePackQuestion => 'Delete Pack?';

  @override
  String get removeStickerQuestion => 'Remove Sticker?';

  @override
  String get packLockedMessage =>
      'This pack is locked. Upgrade to Plus to unlock it.';

  @override
  String get upgradeToPlus => 'Upgrade to Plus';

  @override
  String get packReadyCallout => 'Your pack is ready to export to WhatsApp!';

  @override
  String get packNoStickersYet => 'No stickers yet';

  @override
  String get searchEmojis => 'Search emojis...';

  @override
  String get createNewPack => 'Create new pack';

  @override
  String get selectEmoji => 'Please select at least one emoji';

  @override
  String get packSlots => 'Pack slots';

  @override
  String packSlotsUsed(num count, Object total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of $total used',
      one: '1 of $total used',
    );
    return '$_temp0';
  }

  @override
  String get packLimitReached =>
      'You have reached your pack limit. Delete a pack to create a new one.';

  @override
  String get thanksForFeedback => 'Thanks for the feedback';

  @override
  String get surpriseMe => 'Surprise me';

  @override
  String trySuggestion(Object suggestion) {
    return 'Try: \"$suggestion\"';
  }

  @override
  String get surpriseConfirmTitleFree => 'Free surprise idea';

  @override
  String get surpriseConfirmTitlePaid => 'Use 1 credit?';

  @override
  String surpriseConfirmBodyFree(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count free surprises left today.',
      one: '1 free surprise left today.',
    );
    return '$_temp0';
  }

  @override
  String surpriseConfirmBodyPaid(Object balance) {
    return 'An AI will craft a fresh sticker idea for you. Balance after: $balance credits.';
  }

  @override
  String get surpriseCostLine => 'Cost: 1 credit';

  @override
  String get surpriseLoading => 'Crafting an idea...';

  @override
  String get surpriseFailed => 'Couldn\'t craft an idea right now.';

  @override
  String get surpriseLocalFallback => 'Using a local suggestion instead.';

  @override
  String surpriseWaitSeconds(Object seconds) {
    return 'Please wait $seconds seconds before trying again.';
  }

  @override
  String get surpriseTopUpViaMissions => 'Earn credits on the Missions page.';

  @override
  String get goodResult => 'Good result';

  @override
  String get poorResult => 'Poor result';

  @override
  String get rateThisResult => 'Rate this result';

  @override
  String get choosePackEmojis =>
      'Choose a pack and select 1-3 emojis for WhatsApp.';

  @override
  String emojiCount(Object count) {
    return 'Emojis ($count/3)';
  }

  @override
  String get noRecentEmojis => 'No recent emojis yet';

  @override
  String noEmojisMatch(Object query) {
    return 'No emojis match \"$query\"';
  }

  @override
  String get packLimitReachedTitle => 'Pack limit reached';

  @override
  String get noPacksYetTitle => 'No packs yet';

  @override
  String get packLimitReachedDesc => 'Delete a pack to create a new one.';

  @override
  String get noPacksYetDesc => 'Create your first pack to organize stickers.';

  @override
  String get createNewPackButton => 'Create new pack';

  @override
  String get createPackButton => 'Create Pack';

  @override
  String get selectEmojiError => 'Please select at least one emoji';

  @override
  String packReadyExport(Object name) {
    return '\"$name\" is ready to export to WhatsApp.';
  }

  @override
  String addedToPack(Object count, Object name) {
    return 'Added to \"$name\". Add $count more sticker$count to export.';
  }

  @override
  String get presetKawaiiLabel => 'Kawaii';

  @override
  String get presetKawaiiDesc => 'Cute pastel chibi';

  @override
  String get presetPixelArtLabel => 'Pixel Art';

  @override
  String get presetPixelArtDesc => '16-bit retro pixels';

  @override
  String get presetVectorFlatLabel => 'Vector Flat';

  @override
  String get presetVectorFlatDesc => 'Bold flat illustration';

  @override
  String get presetChibi3dLabel => '3D Chibi';

  @override
  String get presetChibi3dDesc => 'Glossy 3d render';

  @override
  String get presetRetroStickerLabel => 'Retro';

  @override
  String get presetRetroStickerDesc => '90s halftone vibe';

  @override
  String get consentErrorTitle => 'Unable to confirm consent';

  @override
  String get consentErrorBody =>
      'We could not confirm your legal documents right now. Check your connection and try again.';

  @override
  String get consentDocsChanged =>
      'Legal documents have been updated. Please update the app to continue.';

  @override
  String get withdrawPrivacy => 'Revoke Privacy Consent';

  @override
  String get withdrawPrivacySub =>
      'Stop consent-based processing (Terms stay valid).';

  @override
  String get withdrawPrivacyBody =>
      'This stops processing that relies on your consent.';

  @override
  String get withdrawPrivacyConfirm => 'Revoke';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Send';

  @override
  String get tierPlus => 'Plus';

  @override
  String get tierFree => 'Free';

  @override
  String get showcaseTitle => 'Showcase';

  @override
  String get showcaseSearchHint => 'Search packs, creators, tags...';

  @override
  String get showcaseSortTrending => 'Trending';

  @override
  String get showcaseSortTopRated => 'Top rated';

  @override
  String get showcaseSortPopular => 'Popular';

  @override
  String get showcaseSortNewest => 'Newest';

  @override
  String get showcaseEmpty =>
      'No packs on showcase yet.\nList yours from a pack page!';

  @override
  String get showcaseOwned => 'Owned';

  @override
  String get showcaseReport => 'Report listing';

  @override
  String showcaseBySeller(String seller) {
    return 'by $seller';
  }

  @override
  String showcaseStickerCount(int count) {
    return '$count stickers';
  }

  @override
  String get showcaseUnlist => 'Remove from Showcase';

  @override
  String get showcaseUnlistShort => 'Unlist';

  @override
  String get showcaseUnlistConfirm =>
      'Buyers who already purchased keep their copies. Unlist this pack?';

  @override
  String get showcaseUnlisted => 'Pack removed from Showcase.';

  @override
  String get showcaseOpenOwnedPack => 'Open my copy';

  @override
  String showcaseBuyFor(int price) {
    return 'Get for $price credits';
  }

  @override
  String get showcaseConfirmTitle => 'Add to my packs?';

  @override
  String showcaseConfirmBody(int price, String tier, int after) {
    return '$price credits will be spent ($tier price). Balance afterwards: $after.';
  }

  @override
  String showcaseNotEnoughCredits(int price, int balance) {
    return 'You need $price credits but only have $balance.';
  }

  @override
  String get showcasePurchaseSuccess => 'Pack added to your collection!';

  @override
  String get showcasePurchaseRefunded =>
      'Purchase was refunded — the pack could not be copied.';

  @override
  String get showcasePurchasePendingRetry =>
      'Copy is still processing. Try again shortly or refund from history.';

  @override
  String get showcaseListTitle => 'List on Showcase';

  @override
  String get showcaseEditTitle => 'Edit listing';

  @override
  String get showcasePriceLabel => 'Base price (credits)';

  @override
  String get showcaseDescriptionHint => 'Describe your pack (optional)...';

  @override
  String get showcaseTagsHint => 'tag1, tag2, tag3...';

  @override
  String get showcaseTagsHelper =>
      'Up to 8 tags, separated by commas (max 24 chars each).';

  @override
  String get showcaseListConfirm => 'Publish';

  @override
  String get showcaseListSuccess => 'Listing saved.';

  @override
  String get showcasePlusRequired => 'Showcase listing is a Plus feature.';

  @override
  String get showcasePurchaseLabel => 'Showcase purchase';

  @override
  String get showcaseSaleLabel => 'Showcase sale';

  @override
  String get showcaseReasonCopyright => 'Copyright / IP infringement';

  @override
  String get showcaseReasonInappropriate => 'Inappropriate content';

  @override
  String get showcaseReasonSpam => 'Spam or misleading';

  @override
  String get showcaseReasonOther => 'Other';

  @override
  String get showcaseReportNoteHint => 'Additional details (optional)...';

  @override
  String get showcaseReportSent => 'Report submitted. Thank you.';

  @override
  String get packListedBadge => 'Listed';

  @override
  String get limitedBadge => 'Limited';

  @override
  String get seasonalSectionTitle => 'Seasonal Styles';

  @override
  String get seasonalSectionInfo => 'Only available for a limited time.';

  @override
  String seasonalEndsOn(String date) {
    return 'Available until $date';
  }

  @override
  String get plusOnlyPreset => 'This style is exclusive to Plus.';

  @override
  String get presetBackToSchoolDoodleLabel => 'Back-to-School Doodle';

  @override
  String get presetBackToSchoolDoodleDesc => 'Hand-drawn school doodles';

  @override
  String get presetCozyStudyClubLabel => 'Cozy Study Club';

  @override
  String get presetCozyStudyClubDesc => 'Soft gouache study comfort';

  @override
  String get presetRainyDaysLabel => 'Rainy Days';

  @override
  String get presetRainyDaysDesc => 'Cozy rainy day watercolor';

  @override
  String get presetAutumnFirstLeafLabel => 'Autumn First Leaf';

  @override
  String get presetAutumnFirstLeafDesc => 'Layered paper-cut autumn';

  @override
  String get presetHarvestMarketLabel => 'Harvest Market';

  @override
  String get presetHarvestMarketDesc => 'Folk-art harvest market';

  @override
  String get presetFriendlySpookyLabel => 'Friendly Spooky';

  @override
  String get presetFriendlySpookyDesc => 'Cute and friendly Halloween';

  @override
  String get presetWitchyPotionLabLabel => 'Witchy Potion Lab';

  @override
  String get presetWitchyPotionLabDesc => 'Glowing magic potion lab';

  @override
  String get presetGothicStainedGlassLabel => 'Gothic Stained Glass';

  @override
  String get presetGothicStainedGlassDesc => 'Elegant gothic glasswork';

  @override
  String get presetPumpkinPatchClayLabel => 'Pumpkin Patch Clay';

  @override
  String get presetPumpkinPatchClayDesc => 'Soft clay pumpkin diorama';

  @override
  String get presetNightForestLinocutLabel => 'Night Forest Linocut';

  @override
  String get presetNightForestLinocutDesc => 'High-contrast night forest print';

  @override
  String get presetGratitudeJournalLabel => 'Gratitude Journal';

  @override
  String get presetGratitudeJournalDesc => 'Hand-painted gratitude notes';

  @override
  String get presetWarmKitchenTableLabel => 'Warm Kitchen Table';

  @override
  String get presetWarmKitchenTableDesc => 'Cozy homemade food illustration';

  @override
  String get presetWoodlandSweaterClubLabel => 'Woodland Sweater Club';

  @override
  String get presetWoodlandSweaterClubDesc => 'Knitted woodland animals';

  @override
  String get presetNovemberRainNoirLabel => 'November Rain Noir';

  @override
  String get presetNovemberRainNoirDesc => 'Cinematic rainy city noir';

  @override
  String get presetDealHunterPopLabel => 'Deal Hunter Pop';

  @override
  String get presetDealHunterPopDesc => 'Bold pop-art sale stickers';

  @override
  String get presetGingerbreadWorkshopLabel => 'Gingerbread Workshop';

  @override
  String get presetGingerbreadWorkshopDesc => 'Edible gingerbread world';

  @override
  String get presetFrostedPaperVillageLabel => 'Frosted Paper Village';

  @override
  String get presetFrostedPaperVillageDesc => 'Paper-cut winter village';

  @override
  String get presetTropicalHolidayCheerLabel => 'Tropical Holiday Cheer';

  @override
  String get presetTropicalHolidayCheerDesc => 'Tropical year-end celebration';

  @override
  String get presetMidnightNewYearChromeLabel => 'Midnight New Year Chrome';

  @override
  String get presetMidnightNewYearChromeDesc => 'Glossy chrome new year party';

  @override
  String get presetYearInReviewScrapbookLabel => 'Year in Review Scrapbook';

  @override
  String get presetYearInReviewScrapbookDesc => 'Scrapbook year-in-review';

  @override
  String get connectionError =>
      'No internet connection. Check your network and try again.';

  @override
  String get sortBy => 'Sort by';

  @override
  String get navHome => 'Home';

  @override
  String get navMissions => 'Missions';

  @override
  String get navPacks => 'Packs';

  @override
  String get navHistory => 'History';

  @override
  String packStickerCount(int count, int max) {
    return '$count/$max stickers';
  }

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';
}
