import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ta'),
    Locale('te'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Clarivo'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @redownload.
  ///
  /// In en, this message translates to:
  /// **'Re-download'**
  String get redownload;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @identifier.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number'**
  String get identifier;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email/phone or password.'**
  String get invalidCredentials;

  /// No description provided for @identifierAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email/phone already exists.'**
  String get identifierAlreadyExists;

  /// No description provided for @storageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your account. Please check device storage.'**
  String get storageUnavailable;

  /// No description provided for @tutorTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get tutorTitle;

  /// No description provided for @askQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question…'**
  String get askQuestion;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI is thinking…'**
  String get aiThinking;

  /// No description provided for @stopGenerating.
  ///
  /// In en, this message translates to:
  /// **'Stop generating'**
  String get stopGenerating;

  /// No description provided for @clearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get clearConversation;

  /// No description provided for @noAnswerMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m sorry, this topic is not covered in your current study material. Please check if you have uploaded the relevant content, or browse the content library.'**
  String get noAnswerMessage;

  /// No description provided for @modelNotReady.
  ///
  /// In en, this message translates to:
  /// **'AI model is loading. Please wait…'**
  String get modelNotReady;

  /// No description provided for @contentTitle.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentTitle;

  /// No description provided for @uploadedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Documents'**
  String get uploadedDocuments;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @unsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported. Please upload a PDF or text file.'**
  String get unsupportedFormat;

  /// No description provided for @corruptedFile.
  ///
  /// In en, this message translates to:
  /// **'This file could not be read. It may be corrupted.'**
  String get corruptedFile;

  /// No description provided for @ingestionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Indexing took too long. Try a smaller file or restart the app.'**
  String get ingestionTimeout;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @totalStudyTime.
  ///
  /// In en, this message translates to:
  /// **'Total Study Time'**
  String get totalStudyTime;

  /// No description provided for @questionsAsked.
  ///
  /// In en, this message translates to:
  /// **'Questions Asked'**
  String get questionsAsked;

  /// No description provided for @topicsCovered.
  ///
  /// In en, this message translates to:
  /// **'Topics Covered'**
  String get topicsCovered;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get weekly;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// No description provided for @deletePackageWarning.
  ///
  /// In en, this message translates to:
  /// **'This content package will be removed from your device. You will be unable to browse this content or ask the Tutor about it until you re-download it.'**
  String get deletePackageWarning;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'An internet connection is required to download content.'**
  String get noInternet;

  /// No description provided for @downloadInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Download did not complete. Please try again.'**
  String get downloadInterrupted;

  /// No description provided for @downloadCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Download was corrupted. Please try again.'**
  String get downloadCorrupted;

  /// No description provided for @insufficientStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space. Free up space and try again.'**
  String get insufficientStorage;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read text from this image. Please take a clearer photo or type your question.'**
  String get ocrFailed;

  /// No description provided for @studyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to Study!'**
  String get studyReminderTitle;

  /// No description provided for @studyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Your daily study reminder is here. Open the app and keep up your streak!'**
  String get studyReminderBody;

  /// No description provided for @dailyTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Study Tip'**
  String get dailyTipTitle;

  /// No description provided for @supervisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Dashboard'**
  String get supervisorTitle;

  /// No description provided for @supervisorPin.
  ///
  /// In en, this message translates to:
  /// **'Supervisor PIN'**
  String get supervisorPin;

  /// No description provided for @supervisorAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get supervisorAuthFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'hi',
    'kn',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
