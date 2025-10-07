class Language {
  final int id;
  final String flag;
  final String name;
  final String languageCode;
  final String countryCode;
  final String currencySymbol;
  final String currencyCode;
  final String currencyName;
  const Language(
      this.id,
      this.flag,
      this.name,
      this.languageCode,
      this.countryCode,
      this.currencySymbol,
      this.currencyCode,
      this.currencyName);
  static List<Language> languageList = [
    Language(
        1, '🇺🇸', 'English', 'en', 'US', '\$', 'USD', 'United States Dollar'),
    Language(
        2, '🇻🇳', 'Tiếng Việt', 'vi', 'VN', '₫', 'VND', 'Vietnamese Dong'),

  ];
}
