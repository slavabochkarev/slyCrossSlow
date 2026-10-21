import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InterfaceLanguage {
  ru('ru', 'Русский'),
  en('en', 'English');

  const InterfaceLanguage(this.code, this.label);
  final String code;
  final String label;
  Locale get locale => Locale(code);

  static InterfaceLanguage fromCode(String? code) =>
      code == 'en' ? InterfaceLanguage.en : InterfaceLanguage.ru;
}

/// Global UI preference; never reads or writes crossword profiles or the wallet.
class InterfaceLanguageController extends ChangeNotifier {
  InterfaceLanguageController({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const preferenceKey = 'interface_language';
  final SharedPreferencesAsync _preferences;
  InterfaceLanguage _language = InterfaceLanguage.ru;
  InterfaceLanguage get language => _language;
  Future<void> _pendingSave = Future.value();

  Future<void> load() async {
    String? code;
    try {
      code = await _preferences.getString(preferenceKey);
    } on TypeError {
      // A malformed preference must not prevent existing profiles from loading.
    }
    _language = InterfaceLanguage.fromCode(code);
    notifyListeners();
  }

  Future<void> select(InterfaceLanguage language) {
    _language = language;
    notifyListeners();
    return _pendingSave = _pendingSave.then(
      (_) => _preferences.setString(preferenceKey, language.code),
    );
  }
}

class InterfaceLanguageScope
    extends InheritedNotifier<InterfaceLanguageController> {
  const InterfaceLanguageScope({
    super.key,
    required InterfaceLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static InterfaceLanguageController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InterfaceLanguageScope>()
      ?.notifier;
}
