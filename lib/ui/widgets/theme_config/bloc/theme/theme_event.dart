import 'package:equatable/equatable.dart';

class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  // TODO: implement props
  List<Object?> get props => [];
}

/*class ThemeSetEvent extends ThemeEvent {
  const ThemeSetEvent();
}*/

class ThemeLoadEvent extends ThemeEvent {
  const ThemeLoadEvent();
}

class ThemeSetLightEvent extends ThemeEvent {
  const ThemeSetLightEvent();
}

class ThemeSetDarkEvent extends ThemeEvent {
  const ThemeSetDarkEvent();
}

class ThemeSetSystemEvent extends ThemeEvent {
  const ThemeSetSystemEvent();
}
