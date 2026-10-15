import 'package:flutter/material.dart' show TimeOfDay;

/// Durata di un turno.
///
/// Con `overnight` la fine cade il giorno dopo: 22:00–06:00 dura 8h,
/// 00:00–00:00 dura 24h, 06:00–07:00 dura 25h. Senza `overnight` la durata e'
/// semplicemente fine − inizio (un orario di fine precedente all'inizio viene
/// letto come fine il giorno dopo).
Duration shiftDurationFor({
  required TimeOfDay start,
  required TimeOfDay end,
  required bool overnight,
}) {
  var minutes = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
  if (overnight || minutes < 0) {
    minutes += 24 * 60;
  }
  return Duration(minutes: minutes);
}

/// Giorni di calendario toccati dal turno: 00:00–00:00 (24h) ne occupa uno
/// solo perche' finisce a mezzanotte; 06:00–07:00 del giorno dopo (25h) due.
int shiftDaysSpanned({
  required TimeOfDay start,
  required TimeOfDay end,
  required bool overnight,
}) {
  final duration = shiftDurationFor(
    start: start,
    end: end,
    overnight: overnight,
  );
  final endMinutes = start.hour * 60 + start.minute + duration.inMinutes;
  final days = (endMinutes / (24 * 60)).ceil();
  return days < 1 ? 1 : days;
}
