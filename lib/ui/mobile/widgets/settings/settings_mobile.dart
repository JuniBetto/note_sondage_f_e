import 'package:flutter/material.dart';

class SettingsMobile extends StatelessWidget {
  const SettingsMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: Text("Settings Mobile")),
      ),
    );
  }
}
