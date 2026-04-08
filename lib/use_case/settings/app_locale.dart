import 'package:equatable/equatable.dart';

class AppLocale extends Equatable {
  const AppLocale(this.languageCode);

  final String languageCode;

  static AppLocale fromLanguageCode(String languageCode) {
    return AppLocale(languageCode);
  }

  @override
  List<Object?> get props => [languageCode];
}
