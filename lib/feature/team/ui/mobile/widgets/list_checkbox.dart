import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/core/utils/extention_color.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

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
  });
  final List<String> selectedColor;
  final bool? isEditMode;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.bgNavbarSurface,
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
                        onChanged: (value) {
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
  final ValueChanged<bool?> onChanged;

  const ColorCheckboxCard({
    Key? key,
    required this.colorOption,
    required this.onChanged,
  }) : super(key: key);

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
  ColorOption(color: Color(0xFFE6194B)), // Rosso intenso
  ColorOption(color: Color(0xFF3CB44B)), // Verde brillante
  ColorOption(color: Color(0xFFFFE119)), // Giallo vivo
  ColorOption(color: Color(0xFF4363D8)), // Blu puro
  ColorOption(color: Color(0xFFFF851B)), // Arancione
  ColorOption(color: Color(0xFF911EB4)), // Viola profondo
  ColorOption(color: Color(0xFF46F0F0)), // Ciano acceso
  ColorOption(color: Color(0xFFF032E6)), // Magenta
  ColorOption(color: Color(0xFFBCF60C)), // Verde lime
  ColorOption(color: Color(0xFFFABEBE)), // Rosa chiaro
  ColorOption(color: Color(0xFF008080)), // Verde acqua
  ColorOption(color: Color(0xFFE6BEFF)), // Lavanda
  ColorOption(color: Color(0xFF9A6324)), // Marrone
  ColorOption(color: Color(0xFFFFFAC8)), // Beige
  ColorOption(color: Color(0xFF800000)), // Bordeaux
  ColorOption(color: Color(0xFFAAFFC3)), // Menta
  ColorOption(color: Color(0xFF808000)), // Oliva
  ColorOption(color: Color(0xFFFFD8B1)), // Pesca
  ColorOption(color: Color(0xFF000075)), // Blu notte
  ColorOption(color: Color(0xFFAFF141)), // Giallo-verde
  ColorOption(color: Color(0xFFDCBEFF)), // Lilla
  ColorOption(color: Color(0xFFBAB0AC)), // Grigio
];
