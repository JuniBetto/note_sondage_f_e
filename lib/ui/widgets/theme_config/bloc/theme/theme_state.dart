import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  //final ThemeEntitie themeEntitie;
  final ThemeData themeData;

  const ThemeState(this.themeData);

  @override
  List<Object?> get props => [themeData];
}

class ThemeInitial extends ThemeState {
  const ThemeInitial(super.themeData);
}

class ThemeisLight extends ThemeState {
  const ThemeisLight(super.themeData);
}

class ThemeisDark extends ThemeState {
  const ThemeisDark(super.themeData);
}

class ThemeisSystem extends ThemeState {
  const ThemeisSystem(super.themeData);
}
