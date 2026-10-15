import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_duration.dart';

TimeOfDay _t(int h, [int m = 0]) => TimeOfDay(hour: h, minute: m);

void main() {
  group('shiftDurationFor', () {
    test('same-day shift is end minus start', () {
      expect(
        shiftDurationFor(start: _t(9), end: _t(18), overnight: false),
        const Duration(hours: 9),
      );
    });

    test('overnight shift that crosses midnight', () {
      expect(
        shiftDurationFor(start: _t(22, 30), end: _t(6), overnight: true),
        const Duration(hours: 7, minutes: 30),
      );
    });

    test('00:00-00:00 overnight lasts 24 hours', () {
      expect(
        shiftDurationFor(start: _t(0), end: _t(0), overnight: true),
        const Duration(hours: 24),
      );
    });

    test('06:00-07:00 ending the next day lasts 25 hours', () {
      expect(
        shiftDurationFor(start: _t(6), end: _t(7), overnight: true),
        const Duration(hours: 25),
      );
    });

    test('end before start without the flag is read as the next day', () {
      expect(
        shiftDurationFor(start: _t(22), end: _t(6), overnight: false),
        const Duration(hours: 8),
      );
    });

    test('equal times without the flag last zero', () {
      expect(
        shiftDurationFor(start: _t(8), end: _t(8), overnight: false),
        Duration.zero,
      );
    });
  });

  group('shiftDaysSpanned', () {
    test('a same-day shift covers one day', () {
      expect(shiftDaysSpanned(start: _t(9), end: _t(18), overnight: false), 1);
    });

    test('00:00-00:00 (24h) covers a single day', () {
      expect(shiftDaysSpanned(start: _t(0), end: _t(0), overnight: true), 1);
    });

    test('a shift ending exactly at midnight covers a single day', () {
      expect(shiftDaysSpanned(start: _t(18), end: _t(0), overnight: true), 1);
    });

    test('06:00-07:00 next day (25h) covers two days', () {
      expect(shiftDaysSpanned(start: _t(6), end: _t(7), overnight: true), 2);
    });

    test('a night shift covers two days', () {
      expect(shiftDaysSpanned(start: _t(22), end: _t(6), overnight: true), 2);
    });
  });
}
