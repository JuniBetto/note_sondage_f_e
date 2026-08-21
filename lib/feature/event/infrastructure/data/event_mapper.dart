import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_workflow_metadata_entity.dart';

class EventMapper {
  const EventMapper._();

  static EventEntity fromJson(Map<String, dynamic> json) {
    return EventEntity(
      id: json['id']?.toString().trim() ?? '',
      teamId: _trimOrNull(json['teamId']),
      title: json['title']?.toString().trim() ?? '',
      description: _trimOrNull(json['description']),
      startsAt: _parseDateTime(json['startsAt']) ?? DateTime.now(),
      endsAt: _parseDateTime(json['endsAt']),
      allDay: json['allDay'] == true,
      location: _trimOrNull(json['location']),
      participantUserIds: _stringList(json['participantUserIds']),
      participantDisplayNames: _stringList(json['participantDisplayNames']),
      createdByUserId: json['createdByUserId']?.toString().trim() ?? '',
      createdByDisplayName: _trimOrNull(json['createdByDisplayName']),
      workflowMetadata: _workflowMetadataFromJson(json['workflowMetadata']),
      archivedAt: _parseDateTime(json['archivedAt']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> createRequestToJson(
    EventCreateRequestEntity request,
  ) {
    return <String, dynamic>{
      if (_hasText(request.teamId)) 'teamId': request.teamId!.trim(),
      'title': request.title.trim(),
      if (_hasText(request.description))
        'description': request.description!.trim(),
      'startsAt': request.startsAt.toIso8601String(),
      if (request.endsAt != null) 'endsAt': request.endsAt!.toIso8601String(),
      'allDay': request.allDay,
      if (_hasText(request.location)) 'location': request.location!.trim(),
      if (request.participantUserIds.isNotEmpty)
        'participantUserIds': request.participantUserIds,
      if (request.participantDisplayNames.isNotEmpty)
        'participantDisplayNames': request.participantDisplayNames,
      if (_hasText(request.createdByUserId))
        'createdByUserId': request.createdByUserId.trim(),
      if (_hasText(request.createdByDisplayName))
        'createdByDisplayName': request.createdByDisplayName!.trim(),
      if (request.workflowMetadata != null)
        'workflowMetadata': workflowMetadataToJson(request.workflowMetadata!),
    };
  }

  static Map<String, dynamic> updateRequestToJson(
    EventUpdateRequestEntity request,
  ) {
    return <String, dynamic>{
      if (_hasText(request.title)) 'title': request.title!.trim(),
      if (request.description != null) 'description': request.description,
      if (request.startsAt != null)
        'startsAt': request.startsAt!.toIso8601String(),
      if (request.endsAt != null) 'endsAt': request.endsAt!.toIso8601String(),
      'clearEndsAt': request.clearEndsAt,
      if (request.allDay != null) 'allDay': request.allDay,
      if (request.location != null) 'location': request.location,
      if (request.participantUserIds != null)
        'participantUserIds': request.participantUserIds,
      if (request.participantDisplayNames != null)
        'participantDisplayNames': request.participantDisplayNames,
    };
  }

  static Map<String, dynamic> workflowMetadataToJson(
    EventWorkflowMetadataEntity metadata,
  ) {
    return <String, dynamic>{
      if (_hasText(metadata.contextType))
        'contextType': metadata.contextType!.trim(),
      if (_hasText(metadata.contextId)) 'contextId': metadata.contextId!.trim(),
      if (_hasText(metadata.sourceType))
        'sourceType': metadata.sourceType!.trim(),
      if (_hasText(metadata.sourceId)) 'sourceId': metadata.sourceId!.trim(),
      if (_hasText(metadata.sourceMessageId))
        'sourceMessageId': metadata.sourceMessageId!.trim(),
    };
  }

  static EventWorkflowMetadataEntity? _workflowMetadataFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final metadata = EventWorkflowMetadataEntity(
      contextType: _trimOrNull(raw['contextType']),
      contextId: _trimOrNull(raw['contextId']),
      sourceType: _trimOrNull(raw['sourceType']),
      sourceId: _trimOrNull(raw['sourceId']),
      sourceMessageId: _trimOrNull(raw['sourceMessageId']),
    );
    if (!_hasText(metadata.contextType) &&
        !_hasText(metadata.contextId) &&
        !_hasText(metadata.sourceType) &&
        !_hasText(metadata.sourceId) &&
        !_hasText(metadata.sourceMessageId)) {
      return null;
    }
    return metadata;
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _parseDateTime(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  static String? _trimOrNull(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
