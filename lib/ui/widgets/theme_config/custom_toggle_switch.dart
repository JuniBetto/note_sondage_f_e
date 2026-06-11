import 'package:flutter/material.dart';
import 'package:note_sondage/theme/color_palette.dart';

class CustomToggleSwitch extends StatelessWidget {
  final bool value; // Lo stato attuale del toggle (acceso/spento)
  final ValueChanged<bool> onChanged; // Callback quando il valore cambia
  final Color? activeColor; // Colore quando il toggle è attivo
  final Color? inactiveColor; // Colore quando il toggle è inattivo
  final Color? activeTrackColor; // Colore dello sfondo quando attivo
  final Color? inactiveTrackColor; // Colore dello sfondo quando inattivo
  final double thumbRadius; // Raggio del "pollice" (il cerchio mobile)
  final double trackHeight; // Altezza della traccia (il "binario")
  final double trackWidth; // Larghezza della traccia

  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor, //= const Color(0xFFCBB26A), // Colore del cerchio (active)
    this.inactiveColor, //= const Color(0xFFCBB26A), // Colore del cerchio (inactive) - nell'immagine è lo stesso
    this.activeTrackColor, //= Colors.green, // Colore del background (active)
    this.inactiveTrackColor, //= Colors.red, // Colore del background (inactive)
    this.thumbRadius = 15.0, // Raggio del cerchio (per default)
    this.trackHeight = 30.0, // Altezza del binario (per default)
    this.trackWidth = 60.0, // Larghezza del binario (per default)
  });

  @override
  Widget build(BuildContext context) {
    // --- MODIFICA FONDAMENTALE PER LA HITBOX ---
    // 1. GestureDetector crea l'area cliccabile grande
    return GestureDetector(
      onTap: () {
        // Chiamiamo onChanged passando il valore INVERTITO.
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque, // L'intera area è cliccabile
      // 2. AbsorbPointer disattiva i click sullo Switch originale
      child: AbsorbPointer(
        child: Transform.scale(
          // Scaliamo lo switch per controllare dimensioni in base a thumbRadius
          scale: thumbRadius / 15.0, // Scala in base al raggio di default (15)
          child: Switch(
            value: value,
            // onChanged qui non è attivo a causa di AbsorbPointer
            onChanged: onChanged,
            materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap, // Riduce la hitbox interna
            activeThumbColor: activeColor ?? ColorPalette.secondary[4],
            inactiveThumbColor: inactiveColor ?? ColorPalette.gray[3],
            activeTrackColor: activeTrackColor ?? ColorPalette.surface,
            inactiveTrackColor: inactiveTrackColor ?? ColorPalette.primary[4],
          ),
        ),
      ),
    );
    // --- FINE MODIFICA ---
  }
}
