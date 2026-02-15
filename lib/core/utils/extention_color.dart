import 'package:flutter/material.dart';

extension ColorToString on Color {
  /// Converte un Color in una stringa esadecimale (es. #FFAABBCC)
  String toHexString({bool leadingHashSign = true, bool includeAlpha = true}) {
    final hex = value.toRadixString(16).padLeft(8, '0');

    if (includeAlpha) {
      return '${leadingHashSign ? '#' : ''}${hex.toUpperCase()}';
    } else {
      return '${leadingHashSign ? '#' : ''}${hex.substring(2).toUpperCase()}';
    }
  }

  /// Converte un Color in una stringa ARGB (es. 0xFFAABBCC)
  String toArgbString() {
    return '0x${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Converte un Color in una stringa RGB (es. rgb(255, 170, 187))
  String toRgbString() {
    return 'rgb($red, $green, $blue)';
  }

  /// Converte un Color in una stringa RGBA (es. rgba(255, 170, 187, 0.5))
  String toRgbaString() {
    return 'rgba($red, $green, $blue, ${alpha / 255})';
  }
}

extension StringToColor on String {
  /// Converte una stringa in Color
  /// Supporta i formati:
  /// - #RRGGBB
  /// - #AARRGGBB
  /// - 0xAARRGGBB
  /// - rgb(r, g, b)
  /// - rgba(r, g, b, a)
  Color toColor() {
    final trimmedString = trim();

    // Gestione formato #RRGGBB o #AARRGGBB
    if (trimmedString.startsWith('#')) {
      return _hexToColor(trimmedString);
    }

    // Gestione formato 0xAARRGGBB
    if (trimmedString.startsWith('0x')) {
      return _hexToColor(trimmedString);
    }

    // Gestione formato rgb(r, g, b)
    if (trimmedString.startsWith('rgb(')) {
      return _rgbStringToColor(trimmedString);
    }

    // Gestione formato rgba(r, g, b, a)
    if (trimmedString.startsWith('rgba(')) {
      return _rgbaStringToColor(trimmedString);
    }

    // Gestione dei colori con nome (opzionale)
    final namedColor = _getColorFromName(trimmedString.toLowerCase());
    if (namedColor != null) {
      return namedColor;
    }

    throw FormatException('Formato colore non supportato: $trimmedString');
  }

  Color _hexToColor(String hexString) {
    try {
      String hex = hexString.replaceAll('#', '').replaceAll('0x', '');

      // Se è formato corto (es. #RGB)
      if (hex.length == 3) {
        hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
      }

      // Se non ha alpha, aggiungi FF (opaco)
      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      // Verifica che sia un valore esadecimale valido
      final colorValue = int.parse(hex, radix: 16);
      return Color(colorValue);
    } catch (e) {
      throw FormatException('Formato esadecimale non valido: $hexString');
    }
  }

  Color _rgbStringToColor(String rgbString) {
    try {
      final match = RegExp(
        r'rgb\((\d+),\s*(\d+),\s*(\d+)\)',
      ).firstMatch(rgbString);
      if (match == null) {
        throw FormatException('Formato RGB non valido');
      }

      final r = int.parse(match.group(1)!);
      final g = int.parse(match.group(2)!);
      final b = int.parse(match.group(3)!);

      return Color.fromRGBO(r, g, b, 1.0);
    } catch (e) {
      throw FormatException('Formato RGB non valido: $rgbString');
    }
  }

  Color _rgbaStringToColor(String rgbaString) {
    try {
      final match = RegExp(
        r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)',
      ).firstMatch(rgbaString);
      if (match == null) {
        throw FormatException('Formato RGBA non valido');
      }

      final r = int.parse(match.group(1)!);
      final g = int.parse(match.group(2)!);
      final b = int.parse(match.group(3)!);
      final a = double.parse(match.group(4)!);

      return Color.fromRGBO(r, g, b, a);
    } catch (e) {
      throw FormatException('Formato RGBA non valido: $rgbaString');
    }
  }

  Color? _getColorFromName(String name) {
    const colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'brown': Colors.brown,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'black': Colors.black,
      'white': Colors.white,
      'transparent': Colors.transparent,
    };

    return colorMap[name];
  }
}
