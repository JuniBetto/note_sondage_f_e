import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/toggle_tile.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/select_team_page.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/time_range_picker.dart';

const _kMaxWidth = 1200.0;

class CreateSondageWeb extends StatefulWidget {
  final String? sondageId;
  final Function()? onsondageCreated;

  const CreateSondageWeb({super.key, this.onsondageCreated, this.sondageId});

  @override
  State<CreateSondageWeb> createState() => _CreateSondageWebState();
}

class _CreateSondageWebState extends State<CreateSondageWeb> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController namesondageController = TextEditingController();
  final TextEditingController descriptionsondageController =
      TextEditingController();
  bool isFixedTime = false;
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 9, minute: 0);

  bool isEnabled = false;

  // Team selezionato
  Map<String, dynamic>? selectedTeam;

  // Lista delle opzioni
  late List<TextEditingController> items;

  @override
  void initState() {
    super.initState();
    items = [TextEditingController(text: "")];
  }

  @override
  void dispose() {
    namesondageController.dispose();
    descriptionsondageController.dispose();
    for (var controller in items) {
      controller.dispose();
    }
    items.clear();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;

      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });
  }

  void _addItem() {
    setState(() {
      items.add(TextEditingController(text: ""));
    });
  }

  void _removeItem(int index) {
    setState(() {
      items[index].dispose();
      items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _kMaxWidth),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campo domanda
                      CustomTextFieldImmersive(
                        hintText: localization.askQuestion,
                        maxLines: 3,
                        controller: namesondageController,
                      ),
                      SizedBox(height: 16),

                      // Lista delle opzioni con drag & drop
                      ReorderableListView.builder(
                        itemCount: items.length,
                        onReorder: _onReorder,
                        buildDefaultDragHandles: false,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Padding(
                            key: ValueKey(index),
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: CustomTextFieldImmersive(
                              controller: items[index],
                              hintText: '${localization.option} ${index + 1}',
                              suffixIcon: ReorderableDragStartListener(
                                index: index,
                                child: Icon(Icons.drag_handle),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  int emptyCount = items
                                      .where(
                                        (controller) => controller.text.isEmpty,
                                      )
                                      .length;

                                  if (value.isNotEmpty && emptyCount == 0) {
                                    _addItem();
                                  } else if (emptyCount > 1) {
                                    for (
                                      int i = items.length - 2;
                                      i >= 0;
                                      i--
                                    ) {
                                      if (items[i].text.isEmpty &&
                                          emptyCount > 1) {
                                        _removeItem(i);
                                        emptyCount--;
                                      }
                                    }
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 16),

                      // Toggle per rendere anonimo
                      ToggleTile(
                        title: localization.makeResponsesAnonymous,
                        value: isEnabled,
                        onChanged: (val) => setState(() => isEnabled = val),
                      ),
                      SizedBox(height: 16),

                      // Time Range Picker
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.homeSecondary!,
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Checkbox(
                                  value: isFixedTime,
                                  onChanged: (value) {
                                    setState(() {
                                      isFixedTime = value!;
                                    });
                                  },
                                  activeColor: colorScheme.selectionColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                title: Text("imposta tempo di risposta"),
                              ),
                              IgnorePointer(
                                ignoring:!isFixedTime,
                                child: TimeRangePicker(
                                  start: start,
                                  end: end,
                                  onStartChanged: (val) =>
                                      setState(() => start = val),
                                  onEndChanged: (val) =>
                                      setState(() => end = val),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Bottone per selezionare team
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          CustomAppButton(
                            type: ButtonType.text,
                            backgroundColor: Colors.blueAccent,
                            onPressed: () async {
                              // Naviga alla pagina di selezione team
                              final result =
                                  await Navigator.push<Map<String, dynamic>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectTeamPage(),
                                    ),
                                  );

                              if (result != null) {
                                setState(() {
                                  selectedTeam = result;
                                });
                              }
                            },
                            isActive: true,
                            child: Text(
                              selectedTeam == null
                                  ? localization.selectTeam
                                  : "${localization.teamLabel} ${selectedTeam!['teamName']}",
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Bottone di creazione
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localization.surveyCreatedSuccessfully,
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            if (widget.onsondageCreated != null) {
                              widget.onsondageCreated!();
                            }

                            namesondageController.clear();
                            descriptionsondageController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          '${localization.create} ${localization.sondage}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
