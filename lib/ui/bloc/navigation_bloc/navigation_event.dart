import 'package:equatable/equatable.dart';

class NavigationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class NavigationPositionChanged extends NavigationEvent {
  final int newPosition;

  NavigationPositionChanged(this.newPosition);

  @override
  List<Object?> get props => [newPosition];
}
