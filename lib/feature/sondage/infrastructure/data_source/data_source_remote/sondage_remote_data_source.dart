import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_local/sondage_local_data_source.dart';

/// Remote data source per Sondage.
///
/// Attualmente restituisce dati fittizi (mock) perché le API non sono
/// ancora pronte. Quando il backend sarà disponibile, basterà decommentare
/// le chiamate Dio e rimuovere i dati di test.
class SondageRemoteDataSource {
  final SondageLocalDataSource localDataSource;

  SondageRemoteDataSource(this.localDataSource);

  // ────────────────────────────────────────────────────────────
  //  MOCK DATA — Da rimuovere quando le API saranno pronte
  // ────────────────────────────────────────────────────────────

  static final List<SondageEntity> _mockSondages = [
    SondageEntity(
      id: 'sondage-001',
      name: 'Employee Satisfaction Survey 2026',
      focus: 'Workplace Happiness',
      status: SondageStatus.active,
      responses: 42,
      totalQuestions: 10,
      createdDate: DateTime(2026, 3, 15),
      expiryDate: DateTime(2026, 4, 15),
      color: Colors.blue,
      description:
          'Annual employee satisfaction survey to gauge workplace happiness and areas for improvement.',
    ),
    SondageEntity(
      id: 'sondage-002',
      name: 'Product Feedback Q1',
      focus: 'Customer Experience',
      status: SondageStatus.active,
      responses: 128,
      totalQuestions: 8,
      createdDate: DateTime(2026, 3, 10),
      expiryDate: DateTime(2026, 3, 30),
      color: Colors.green,
      description:
          'Quarterly product feedback survey focused on customer experience.',
    ),
    SondageEntity(
      id: 'sondage-003',
      name: 'Team Building Event Planning',
      focus: 'Event Preferences',
      status: SondageStatus.active,
      responses: 35,
      totalQuestions: 6,
      createdDate: DateTime(2026, 3, 20),
      expiryDate: DateTime(2026, 4, 1),
      color: Colors.purple,
      description: 'Help us plan the next team building event!',
    ),
    SondageEntity(
      id: 'sondage-004',
      name: 'Remote Work Policy Review',
      focus: 'Work Arrangements',
      status: SondageStatus.completed,
      responses: 156,
      totalQuestions: 12,
      createdDate: DateTime(2026, 2, 1),
      expiryDate: DateTime(2026, 2, 28),
      color: Colors.orange,
      description:
          'Review of current remote work policy to improve flexibility.',
    ),
    SondageEntity(
      id: 'sondage-005',
      name: 'New Feature Priority Poll',
      focus: 'Product Roadmap',
      status: SondageStatus.active,
      responses: 89,
      totalQuestions: 5,
      createdDate: DateTime(2026, 3, 18),
      expiryDate: DateTime(2026, 4, 10),
      color: Colors.teal,
      description: 'Vote on which features should be prioritized next.',
    ),
    SondageEntity(
      id: 'sondage-006',
      name: 'Office Cafeteria Menu Preferences',
      focus: 'Food & Beverages',
      status: SondageStatus.active,
      responses: 67,
      totalQuestions: 7,
      createdDate: DateTime(2026, 3, 12),
      expiryDate: DateTime(2026, 3, 26),
      color: const Color(0xFFE91E63),
      description:
          'Choose your preferred menu options for the office cafeteria.',
    ),
    SondageEntity(
      id: 'sondage-007',
      name: 'Training Needs Assessment',
      focus: 'Professional Development',
      status: SondageStatus.active,
      responses: 51,
      totalQuestions: 9,
      createdDate: DateTime(2026, 3, 8),
      expiryDate: DateTime(2026, 4, 8),
      color: const Color(0xFF9C27B0),
      description: 'Identify your training needs for the next quarter.',
    ),
    SondageEntity(
      id: 'sondage-008',
      name: 'Brand Awareness Study',
      focus: 'Marketing Research',
      status: SondageStatus.draft,
      responses: 0,
      totalQuestions: 15,
      createdDate: DateTime(2026, 3, 22),
      expiryDate: DateTime(2026, 5, 1),
      color: const Color(0xFF3F51B5),
      description:
          'Study to measure brand awareness among target demographics.',
    ),
    SondageEntity(
      id: 'sondage-009',
      name: 'Customer Onboarding Experience',
      focus: 'Customer Success',
      status: SondageStatus.active,
      responses: 73,
      totalQuestions: 11,
      createdDate: DateTime(2026, 3, 5),
      expiryDate: DateTime(2026, 4, 5),
      color: const Color(0xFF00BCD4),
      description: 'Evaluate the customer onboarding experience.',
    ),
    SondageEntity(
      id: 'sondage-010',
      name: 'IT Infrastructure Feedback',
      focus: 'Technology',
      status: SondageStatus.completed,
      responses: 95,
      totalQuestions: 8,
      createdDate: DateTime(2026, 2, 15),
      expiryDate: DateTime(2026, 3, 15),
      color: const Color(0xFF607D8B),
      description: 'Feedback on current IT infrastructure and tools.',
    ),
    SondageEntity(
      id: 'sondage-011',
      name: 'Annual Benefits Review',
      focus: 'HR & Benefits',
      status: SondageStatus.draft,
      responses: 0,
      totalQuestions: 14,
      createdDate: DateTime(2026, 3, 25),
      expiryDate: DateTime(2026, 5, 15),
      color: const Color(0xFFFF5722),
      description: 'Annual review of employee benefits and compensation.',
    ),
    SondageEntity(
      id: 'sondage-012',
      name: 'Sustainability Initiatives Poll',
      focus: 'Corporate Responsibility',
      status: SondageStatus.active,
      responses: 44,
      totalQuestions: 6,
      createdDate: DateTime(2026, 3, 14),
      expiryDate: DateTime(2026, 4, 14),
      color: const Color(0xFF4CAF50),
      description: 'Vote on sustainability initiatives for the company.',
    ),
  ];

