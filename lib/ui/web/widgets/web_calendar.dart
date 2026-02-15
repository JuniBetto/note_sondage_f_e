import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class WebCalendar extends StatelessWidget {
  const WebCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: DateTime.now(),
    );
  }
}
