import 'package:equatable/equatable.dart';

class SettingNavigationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingNavigationPositionChanged extends SettingNavigationEvent {
  final int newPosition;

  SettingNavigationPositionChanged(this.newPosition);

  @override
  List<Object?> get props => [newPosition];
}
