import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/core/utils/extention_color.dart';

/// ScrollBehavior personalizzato per abilitare il drag scroll sul web
class WebDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class ColorOption {
  final Color color;
  bool isSelected;

  ColorOption({required this.color, this.isSelected = false});
}

class ListCheckbox extends StatefulWidget {
  const ListCheckbox({
    super.key,
    required this.selectedColor,
    this.isEditMode = false,
    this.isEnabled = true,
    this.onColorChanged,
  });
  final List<String> selectedColor;
  final bool? isEditMode;
  final bool isEnabled;
  final ValueChanged<String>? onColorChanged;

  @override
  State<ListCheckbox> createState() => _ListCheckboxState();
}

class _ListCheckboxState extends State<ListCheckbox> {
  @override
  void initState() {
    // TODO: implement initState
    for (var option in colorOptions) {
      option.isSelected = false;
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant ListCheckbox oldWidget) {
    // TODO: implement didUpdateWidget

    if (widget.isEditMode == true) {
      for (var option in colorOptions) {
        final String colorString = option.color.toArgbString();
        if (widget.selectedColor.contains(colorString)) {
          option.isSelected = true;
        }
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8.0,
            children: [
              ScrollConfiguration(
                behavior: WebDragScrollBehavior(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: colorOptions.map((e) {
                      final ColorOption colorOption = e;
                      return ColorCheckboxCard(
                        colorOption: colorOption,
                        isEnabled: widget.isEnabled,
                        onChanged: (value) {
                          if (!widget.isEnabled) return;
                          setState(() {
                            for (var option in colorOptions) {
                              option.isSelected = false;
                            }
                            colorOption.isSelected = value!;
                            widget.selectedColor.clear();
                            if (colorOption.isSelected) {
                              final String colorString = colorOption.color
                                  .toArgbString();
                              widget.selectedColor.add(colorString);
                              widget.onColorChanged?.call(colorString);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorCheckboxCard extends StatelessWidget {
  final ColorOption colorOption;
  final bool isEnabled;
  final ValueChanged<bool?> onChanged;

  const ColorCheckboxCard({
    super.key,
    required this.colorOption,
    this.isEnabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: CircleBorder(),
      color: colorOption.color,
      child: InkWell(
        customBorder: CircleBorder(
          side: BorderSide(
            color: colorOption.isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        onTap: () {
          if (!isEnabled) return;
          onChanged(!colorOption.isSelected);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Icon(
            Icons.check,
            size: 32,
            color: colorOption.isSelected ? Colors.white : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

List<ColorOption> colorOptions = [
  ColorOption(color: Color(0xFFA56555)), // Mattone tenue
  ColorOption(color: Color(0xFFCB4B2B)), // Mattone intenso
  ColorOption(color: Color(0xFF8B7148)), // Rame tenue
  ColorOption(color: Color(0xFF9B6C21)), // Rame intenso
  ColorOption(color: Color(0xFF78783E)), // Senape tenue
  ColorOption(color: Color(0xFF7A7A1A)), // Senape intenso
  ColorOption(color: Color(0xFF528143)), // Muschio tenue
  ColorOption(color: Color(0xFF37861C)), // Muschio intenso
  ColorOption(color: Color(0xFF438162)), // Giada tenue
  ColorOption(color: Color(0xFF1D8652)), // Giada intenso
  ColorOption(color: Color(0xFF42806C)), // Smeraldo tenue
  ColorOption(color: Color(0xFF1C8662)), // Smeraldo intenso
  ColorOption(color: Color(0xFF447E84)), // Turchese tenue
  ColorOption(color: Color(0xFF1D818B)), // Turchese intenso
  ColorOption(color: Color(0xFF5B76AB)), // Fiordaliso tenue
  ColorOption(color: Color(0xFF3F71D6)), // Fiordaliso intenso
  ColorOption(color: Color(0xFF7C6AB2)), // Indaco tenue
  ColorOption(color: Color(0xFF7F5FDD)), // Indaco intenso
  ColorOption(color: Color(0xFFA856A8)), // Orchidea tenue
  ColorOption(color: Color(0xFFC62AC6)), // Orchidea intenso
  // Rossi
  ColorOption(color: Color(0xFFA26464)),
  ColorOption(color: Color(0xFFB85858)),
  ColorOption(color: Color(0xFFCA4949)),
  ColorOption(color: Color(0xFFDB3535)),
  ColorOption(color: Color(0xFFE91313)),

// Terracotta e arancioni
  ColorOption(color: Color(0xFF906F56)),
  ColorOption(color: Color(0xFF9E6944)),
  ColorOption(color: Color(0xFFAB6432)),
  ColorOption(color: Color(0xFFB55E20)),
  ColorOption(color: Color(0xFFBD580F)),

// Ocra e oro
  ColorOption(color: Color(0xFF7E754C)),
  ColorOption(color: Color(0xFF827638)),
  ColorOption(color: Color(0xFF857627)),
  ColorOption(color: Color(0xFF877418)),
  ColorOption(color: Color(0xFF8A740B)),

// Verdi oliva
  ColorOption(color: Color(0xFF687D4B)),
  ColorOption(color: Color(0xFF607F36)),
  ColorOption(color: Color(0xFF5B8125)),
  ColorOption(color: Color(0xFF558217)),
  ColorOption(color: Color(0xFF51830B)),

// Verdi
  ColorOption(color: Color(0xFF4D8156)),
  ColorOption(color: Color(0xFF398445)),
  ColorOption(color: Color(0xFF278737)),
  ColorOption(color: Color(0xFF18872B)),
  ColorOption(color: Color(0xFF0B8920)),

// Verdi acqua
  ColorOption(color: Color(0xFF4C7F76)),
  ColorOption(color: Color(0xFF378175)),
  ColorOption(color: Color(0xFF268474)),
  ColorOption(color: Color(0xFF178572)),
  ColorOption(color: Color(0xFF0B8570)),

// Azzurri e petrolio
  ColorOption(color: Color(0xFF577992)),
  ColorOption(color: Color(0xFF457BA1)),
  ColorOption(color: Color(0xFF337BAE)),
  ColorOption(color: Color(0xFF217ABA)),
  ColorOption(color: Color(0xFF1079C5)),

// Blu e pervinca
  ColorOption(color: Color(0xFF6D71A7)),
  ColorOption(color: Color(0xFF676FBE)),
  ColorOption(color: Color(0xFF626BD1)),
  ColorOption(color: Color(0xFF5D69E2)),
  ColorOption(color: Color(0xFF5965F2)),

// Viola
  ColorOption(color: Color(0xFF8B67A4)),
  ColorOption(color: Color(0xFF945FBA)),
  ColorOption(color: Color(0xFF9B54CD)),
  ColorOption(color: Color(0xFFA14ADF)),
  ColorOption(color: Color(0xFFA640EF)),

// Rosa e lampone
  ColorOption(color: Color(0xFFA06186)),
  ColorOption(color: Color(0xFFB5538D)),
  ColorOption(color: Color(0xFFC7408F)),
  ColorOption(color: Color(0xFFD8268E)),
  ColorOption(color: Color(0xFFDE1289)),
];
