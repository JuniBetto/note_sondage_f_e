import 'package:equatable/equatable.dart';

class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object?> get props => [];
}

class LanguageLoadEvent extends LanguageEvent {
  const LanguageLoadEvent();
}

class LanguageChangeEvent extends LanguageEvent {
  final String languageCode;

  const LanguageChangeEvent(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}
