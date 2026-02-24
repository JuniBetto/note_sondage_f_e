import 'package:flutter/material.dart';

class ButtonClocking extends StatefulWidget {
  const ButtonClocking({super.key});

  @override
  State<ButtonClocking> createState() => _ButtonClockingState();
}

class _ButtonClockingState extends State<ButtonClocking> {
  bool isClockedIn = false;
  bool isPaused = false;

  void toggleClocking() {
    setState(() {
      if (isClockedIn) {
        isClockedIn = false;
        isPaused = false; // Resetta lo stato di pausa quando si clocka out
      } else {
        isClockedIn = true;
      }
    });
  }

  void togglePause() {
    setState(() {
      if (isClockedIn) {
        isPaused = !isPaused;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: toggleClocking,
          style: ElevatedButton.styleFrom(
            backgroundColor: isClockedIn ? Colors.green : Colors.red,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                Icon(
                  isClockedIn ? Icons.timer_outlined : Icons.timer_off_outlined,
                  size: 32,
                ),
                Text(isClockedIn ? "Clock in" : "Clock out"),
              ],
            ),
          ),
        ),
        SizedBox(width: 8.0),
        ElevatedButton(
          onPressed: togglePause,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPaused ? Colors.yellow[700] : Colors.grey[400],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                Icon(
                  isPaused ? Icons.coffee : Icons.coffee_maker_rounded,
                  size: 32,
                ),
                Text(isPaused ? "Start break" : "Resume break"),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
