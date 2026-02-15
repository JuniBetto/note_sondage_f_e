import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class ClockingWeb extends StatelessWidget {
  const ClockingWeb({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<NavigationBloc>().add(NavigationPositionChanged(5));

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: Text("Clocking web"),
            ),
          ),
          Expanded(
            flex: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.grey[500]),
              child: Text("Clocking web"),
            ),
          ),
        ],
      ),
    );
  }
}
