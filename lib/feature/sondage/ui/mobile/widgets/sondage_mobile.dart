import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/create_sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_display.dart';
import 'package:note_sondage/theme/color_palette.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

/*class SondageMobile extends StatefulWidget {
  const SondageMobile({super.key});

  @override
  State<SondageMobile> createState() => _SondageMobileState();
}

class _SondageMobileState extends State<SondageMobile> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simula il caricamento dei dati
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SondageMobileSkeleton();
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Sondaggio Mobile"),
    );
  }
}*/

class SondageMobile extends StatefulWidget {
  const SondageMobile({super.key});

  @override
  State<SondageMobile> createState() => _SondageMobileState();
}

class _SondageMobileState extends State<SondageMobile>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int currentViewType = 1;
  List<Map<String, dynamic>> sondages =
      sondagesList; // Lista di sondaggi fittizi

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    // Ascolta TUTTI i cambiamenti del tabController (non solo indexIsChanging)
    // per aggiornare i colori della tab bar anche durante lo swipe del TabBarView.
    tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // setState su ogni cambio di indice (incluso swipe completato)
    // per aggiornare correttamente i colori dei testi nella tab bar.
    setState(() {});
  }

  void _handleViewTypeChanged(int viewType) {
    setState(() {
      currentViewType = viewType;
    });
  }

  void _handleSondageCreated() {
    // Logica per aggiornare la lista dei sondaggi
    // Potresti qui fare una chiamata API e poi cambiare tab
    setState(() {
      // Aggiorna la lista dei sondaggi
    });

    // Torna alla tab dei sondaggi selezionati
    tabController.animateTo(0);
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TabBarComponent(
              childTab1: Text(
                'Lista ${localization.sondage}', // Puoi creare una localizzazione "selectedSondage" se vuoi
                style: TextStyle(
                  color: tabController.index == 0
                      ? ColorPalette.primary[6]
                      : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              childTab2: Text(
                'Create ${localization.sondage}', // Puoi creare una localizzazione "createSondage" se vuoi
                style: TextStyle(
                  color: tabController.index == 1
                      ? ColorPalette.primary[6]
                      : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              tabController: tabController,
              setToUpdate: setState,
            ),
            SizedBox(height: 8),
            Divider(height: 2, color: Colors.grey[400]),
            SizedBox(height: 16),

            // Contenuto dinamico basato sulla tab selezionata
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  // Prima tab: Visualizzazione sondaggi
                  SondageDisplay(
                    sondages: sondages, // Lista di sondaggi
                    onViewChanged: _handleViewTypeChanged,
                    initialViewType: currentViewType,
                  ),

                  // Seconda tab: Creazione sondaggio
                  // DragDropList(),
                  CreateSondageMobile(onsondageCreated: _handleSondageCreated),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Lista di 20 sondaggi fittizi per testing
final List<Map<String, dynamic>> sondagesList = [
  {
    'sondageId': 'sondage-001',
    'sondageName': 'Employee Satisfaction Survey 2026',
    'sondageFocus': 'Workplace Happiness',
    'status': 'active',
    'responses': 42,
    'totalQuestions': 10,
    'createdDate': '2026-03-15',
    'expiryDate': '2026-04-15',
    'color': Colors.blue,
  },
  {
    'sondageId': 'sondage-002',
    'sondageName': 'Product Feedback Q1',
    'sondageFocus': 'Customer Experience',
    'status': 'active',
    'responses': 128,
    'totalQuestions': 8,
    'createdDate': '2026-03-10',
    'expiryDate': '2026-03-30',
    'color': Colors.green,
  },
  {
    'sondageId': 'sondage-003',
    'sondageName': 'Team Building Event Planning',
    'sondageFocus': 'Event Preferences',
    'status': 'active',
    'responses': 35,
    'totalQuestions': 6,
    'createdDate': '2026-03-20',
    'expiryDate': '2026-04-01',
    'color': Colors.purple,
  },
  {
    'sondageId': 'sondage-004',
    'sondageName': 'Remote Work Policy Review',
    'sondageFocus': 'Work Arrangements',
    'status': 'completed',
    'responses': 156,
    'totalQuestions': 12,
    'createdDate': '2026-02-01',
    'expiryDate': '2026-02-28',
    'color': Colors.orange,
  },
  {
    'sondageId': 'sondage-005',
    'sondageName': 'New Feature Priority Poll',
    'sondageFocus': 'Product Roadmap',
    'status': 'active',
    'responses': 89,
    'totalQuestions': 5,
    'createdDate': '2026-03-18',
    'expiryDate': '2026-04-10',
    'color': Colors.teal,
  },
  {
    'sondageId': 'sondage-006',
    'sondageName': 'Office Cafeteria Menu Preferences',
    'sondageFocus': 'Food & Beverages',
    'status': 'active',
    'responses': 67,
    'totalQuestions': 7,
    'createdDate': '2026-03-12',
    'expiryDate': '2026-03-26',
    'color': Color(0xFFE91E63),
  },
  {
    'sondageId': 'sondage-007',
    'sondageName': 'Training Needs Assessment',
    'sondageFocus': 'Professional Development',
    'status': 'active',
    'responses': 51,
    'totalQuestions': 9,
    'createdDate': '2026-03-08',
    'expiryDate': '2026-04-08',
    'color': Color(0xFF9C27B0),
  },
  {
    'sondageId': 'sondage-008',
    'sondageName': 'Brand Awareness Study',
    'sondageFocus': 'Marketing Research',
    'status': 'draft',
    'responses': 0,
    'totalQuestions': 15,
    'createdDate': '2026-03-22',
    'expiryDate': '2026-05-01',
    'color': Color(0xFF3F51B5),
  },
  {
    'sondageId': 'sondage-009',
    'sondageName': 'IT Infrastructure Upgrade',
    'sondageFocus': 'Technology Preferences',
    'status': 'active',
    'responses': 73,
    'totalQuestions': 11,
    'createdDate': '2026-03-05',
    'expiryDate': '2026-03-28',
    'color': Color(0xFF00BCD4),
  },
  {
    'sondageId': 'sondage-010',
    'sondageName': 'Quarterly Performance Review',
    'sondageFocus': 'Goal Achievement',
    'status': 'completed',
    'responses': 142,
    'totalQuestions': 13,
    'createdDate': '2026-01-15',
    'expiryDate': '2026-02-15',
    'color': Color(0xFF4CAF50),
  },
  {
    'sondageId': 'sondage-011',
    'sondageName': 'Customer Service Quality Check',
    'sondageFocus': 'Service Excellence',
    'status': 'active',
    'responses': 95,
    'totalQuestions': 8,
    'createdDate': '2026-03-14',
    'expiryDate': '2026-04-05',
    'color': Color(0xFFFF5722),
  },
  {
    'sondageId': 'sondage-012',
    'sondageName': 'Sustainability Initiatives Poll',
    'sondageFocus': 'Environmental Impact',
    'status': 'active',
    'responses': 38,
    'totalQuestions': 6,
    'createdDate': '2026-03-19',
    'expiryDate': '2026-04-20',
    'color': Color(0xFF8BC34A),
  },
  {
    'sondageId': 'sondage-013',
    'sondageName': 'Employee Benefits Survey',
    'sondageFocus': 'Compensation & Benefits',
    'status': 'active',
    'responses': 112,
    'totalQuestions': 14,
    'createdDate': '2026-03-01',
    'expiryDate': '2026-03-31',
    'color': Color(0xFFFF9800),
  },
  {
    'sondageId': 'sondage-014',
    'sondageName': 'Mobile App User Experience',
    'sondageFocus': 'UX/UI Feedback',
    'status': 'active',
    'responses': 201,
    'totalQuestions': 10,
    'createdDate': '2026-03-11',
    'expiryDate': '2026-04-11',
    'color': Color(0xFF2196F3),
  },
  {
    'sondageId': 'sondage-015',
    'sondageName': 'Team Communication Survey',
    'sondageFocus': 'Internal Communication',
    'status': 'completed',
    'responses': 88,
    'totalQuestions': 7,
    'createdDate': '2026-02-10',
    'expiryDate': '2026-03-10',
    'color': Color(0xFF673AB7),
  },
  {
    'sondageId': 'sondage-016',
    'sondageName': 'Holiday Schedule Preferences',
    'sondageFocus': 'Time Off Planning',
    'status': 'draft',
    'responses': 0,
    'totalQuestions': 4,
    'createdDate': '2026-03-23',
    'expiryDate': '2026-04-30',
    'color': Color(0xFFFFC107),
  },
  {
    'sondageId': 'sondage-017',
    'sondageName': 'Workplace Safety Assessment',
    'sondageFocus': 'Health & Safety',
    'status': 'active',
    'responses': 64,
    'totalQuestions': 9,
    'createdDate': '2026-03-07',
    'expiryDate': '2026-04-07',
    'color': Color(0xFFF44336),
  },
  {
    'sondageId': 'sondage-018',
    'sondageName': 'Diversity & Inclusion Survey',
    'sondageFocus': 'Workplace Culture',
    'status': 'active',
    'responses': 127,
    'totalQuestions': 16,
    'createdDate': '2026-03-03',
    'expiryDate': '2026-04-03',
    'color': Color(0xFF9E9E9E),
  },
  {
    'sondageId': 'sondage-019',
    'sondageName': 'Innovation Ideas Collection',
    'sondageFocus': 'Creative Solutions',
    'status': 'active',
    'responses': 45,
    'totalQuestions': 5,
    'createdDate': '2026-03-16',
    'expiryDate': '2026-04-16',
    'color': Color(0xFF00E676),
  },
  {
    'sondageId': 'sondage-020',
    'sondageName': 'Annual Company Conference',
    'sondageFocus': 'Event Logistics',
    'status': 'active',
    'responses': 178,
    'totalQuestions': 12,
    'createdDate': '2026-03-04',
    'expiryDate': '2026-04-25',
    'color': Color(0xFFE040FB),
  },
];
