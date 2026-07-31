import 'package:note_sondage/feature/team/domain/entities/planning_worker_type_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/invite_team_member_request_mapper.dart';

class TeamMapper {
  static const String _defaultReminderTime = '09:00';
  static const String _defaultMissingAlertTime = '10:00';
  static const String _defaultOpenAlertTime = '18:00';

  static TeamEntity fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (_) {
        createdAt = null;
      }
    }

    // Spring returns "ownerId", Python returned "createdByUserId" — handle both
    final createdByUserId =
        (json['ownerId'] ?? json['createdByUserId'])?.toString() ?? '';

    final rawColor = json['color']?.toString();
    final color = (rawColor != null && rawColor.isNotEmpty) ? rawColor : null;
    final clockingRequired = json['clockingRequired'] == true;
    final explicitMemberCount = (json['memberCount'] as num?)?.toInt();
    final members = json['members'];
    final derivedMemberCount = members is List ? members.length : 0;
    final planningWorkerTypes =
        (json['planningWorkerTypes'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => planningWorkerTypeFromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

    return TeamEntity(
      json['id']?.toString(),
      color,
      null, // pendingInvitations is not returned by the API
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdByUserId: createdByUserId,
      clockingRequired: clockingRequired,
      clockingRequiredStartDate: _normalizeDateString(
        json['clockingRequiredStartDate'],
      ),
      clockingRequiredEndDate: _normalizeDateString(
        json['clockingRequiredEndDate'],
      ),
      clockingReminderTime: _normalizeTimeString(
        json['clockingReminderTime'],
        fallback: _defaultReminderTime,
      ),
      clockingMissingAlertTime: _normalizeTimeString(
        json['clockingMissingAlertTime'],
        fallback: _defaultMissingAlertTime,
      ),
      clockingOpenAlertTime: _normalizeTimeString(
        json['clockingOpenAlertTime'],
        fallback: _defaultOpenAlertTime,
      ),
      memberCount: explicitMemberCount ?? derivedMemberCount,
      planningWorkerTypes: planningWorkerTypes.isEmpty
          ? PlanningWorkerTypeEntity.builtIns
          : planningWorkerTypes,
      createdAt: createdAt,
    );
  }

  static PlanningWorkerTypeEntity planningWorkerTypeFromJson(
    Map<String, dynamic> json,
  ) {
    return PlanningWorkerTypeEntity(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      defaultMaxHoursPerDay: (json['defaultMaxHoursPerDay'] as num?)?.toInt(),
      isCustom: json['custom'] == true,
    );
  }

  static Map<String, dynamic> planningWorkerTypeToJson(
    PlanningWorkerTypeEntity entity,
  ) {
    return {
      'code': entity.code,
      'label': entity.label,
      'defaultMaxHoursPerDay': entity.defaultMaxHoursPerDay,
      'custom': entity.isCustom,
    };
  }

  /// Serializes a [TeamEntity] for the POST /api/aggregate/teams endpoint.
  static Map<String, dynamic> toJson(TeamEntity entity) {
    final name = entity.name;
    final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final normalizedStartDate = _normalizeDateString(
      entity.clockingRequiredStartDate,
    );
    final normalizedEndDate = _normalizeDateString(
      entity.clockingRequiredEndDate,
    );
    return {
      'name': name,
      'slug': slug,
      'description': entity.description,
      if (entity.color != null && entity.color!.isNotEmpty)
        'color': entity.color,
      'clockingRequired': entity.clockingRequired,
      if (normalizedStartDate != null)
        'clockingRequiredStartDate': normalizedStartDate,
      if (normalizedEndDate != null)
        'clockingRequiredEndDate': normalizedEndDate,
      'clockingReminderTime': _timeForApi(
        entity.clockingReminderTime,
        fallback: _defaultReminderTime,
      ),
      'clockingMissingAlertTime': _timeForApi(
        entity.clockingMissingAlertTime,
        fallback: _defaultMissingAlertTime,
      ),
      'clockingOpenAlertTime': _timeForApi(
        entity.clockingOpenAlertTime,
        fallback: _defaultOpenAlertTime,
      ),
      'organisationId': null,
      if (entity.pendingInvitations != null &&
          entity.pendingInvitations!.isNotEmpty)
        'members': entity.pendingInvitations!
            .map(InviteTeamMemberRequestMapper.toJson)
            .toList(),
    };
  }

  static Map<String, dynamic> toJsonForUpdate(TeamUpdate entity) {
    final normalizedStartDate = _normalizeDateString(
      entity.clockingRequiredStartDate,
    );
    final normalizedEndDate = _normalizeDateString(
      entity.clockingRequiredEndDate,
    );
    return {
      'name': entity.name,
      'description': entity.description,
      if (entity.color != null && entity.color!.isNotEmpty)
        'color': entity.color,
      'clockingRequired': entity.clockingRequired,
      if (normalizedStartDate != null)
        'clockingRequiredStartDate': normalizedStartDate,
      if (normalizedEndDate != null)
        'clockingRequiredEndDate': normalizedEndDate,
      if (entity.clearClockingRequiredEndDate)
        'clearClockingRequiredEndDate': true,
      'clockingReminderTime': _timeForApi(
        entity.clockingReminderTime,
        fallback: _defaultReminderTime,
      ),
      'clockingMissingAlertTime': _timeForApi(
        entity.clockingMissingAlertTime,
        fallback: _defaultMissingAlertTime,
      ),
      'clockingOpenAlertTime': _timeForApi(
        entity.clockingOpenAlertTime,
        fallback: _defaultOpenAlertTime,
      ),
    };
  }

  static TeamUpdate fromJsonForUpdate(Map<String, dynamic> json) {
    final planningWorkerTypes =
        (json['planningWorkerTypes'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => planningWorkerTypeFromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();
    return TeamUpdate(
      json['isActive'] != null ? !(json['isActive'] as bool) : false,
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdByUserId:
          (json['ownerId'] ?? json['created_by_user_id'])?.toString() ?? '',
      color: (json['color']?.toString().isNotEmpty ?? false)
          ? json['color']!.toString()
          : null,
      clockingRequired: json['clockingRequired'] == true,
      clockingRequiredStartDate: _normalizeDateString(
        json['clockingRequiredStartDate'],
      ),
      clockingRequiredEndDate: _normalizeDateString(
        json['clockingRequiredEndDate'],
      ),
      clockingReminderTime: _normalizeTimeString(
        json['clockingReminderTime'],
        fallback: _defaultReminderTime,
      ),
      clockingMissingAlertTime: _normalizeTimeString(
        json['clockingMissingAlertTime'],
        fallback: _defaultMissingAlertTime,
      ),
      clockingOpenAlertTime: _normalizeTimeString(
        json['clockingOpenAlertTime'],
        fallback: _defaultOpenAlertTime,
      ),
      clearClockingRequiredEndDate:
          json['clearClockingRequiredEndDate'] == true,
      planningWorkerTypes: planningWorkerTypes.isEmpty
          ? PlanningWorkerTypeEntity.builtIns
          : planningWorkerTypes,
      listMember: [],
    );
  }

  static String _timeForApi(String? value, {required String fallback}) {
    final normalized = _normalizeTimeString(value, fallback: fallback);
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }
    return '$normalized:00';
  }

  static String? _normalizeTimeString(dynamic raw, {String? fallback}) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return fallback;
    }
    if (value.length >= 5) {
      return value.substring(0, 5);
    }
    return value;
  }

  static String? _normalizeDateString(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.length >= 10 ? value.substring(0, 10) : value;
  }
}
