import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class SondageWeb extends StatelessWidget {
  const SondageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<NavigationBloc>().add(NavigationPositionChanged(6));

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Sondaggio web"),
    );
  }
}
