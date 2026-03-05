import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_event.dart';

class SettingsLanguageWeb extends StatelessWidget {
  const SettingsLanguageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<SettingNavigationBloc>().add(
      SettingNavigationPositionChanged(0),
    );
    return const Center(child: Text('Settings Language'));
  }
}
