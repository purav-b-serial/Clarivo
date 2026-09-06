// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Clarivo';

  @override
  String get loading => 'Loading…';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get redownload => 'Re-download';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Log Out';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get password => 'Password';

  @override
  String get identifier => 'Email or phone number';

  @override
  String get invalidCredentials => 'Incorrect email/phone or password.';

  @override
  String get identifierAlreadyExists =>
      'An account with this email/phone already exists.';

  @override
  String get storageUnavailable =>
      'Unable to save your account. Please check device storage.';

  @override
  String get tutorTitle => 'AI Tutor';

  @override
  String get askQuestion => 'Ask a question…';

  @override
  String get aiThinking => 'AI is thinking…';

  @override
  String get stopGenerating => 'Stop generating';

  @override
  String get clearConversation => 'Clear conversation';

  @override
  String get noAnswerMessage =>
      'I\'m sorry, this topic is not covered in your current study material. Please check if you have uploaded the relevant content, or browse the content library.';

  @override
  String get modelNotReady => 'AI model is loading. Please wait…';

  @override
  String get contentTitle => 'Content';

  @override
  String get uploadedDocuments => 'Uploaded Documents';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String get unsupportedFormat =>
      'This file type is not supported. Please upload a PDF or text file.';

  @override
  String get corruptedFile =>
      'This file could not be read. It may be corrupted.';

  @override
  String get ingestionTimeout =>
      'Indexing took too long. Try a smaller file or restart the app.';

  @override
  String get progressTitle => 'Progress';

  @override
  String get totalStudyTime => 'Total Study Time';

  @override
  String get questionsAsked => 'Questions Asked';

  @override
  String get topicsCovered => 'Topics Covered';

  @override
  String get weekly => 'This Week';

  @override
  String get overall => 'Overall';

  @override
  String get storageTitle => 'Storage';

  @override
  String get deletePackageWarning =>
      'This content package will be removed from your device. You will be unable to browse this content or ask the Tutor about it until you re-download it.';

  @override
  String get noInternet =>
      'An internet connection is required to download content.';

  @override
  String get downloadInterrupted =>
      'Download did not complete. Please try again.';

  @override
  String get downloadCorrupted => 'Download was corrupted. Please try again.';

  @override
  String get insufficientStorage =>
      'Not enough storage space. Free up space and try again.';

  @override
  String get ocrFailed =>
      'Could not read text from this image. Please take a clearer photo or type your question.';

  @override
  String get studyReminderTitle => 'Time to Study!';

  @override
  String get studyReminderBody =>
      'Your daily study reminder is here. Open the app and keep up your streak!';

  @override
  String get dailyTipTitle => 'Today\'s Study Tip';

  @override
  String get supervisorTitle => 'Supervisor Dashboard';

  @override
  String get supervisorPin => 'Supervisor PIN';

  @override
  String get supervisorAuthFailed => 'Incorrect PIN. Please try again.';
}
