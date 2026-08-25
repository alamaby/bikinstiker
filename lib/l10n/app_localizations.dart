import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BikinStiker'**
  String get appName;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @preparingGuestSession.
  ///
  /// In en, this message translates to:
  /// **'Preparing your guest session...'**
  String get preparingGuestSession;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @missions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get missions;

  /// No description provided for @myPacks.
  ///
  /// In en, this message translates to:
  /// **'My Packs'**
  String get myPacks;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myStickerPacks.
  ///
  /// In en, this message translates to:
  /// **'My Sticker Packs'**
  String get myStickerPacks;

  /// No description provided for @typePromptFirst.
  ///
  /// In en, this message translates to:
  /// **'Type a short prompt first'**
  String get typePromptFirst;

  /// No description provided for @promptTooLong.
  ///
  /// In en, this message translates to:
  /// **'Prompt must be {count} characters or less'**
  String promptTooLong(Object count);

  /// No description provided for @chooseValidStyle.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid style'**
  String get chooseValidStyle;

  /// No description provided for @typeYourText.
  ///
  /// In en, this message translates to:
  /// **'Type your text'**
  String get typeYourText;

  /// No description provided for @describeYourSticker.
  ///
  /// In en, this message translates to:
  /// **'Describe your sticker'**
  String get describeYourSticker;

  /// No description provided for @failedToLoadStyles.
  ///
  /// In en, this message translates to:
  /// **'Failed to load styles'**
  String get failedToLoadStyles;

  /// No description provided for @inputHintTextOnly.
  ///
  /// In en, this message translates to:
  /// **'e.g. HELLO, YUM, WOW'**
  String get inputHintTextOnly;

  /// No description provided for @inputHintSubject.
  ///
  /// In en, this message translates to:
  /// **'e.g. a smiling boba tea cup waving hello'**
  String get inputHintSubject;

  /// No description provided for @useLast.
  ///
  /// In en, this message translates to:
  /// **'Use last'**
  String get useLast;

  /// No description provided for @captionOptional.
  ///
  /// In en, this message translates to:
  /// **'Caption (optional)'**
  String get captionOptional;

  /// No description provided for @captionExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. READY'**
  String get captionExample;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @bottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get bottom;

  /// No description provided for @guestCredits.
  ///
  /// In en, this message translates to:
  /// **'Guest Credits'**
  String get guestCredits;

  /// No description provided for @creditsPlus.
  ///
  /// In en, this message translates to:
  /// **'Credits (Plus)'**
  String get creditsPlus;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @createAccountForCredits.
  ///
  /// In en, this message translates to:
  /// **'Create an account for 5 credits'**
  String get createAccountForCredits;

  /// No description provided for @lowBalance.
  ///
  /// In en, this message translates to:
  /// **'Low balance'**
  String get lowBalance;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @chooseStyle.
  ///
  /// In en, this message translates to:
  /// **'Choose a style'**
  String get chooseStyle;

  /// No description provided for @chooseStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose style'**
  String get chooseStyleTitle;

  /// No description provided for @notEnoughCredits.
  ///
  /// In en, this message translates to:
  /// **'Not enough credits'**
  String get notEnoughCredits;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get generating;

  /// No description provided for @generateSticker.
  ///
  /// In en, this message translates to:
  /// **'Generate Sticker ({count} credit)'**
  String generateSticker(Object count);

  /// No description provided for @failedToShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share sticker: {error}'**
  String failedToShare(Object error);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {message}'**
  String exportFailed(Object message);

  /// No description provided for @conjuringSticker.
  ///
  /// In en, this message translates to:
  /// **'Conjuring your sticker…'**
  String get conjuringSticker;

  /// No description provided for @nextAddToPack.
  ///
  /// In en, this message translates to:
  /// **'Next: add this sticker to a pack'**
  String get nextAddToPack;

  /// No description provided for @addToPack.
  ///
  /// In en, this message translates to:
  /// **'Add to Pack'**
  String get addToPack;

  /// No description provided for @notEnoughCreditsToGenerate.
  ///
  /// In en, this message translates to:
  /// **'Not enough credits to generate.'**
  String get notEnoughCreditsToGenerate;

  /// No description provided for @generationFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed'**
  String get generationFailed;

  /// No description provided for @createAccountSaveShare.
  ///
  /// In en, this message translates to:
  /// **'Create an account to save or share this sticker.'**
  String get createAccountSaveShare;

  /// No description provided for @createAccountKeepSticker.
  ///
  /// In en, this message translates to:
  /// **'Create account and keep sticker'**
  String get createAccountKeepSticker;

  /// No description provided for @signInExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to existing account'**
  String get signInExistingAccount;

  /// No description provided for @guestDiscardWarning.
  ///
  /// In en, this message translates to:
  /// **'If you sign in to an existing account, this guest sticker will be discarded.'**
  String get guestDiscardWarning;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again in a few minutes.'**
  String get tooManyRequests;

  /// No description provided for @tooManyRequestsWait.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait {seconds}s.'**
  String tooManyRequestsWait(Object seconds);

  /// No description provided for @generationRunning.
  ///
  /// In en, this message translates to:
  /// **'A generation is already running. Please wait {seconds}s.'**
  String generationRunning(Object seconds);

  /// No description provided for @generationInProgress.
  ///
  /// In en, this message translates to:
  /// **'A sticker generation is already in progress.'**
  String get generationInProgress;

  /// No description provided for @noStylesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No styles available right now'**
  String get noStylesAvailable;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'AI-powered WhatsApp sticker generator'**
  String get tagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordMin.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get passwordMin;

  /// No description provided for @displayNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Display Name (optional)'**
  String get displayNameOptional;

  /// No description provided for @sendTips.
  ///
  /// In en, this message translates to:
  /// **'Send me tips and promotions'**
  String get sendTips;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithGoogleKeep.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google and keep sticker'**
  String get continueWithGoogleKeep;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here? Create account'**
  String get newHere;

  /// No description provided for @saveYourSticker.
  ///
  /// In en, this message translates to:
  /// **'Save your sticker'**
  String get saveYourSticker;

  /// No description provided for @guestSaveWarning.
  ///
  /// In en, this message translates to:
  /// **'You\'ve generated a sticker as a guest. Create an account to save and share it.'**
  String get guestSaveWarning;

  /// No description provided for @guestCreateAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Create an account to save and share your stickers.'**
  String get guestCreateAccountDesc;

  /// No description provided for @guestSignInDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your existing account to access your stickers.'**
  String get guestSignInDesc;

  /// No description provided for @guestWallWarning.
  ///
  /// In en, this message translates to:
  /// **'Guest stickers cannot be moved to an existing account. If you continue signing in, this guest sticker will be discarded.'**
  String get guestWallWarning;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service & Privacy Policy'**
  String get legalTitle;

  /// No description provided for @legalConsentText.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the Terms of Service and Privacy Policy'**
  String get legalConsentText;

  /// No description provided for @createMyFirstSticker.
  ///
  /// In en, this message translates to:
  /// **'Create My First Sticker'**
  String get createMyFirstSticker;

  /// No description provided for @onboardingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your sticker'**
  String get onboardingCreateTitle;

  /// No description provided for @onboardingCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Write a short idea, choose a style, then generate your sticker.'**
  String get onboardingCreateDesc;

  /// No description provided for @onboardingPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Add it to a pack'**
  String get onboardingPackTitle;

  /// No description provided for @onboardingPackDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose or create a pack, then add 1-3 emojis so the sticker is easy to find in WhatsApp.'**
  String get onboardingPackDesc;

  /// No description provided for @onboardingWhatsAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your pack to WhatsApp'**
  String get onboardingWhatsAppTitle;

  /// No description provided for @onboardingWhatsAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Add at least 3 stickers to a pack, then tap Export to WhatsApp.'**
  String get onboardingWhatsAppDesc;

  /// No description provided for @anonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous User'**
  String get anonymousUser;

  /// No description provided for @editDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Edit display name'**
  String get editDisplayName;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @plusMember.
  ///
  /// In en, this message translates to:
  /// **'Plus Member'**
  String get plusMember;

  /// No description provided for @freeTier.
  ///
  /// In en, this message translates to:
  /// **'Free Tier'**
  String get freeTier;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntil(Object date);

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @creditHistory.
  ///
  /// In en, this message translates to:
  /// **'Credit History'**
  String get creditHistory;

  /// No description provided for @failedToLoadTransactions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transactions'**
  String get failedToLoadTransactions;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @emailMarketing.
  ///
  /// In en, this message translates to:
  /// **'Email Marketing'**
  String get emailMarketing;

  /// No description provided for @receiveTips.
  ///
  /// In en, this message translates to:
  /// **'Receive tips and promotions'**
  String get receiveTips;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get updatePassword;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signOutDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device'**
  String get signOutDevice;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action permanently deletes your account and all associated data. This cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bahasaIndonesia.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get bahasaIndonesia;

  /// No description provided for @emailAccount.
  ///
  /// In en, this message translates to:
  /// **'Email Account'**
  String get emailAccount;

  /// No description provided for @googleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get googleAccount;

  /// No description provided for @guestAccount.
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get guestAccount;

  /// No description provided for @externalAccount.
  ///
  /// In en, this message translates to:
  /// **'External Account'**
  String get externalAccount;

  /// No description provided for @creditTopup.
  ///
  /// In en, this message translates to:
  /// **'Credit Top-up'**
  String get creditTopup;

  /// No description provided for @dailyReward.
  ///
  /// In en, this message translates to:
  /// **'Daily Reward'**
  String get dailyReward;

  /// No description provided for @stickerGeneration.
  ///
  /// In en, this message translates to:
  /// **'Sticker Generation'**
  String get stickerGeneration;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @subscriptionGrant.
  ///
  /// In en, this message translates to:
  /// **'Subscription Grant'**
  String get subscriptionGrant;

  /// No description provided for @missionReward.
  ///
  /// In en, this message translates to:
  /// **'Mission Reward'**
  String get missionReward;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @nextMonthlyCredits.
  ///
  /// In en, this message translates to:
  /// **'Next monthly credits (+{amount}) on {date}'**
  String nextMonthlyCredits(Object amount, Object date);

  /// No description provided for @creditsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String creditsRemaining(Object count);

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @editDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get editDisplayNameHint;

  /// No description provided for @howItWorksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate stickers, build a pack, then add it to WhatsApp'**
  String get howItWorksSubtitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get deleteAccountSubtitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Plus subscription upgrade will be available soon!'**
  String get comingSoonBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use the app on this device.'**
  String get logoutConfirmBody;

  /// No description provided for @yourStickers.
  ///
  /// In en, this message translates to:
  /// **'Your stickers'**
  String get yourStickers;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @preset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get preset;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dateFilter.
  ///
  /// In en, this message translates to:
  /// **'Date filter'**
  String get dateFilter;

  /// No description provided for @noMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No stickers match your filters'**
  String get noMatchFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @historyNoStickersYet.
  ///
  /// In en, this message translates to:
  /// **'No stickers yet — generate your first one!'**
  String get historyNoStickersYet;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @regenerateSamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Regenerate with same prompt'**
  String get regenerateSamePrompt;

  /// No description provided for @plusOnly.
  ///
  /// In en, this message translates to:
  /// **'Plus only'**
  String get plusOnly;

  /// No description provided for @regeneratePlusFeature.
  ///
  /// In en, this message translates to:
  /// **'Regenerate is a Plus feature'**
  String get regeneratePlusFeature;

  /// No description provided for @featurePlusOnly.
  ///
  /// In en, this message translates to:
  /// **'{feature} is a Plus feature'**
  String featurePlusOnly(Object feature);

  /// No description provided for @searchPlusFeature.
  ///
  /// In en, this message translates to:
  /// **'Text search is a Plus feature'**
  String get searchPlusFeature;

  /// No description provided for @searchStickers.
  ///
  /// In en, this message translates to:
  /// **'Search stickers...'**
  String get searchStickers;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share sticker'**
  String get shareFailed;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortPresetAZ.
  ///
  /// In en, this message translates to:
  /// **'Preset A-Z'**
  String get sortPresetAZ;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @last7d.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7d;

  /// No description provided for @last30d.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30d;

  /// No description provided for @last90d.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get last90d;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequired;

  /// No description provided for @claimFailed.
  ///
  /// In en, this message translates to:
  /// **'Claim failed'**
  String get claimFailed;

  /// No description provided for @checkInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Check-in successful!'**
  String get checkInSuccessful;

  /// No description provided for @missionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mission completed!'**
  String get missionCompleted;

  /// No description provided for @shareRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Share reward claimed!'**
  String get shareRewardClaimed;

  /// No description provided for @dailyRewards.
  ///
  /// In en, this message translates to:
  /// **'Daily Rewards'**
  String get dailyRewards;

  /// No description provided for @quickRewards.
  ///
  /// In en, this message translates to:
  /// **'Quick Rewards'**
  String get quickRewards;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @waitingShareOpened.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your share to be opened'**
  String get waitingShareOpened;

  /// No description provided for @shareMissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Open the link you shared from WhatsApp / IG / etc to claim your credits. Link expires in about {minutes} min.'**
  String shareMissionDesc(Object minutes);

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @requiresPlus.
  ///
  /// In en, this message translates to:
  /// **'Requires Plus'**
  String get requiresPlus;

  /// No description provided for @awaitingLinkClick.
  ///
  /// In en, this message translates to:
  /// **'Awaiting link click'**
  String get awaitingLinkClick;

  /// No description provided for @dailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get dailyLimitReached;

  /// No description provided for @cycleComplete.
  ///
  /// In en, this message translates to:
  /// **'Cycle complete!'**
  String get cycleComplete;

  /// No description provided for @nextIn.
  ///
  /// In en, this message translates to:
  /// **'Next in {duration}'**
  String nextIn(Object duration);

  /// No description provided for @startNewCycle.
  ///
  /// In en, this message translates to:
  /// **'Start new cycle'**
  String get startNewCycle;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get checkedIn;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @missionRewardCredits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+{count} credit} other{+{count} credits}}'**
  String missionRewardCredits(num count);

  /// No description provided for @missionFirstStickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Create your first sticker'**
  String get missionFirstStickerLabel;

  /// No description provided for @missionFirstStickerDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate your very first sticker'**
  String get missionFirstStickerDesc;

  /// No description provided for @missionDailyLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in'**
  String get missionDailyLoginLabel;

  /// No description provided for @missionDailyLoginDesc.
  ///
  /// In en, this message translates to:
  /// **'Open the app today'**
  String get missionDailyLoginDesc;

  /// No description provided for @missionTryAllPresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Style explorer'**
  String get missionTryAllPresetsLabel;

  /// No description provided for @missionTryAllPresetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Try all 4 free presets'**
  String get missionTryAllPresetsDesc;

  /// No description provided for @missionPlusFirst3dLabel.
  ///
  /// In en, this message translates to:
  /// **'Plus: first 3D render'**
  String get missionPlusFirst3dLabel;

  /// No description provided for @missionPlusFirst3dDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate your first chibi_3d sticker'**
  String get missionPlusFirst3dDesc;

  /// No description provided for @missionPlusStreak7Label.
  ///
  /// In en, this message translates to:
  /// **'Plus: weekly streak'**
  String get missionPlusStreak7Label;

  /// No description provided for @missionPlusStreak7Desc.
  ///
  /// In en, this message translates to:
  /// **'Generate a sticker 7 days in a row'**
  String get missionPlusStreak7Desc;

  /// No description provided for @missionWatchAdLabel.
  ///
  /// In en, this message translates to:
  /// **'Watch video ad'**
  String get missionWatchAdLabel;

  /// No description provided for @missionWatchAdDesc.
  ///
  /// In en, this message translates to:
  /// **'Watch a rewarded ad to earn credits'**
  String get missionWatchAdDesc;

  /// No description provided for @missionShareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share BikinStiker'**
  String get missionShareLabel;

  /// No description provided for @missionShareDesc.
  ///
  /// In en, this message translates to:
  /// **'Share the app to social media'**
  String get missionShareDesc;

  /// No description provided for @newPack.
  ///
  /// In en, this message translates to:
  /// **'New Pack'**
  String get newPack;

  /// No description provided for @noPacksYet.
  ///
  /// In en, this message translates to:
  /// **'No packs yet'**
  String get noPacksYet;

  /// No description provided for @packOrgGuidance.
  ///
  /// In en, this message translates to:
  /// **'Create packs to organize your stickers, then export them to WhatsApp.'**
  String get packOrgGuidance;

  /// No description provided for @failedCreatePack.
  ///
  /// In en, this message translates to:
  /// **'Failed to create pack'**
  String get failedCreatePack;

  /// No description provided for @newStickerPack.
  ///
  /// In en, this message translates to:
  /// **'New Sticker Pack'**
  String get newStickerPack;

  /// No description provided for @packName.
  ///
  /// In en, this message translates to:
  /// **'Pack name'**
  String get packName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get enterName;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be 128 characters or less'**
  String get nameTooLong;

  /// No description provided for @whatsAppPackGuidance.
  ///
  /// In en, this message translates to:
  /// **'Packs sync to WhatsApp with a name, tray icon, and emoji keywords.'**
  String get whatsAppPackGuidance;

  /// No description provided for @packNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Cute Cats'**
  String get packNameHint;

  /// No description provided for @packCreateGuidance.
  ///
  /// In en, this message translates to:
  /// **'You can add stickers to this pack after creating it. You need at least 3 stickers to import the pack to WhatsApp.'**
  String get packCreateGuidance;

  /// No description provided for @createPack.
  ///
  /// In en, this message translates to:
  /// **'Create Pack'**
  String get createPack;

  /// No description provided for @pack.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get pack;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @errorLoadingPack.
  ///
  /// In en, this message translates to:
  /// **'Error loading pack'**
  String get errorLoadingPack;

  /// No description provided for @packNotFound.
  ///
  /// In en, this message translates to:
  /// **'Pack not found'**
  String get packNotFound;

  /// No description provided for @exportToWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Export to WhatsApp'**
  String get exportToWhatsApp;

  /// No description provided for @addMoreStickers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 more sticker} other{Add {count} more stickers}}'**
  String addMoreStickers(num count);

  /// No description provided for @openingWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Opening WhatsApp...'**
  String get openingWhatsApp;

  /// No description provided for @whatsAppNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is not installed on this device.'**
  String get whatsAppNotInstalled;

  /// No description provided for @renamePack.
  ///
  /// In en, this message translates to:
  /// **'Rename Pack'**
  String get renamePack;

  /// No description provided for @deletePackQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Pack?'**
  String get deletePackQuestion;

  /// No description provided for @removeStickerQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove Sticker?'**
  String get removeStickerQuestion;

  /// No description provided for @packLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This pack is locked. Upgrade to Plus to unlock it.'**
  String get packLockedMessage;

  /// No description provided for @upgradeToPlus.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Plus'**
  String get upgradeToPlus;

  /// No description provided for @packReadyCallout.
  ///
  /// In en, this message translates to:
  /// **'Your pack is ready to export to WhatsApp!'**
  String get packReadyCallout;

  /// No description provided for @packNoStickersYet.
  ///
  /// In en, this message translates to:
  /// **'No stickers yet'**
  String get packNoStickersYet;

  /// No description provided for @searchEmojis.
  ///
  /// In en, this message translates to:
  /// **'Search emojis...'**
  String get searchEmojis;

  /// No description provided for @createNewPack.
  ///
  /// In en, this message translates to:
  /// **'Create new pack'**
  String get createNewPack;

  /// No description provided for @selectEmoji.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one emoji'**
  String get selectEmoji;

  /// No description provided for @packSlots.
  ///
  /// In en, this message translates to:
  /// **'Pack slots'**
  String get packSlots;

  /// No description provided for @packSlotsUsed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 of {total} used} other{{count} of {total} used}}'**
  String packSlotsUsed(num count, Object total);

  /// No description provided for @packLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached your pack limit. Delete a pack to create a new one.'**
  String get packLimitReached;

  /// No description provided for @thanksForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the feedback'**
  String get thanksForFeedback;

  /// No description provided for @surpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get surpriseMe;

  /// No description provided for @trySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try: \"{suggestion}\"'**
  String trySuggestion(Object suggestion);

  /// No description provided for @surpriseConfirmTitleFree.
  ///
  /// In en, this message translates to:
  /// **'Free surprise idea'**
  String get surpriseConfirmTitleFree;

  /// No description provided for @surpriseConfirmTitlePaid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 credit?'**
  String get surpriseConfirmTitlePaid;

  /// No description provided for @surpriseConfirmBodyFree.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 free surprise left today.} other{{count} free surprises left today.}}'**
  String surpriseConfirmBodyFree(num count);

  /// No description provided for @surpriseConfirmBodyPaid.
  ///
  /// In en, this message translates to:
  /// **'An AI will craft a fresh sticker idea for you. Balance after: {balance} credits.'**
  String surpriseConfirmBodyPaid(Object balance);

  /// No description provided for @surpriseCostLine.
  ///
  /// In en, this message translates to:
  /// **'Cost: 1 credit'**
  String get surpriseCostLine;

  /// No description provided for @surpriseLoading.
  ///
  /// In en, this message translates to:
  /// **'Crafting an idea...'**
  String get surpriseLoading;

  /// No description provided for @surpriseFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t craft an idea right now.'**
  String get surpriseFailed;

  /// No description provided for @surpriseLocalFallback.
  ///
  /// In en, this message translates to:
  /// **'Using a local suggestion instead.'**
  String get surpriseLocalFallback;

  /// No description provided for @surpriseWaitSeconds.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before trying again.'**
  String surpriseWaitSeconds(Object seconds);

  /// No description provided for @surpriseTopUpViaMissions.
  ///
  /// In en, this message translates to:
  /// **'Earn credits on the Missions page.'**
  String get surpriseTopUpViaMissions;

  /// No description provided for @goodResult.
  ///
  /// In en, this message translates to:
  /// **'Good result'**
  String get goodResult;

  /// No description provided for @poorResult.
  ///
  /// In en, this message translates to:
  /// **'Poor result'**
  String get poorResult;

  /// No description provided for @rateThisResult.
  ///
  /// In en, this message translates to:
  /// **'Rate this result'**
  String get rateThisResult;

  /// No description provided for @choosePackEmojis.
  ///
  /// In en, this message translates to:
  /// **'Choose a pack and select 1-3 emojis for WhatsApp.'**
  String get choosePackEmojis;

  /// No description provided for @emojiCount.
  ///
  /// In en, this message translates to:
  /// **'Emojis ({count}/3)'**
  String emojiCount(Object count);

  /// No description provided for @noRecentEmojis.
  ///
  /// In en, this message translates to:
  /// **'No recent emojis yet'**
  String get noRecentEmojis;

  /// No description provided for @noEmojisMatch.
  ///
  /// In en, this message translates to:
  /// **'No emojis match \"{query}\"'**
  String noEmojisMatch(Object query);

  /// No description provided for @packLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pack limit reached'**
  String get packLimitReachedTitle;

  /// No description provided for @noPacksYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No packs yet'**
  String get noPacksYetTitle;

  /// No description provided for @packLimitReachedDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete a pack to create a new one.'**
  String get packLimitReachedDesc;

  /// No description provided for @noPacksYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first pack to organize stickers.'**
  String get noPacksYetDesc;

  /// No description provided for @createNewPackButton.
  ///
  /// In en, this message translates to:
  /// **'Create new pack'**
  String get createNewPackButton;

  /// No description provided for @createPackButton.
  ///
  /// In en, this message translates to:
  /// **'Create Pack'**
  String get createPackButton;

  /// No description provided for @selectEmojiError.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one emoji'**
  String get selectEmojiError;

  /// No description provided for @packReadyExport.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is ready to export to WhatsApp.'**
  String packReadyExport(Object name);

  /// No description provided for @addedToPack.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{name}\". Add {count} more sticker{count} to export.'**
  String addedToPack(Object count, Object name);

  /// No description provided for @presetKawaiiLabel.
  ///
  /// In en, this message translates to:
  /// **'Kawaii'**
  String get presetKawaiiLabel;

  /// No description provided for @presetKawaiiDesc.
  ///
  /// In en, this message translates to:
  /// **'Cute pastel chibi'**
  String get presetKawaiiDesc;

  /// No description provided for @presetPixelArtLabel.
  ///
  /// In en, this message translates to:
  /// **'Pixel Art'**
  String get presetPixelArtLabel;

  /// No description provided for @presetPixelArtDesc.
  ///
  /// In en, this message translates to:
  /// **'16-bit retro pixels'**
  String get presetPixelArtDesc;

  /// No description provided for @presetVectorFlatLabel.
  ///
  /// In en, this message translates to:
  /// **'Vector Flat'**
  String get presetVectorFlatLabel;

  /// No description provided for @presetVectorFlatDesc.
  ///
  /// In en, this message translates to:
  /// **'Bold flat illustration'**
  String get presetVectorFlatDesc;

  /// No description provided for @presetChibi3dLabel.
  ///
  /// In en, this message translates to:
  /// **'3D Chibi'**
  String get presetChibi3dLabel;

  /// No description provided for @presetChibi3dDesc.
  ///
  /// In en, this message translates to:
  /// **'Glossy 3d render'**
  String get presetChibi3dDesc;

  /// No description provided for @presetRetroStickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Retro'**
  String get presetRetroStickerLabel;

  /// No description provided for @presetRetroStickerDesc.
  ///
  /// In en, this message translates to:
  /// **'90s halftone vibe'**
  String get presetRetroStickerDesc;

  /// No description provided for @consentErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm consent'**
  String get consentErrorTitle;

  /// No description provided for @consentErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm your legal documents right now. Check your connection and try again.'**
  String get consentErrorBody;

  /// No description provided for @consentDocsChanged.
  ///
  /// In en, this message translates to:
  /// **'Legal documents have been updated. Please update the app to continue.'**
  String get consentDocsChanged;

  /// No description provided for @withdrawPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Revoke Privacy Consent'**
  String get withdrawPrivacy;

  /// No description provided for @withdrawPrivacySub.
  ///
  /// In en, this message translates to:
  /// **'Stop consent-based processing (Terms stay valid).'**
  String get withdrawPrivacySub;

  /// No description provided for @withdrawPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'This stops processing that relies on your consent.'**
  String get withdrawPrivacyBody;

  /// No description provided for @withdrawPrivacyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get withdrawPrivacyConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
