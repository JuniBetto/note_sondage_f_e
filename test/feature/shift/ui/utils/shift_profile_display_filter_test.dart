import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_profile_display_filter.dart';

ShiftProfileEntity _profile({
  required String id,
  required String name,
  required bool isSystem,
}) {
  return ShiftProfileEntity(
    id: id,
    userId: isSystem ? null : 'user-1',
    name: name,
    color: '#000000',
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 17, minute: 0),
    overnight: false,
    isSystem: isSystem,
    alarmOffsets: const [],
  );
}

void main() {
  test('drops the system profile when a same-named custom duplicate exists', () {
    final system = _profile(id: 'sys-1', name: 'Mattina', isSystem: true);
    final custom = _profile(id: 'custom-1', name: 'Mattina', isSystem: false);
    final other = _profile(id: 'sys-2', name: 'Serale', isSystem: true);

    final result = preferCustomOverDuplicateSystemProfiles([
      system,
      custom,
      other,
    ]);

    expect(result, containsAll([custom, other]));
    expect(result, isNot(contains(system)));
    expect(result.length, 2);
  });

  test('name match is case-insensitive and ignores surrounding spaces', () {
    final system = _profile(id: 'sys-1', name: 'Mattina', isSystem: true);
    final custom = _profile(id: 'custom-1', name: '  MATTINA  ', isSystem: false);

    final result = preferCustomOverDuplicateSystemProfiles([system, custom]);

    expect(result, [custom]);
  });

  test('keeps a system profile with no matching custom duplicate', () {
    final system = _profile(id: 'sys-1', name: 'Mattina', isSystem: true);
    final custom = _profile(id: 'custom-1', name: 'Something else', isSystem: false);

    final result = preferCustomOverDuplicateSystemProfiles([system, custom]);

    expect(result, containsAll([system, custom]));
    expect(result.length, 2);
  });

  test('returns the list unchanged when there are no custom profiles', () {
    final system = _profile(id: 'sys-1', name: 'Mattina', isSystem: true);

    final result = preferCustomOverDuplicateSystemProfiles([system]);

    expect(result, [system]);
  });
}
