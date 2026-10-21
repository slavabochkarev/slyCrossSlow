enum GameLanguage {
  ru('ru', 'Русский'),
  en('en', 'English');

  const GameLanguage(this.code, this.label);

  final String code;
  final String label;

  static GameLanguage fromCode(String? code) => GameLanguage.values.firstWhere(
    (language) => language.code == code,
    orElse: () => GameLanguage.ru,
  );
}
