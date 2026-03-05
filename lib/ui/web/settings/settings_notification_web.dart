import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_event.dart';

class SettingsNotificationWeb extends StatelessWidget {
  const SettingsNotificationWeb({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<SettingNavigationBloc>().add(
      SettingNavigationPositionChanged(1),
    );

    return const Center(child: Text('Settings Notification'));
  }
}
