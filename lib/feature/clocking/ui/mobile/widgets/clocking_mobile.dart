import 'package:flutter/material.dart';

class ClockingMobile extends StatelessWidget {
  const ClockingMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
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
