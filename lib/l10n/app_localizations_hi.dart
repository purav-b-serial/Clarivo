// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Clarivo';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get redownload => 'पुनः डाउनलोड करें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get login => 'लॉग इन करें';

  @override
  String get register => 'पंजीकरण करें';

  @override
  String get logout => 'लॉग आउट करें';

  @override
  String get email => 'ईमेल';

  @override
  String get phone => 'फोन';

  @override
  String get password => 'पासवर्ड';

  @override
  String get identifier => 'ईमेल या फोन नंबर';

  @override
  String get invalidCredentials => 'गलत ईमेल/फोन या पासवर्ड।';

  @override
  String get identifierAlreadyExists =>
      'इस ईमेल/फोन से एक खाता पहले से मौजूद है।';

  @override
  String get storageUnavailable =>
      'आपका खाता सहेजने में असमर्थ। कृपया डिवाइस संग्रहण जांचें।';

  @override
  String get tutorTitle => 'AI ट्यूटर';

  @override
  String get askQuestion => 'एक प्रश्न पूछें…';

  @override
  String get aiThinking => 'AI सोच रही है…';

  @override
  String get stopGenerating => 'उत्पन्न करना बंद करें';

  @override
  String get clearConversation => 'बातचीत साफ़ करें';

  @override
  String get noAnswerMessage =>
      'मुझे खेद है, यह विषय आपकी वर्तमान अध्ययन सामग्री में शामिल नहीं है। कृपया जांचें कि क्या आपने प्रासंगिक सामग्री अपलोड की है, या सामग्री पुस्तकालय देखें।';

  @override
  String get modelNotReady => 'AI मॉडल लोड हो रहा है। कृपया प्रतीक्षा करें…';

  @override
  String get contentTitle => 'सामग्री';

  @override
  String get uploadedDocuments => 'अपलोड किए गए दस्तावेज़';

  @override
  String get uploadDocument => 'दस्तावेज़ अपलोड करें';

  @override
  String get unsupportedFormat =>
      'यह फ़ाइल प्रकार समर्थित नहीं है। कृपया PDF या टेक्स्ट फ़ाइल अपलोड करें।';

  @override
  String get corruptedFile => 'यह फ़ाइल पढ़ी नहीं जा सकी। यह दूषित हो सकती है।';

  @override
  String get ingestionTimeout =>
      'इंडेक्सिंग में बहुत अधिक समय लगा। एक छोटी फ़ाइल आज़माएं या ऐप पुनः आरंभ करें।';

  @override
  String get progressTitle => 'प्रगति';

  @override
  String get totalStudyTime => 'कुल अध्ययन समय';

  @override
  String get questionsAsked => 'पूछे गए प्रश्न';

  @override
  String get topicsCovered => 'कवर किए गए विषय';

  @override
  String get weekly => 'इस सप्ताह';

  @override
  String get overall => 'कुल';

  @override
  String get storageTitle => 'संग्रहण';

  @override
  String get deletePackageWarning =>
      'यह सामग्री पैकेज आपके डिवाइस से हटा दिया जाएगा। जब तक आप इसे पुनः डाउनलोड नहीं करते, आप इस सामग्री को ब्राउज़ नहीं कर पाएंगे।';

  @override
  String get noInternet =>
      'सामग्री डाउनलोड करने के लिए इंटरनेट कनेक्शन आवश्यक है।';

  @override
  String get downloadInterrupted =>
      'डाउनलोड पूरा नहीं हुआ। कृपया पुनः प्रयास करें।';

  @override
  String get downloadCorrupted =>
      'डाउनलोड दूषित हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get insufficientStorage =>
      'पर्याप्त संग्रहण स्थान नहीं है। जगह खाली करें और पुनः प्रयास करें।';

  @override
  String get ocrFailed =>
      'इस छवि से टेक्स्ट नहीं पढ़ा जा सका। कृपया स्पष्ट फ़ोटो लें या प्रश्न टाइप करें।';

  @override
  String get studyReminderTitle => 'पढ़ाई का समय!';

  @override
  String get studyReminderBody =>
      'आपकी दैनिक अध्ययन अनुस्मारक यहां है। ऐप खोलें और अपनी streak जारी रखें!';

  @override
  String get dailyTipTitle => 'आज की अध्ययन टिप';

  @override
  String get supervisorTitle => 'पर्यवेक्षक डैशबोर्ड';

  @override
  String get supervisorPin => 'पर्यवेक्षक PIN';

  @override
  String get supervisorAuthFailed => 'गलत PIN। कृपया पुनः प्रयास करें।';
}