  // ────────────────────────────────────────────────────────────
  //  API METHODS — Attualmente usano dati mock
  // ────────────────────────────────────────────────────────────

  Future<List<SondageEntity>> getAll() async {
    // TODO: Sostituire con chiamata API reale
    // final response = await DioClient().dio.get('/sondages/all');
    // final data = response.data as List;
    // final sondages = data
    //     .where((e) => e != null)
    //     .map((e) => SondageMapper.fromJson(e as Map<String, dynamic>))
    //     .toList();
    // await localDataSource.saveAll(sondages);
    // return sondages;

    await Future.delayed(const Duration(milliseconds: 300));
    await localDataSource.saveAll(_mockSondages);
    return List.from(_mockSondages);
  }

  Future<List<SondageEntity>> getAllByUserId(String userId) async {
    // TODO: Sostituire con chiamata API reale
    // final response = await DioClient().dio.get('/sondages/all_by_user/$userId');
    // ...

    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockSondages);
  }

  Future<SondageEntity?> getById(String id) async {
    // TODO: Sostituire con chiamata API reale
    // final response = await DioClient().dio.get('/sondages/$id');
    // return SondageMapper.fromJson(response.data as Map<String, dynamic>);

    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _mockSondages.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<SondageEntity> create(SondageEntity sondage) async {
    // TODO: Sostituire con chiamata API reale
    // final response = await DioClient().dio.post(
    //   '/sondages/create',
    //   data: SondageMapper.toJson(sondage),
    // );
    // return SondageMapper.fromJson(response.data as Map<String, dynamic>);

    await Future.delayed(const Duration(milliseconds: 300));
    return sondage;
  }

  Future<SondageEntity> update(SondageEntity sondage) async {
    // TODO: Sostituire con chiamata API reale
    // final response = await DioClient().dio.put(
    //   '/sondages/update/${sondage.id}',
    //   data: SondageMapper.toJson(sondage),
    // );
    // return SondageMapper.fromJson(response.data as Map<String, dynamic>);

    await Future.delayed(const Duration(milliseconds: 300));
    return sondage;
  }

  Future<void> delete(String id) async {
    // TODO: Sostituire con chiamata API reale
    // await DioClient().dio.delete('/sondages/delete/$id');

    await Future.delayed(const Duration(milliseconds: 200));
  }
}
