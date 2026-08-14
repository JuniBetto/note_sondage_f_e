class WorkflowContextMetadata {
  static const contextTypeKey = 'contextType';
  static const contextIdKey = 'contextId';
  static const sourceTypeKey = 'sourceType';
  static const sourceIdKey = 'sourceId';
  static const sourceMessageIdKey = 'sourceMessageId';

  const WorkflowContextMetadata({
    required this.metadata,
    this.contextType,
    this.contextId,
    this.sourceType,
    this.sourceId,
    this.sourceMessageId,
  });

  final Map<String, String> metadata;
  final String? contextType;
  final String? contextId;
  final String? sourceType;
  final String? sourceId;
  final String? sourceMessageId;

  factory WorkflowContextMetadata.fromMetadata(Map<String, String> metadata) {
    String? normalize(String key) {
      final value = metadata[key]?.trim();
      if (value == null || value.isEmpty) {
        return null;
      }
      return value;
    }

    return WorkflowContextMetadata(
      metadata: metadata,
      contextType: normalize(contextTypeKey),
      contextId: normalize(contextIdKey),
      sourceType: normalize(sourceTypeKey),
      sourceId: normalize(sourceIdKey),
      sourceMessageId: normalize(sourceMessageIdKey),
    );
  }

  bool get hasContext => contextType != null || contextId != null;

  bool get hasSource =>
      sourceType != null || sourceId != null || sourceMessageId != null;

  String? get normalizedContextType => _normalizeType(contextType);

  String? get normalizedSourceType => _normalizeType(sourceType);

  bool get pointsToChat => _matchesAny(normalizedContextType, const {
    'chat',
    'conversation',
    'chat_conversation',
    'direct_chat',
    'team_chat',
  });

  bool get pointsToSondage =>
      _matchesAny(normalizedContextType, const {'sondage', 'survey'});

  bool get pointsToShift => _matchesAny(normalizedContextType, const {
    'shift',
    'shift_assignment',
    'assignment',
  });

  bool get pointsToClocking => _matchesAny(normalizedContextType, const {
    'clocking',
    'clocking_record',
    'attendance',
  });

  bool get pointsToTeam => _matchesAny(normalizedContextType, const {'team'});

  String? get resolvedTeamId {
    if (pointsToTeam && contextId != null) {
      return contextId;
    }
    return _trimOrNull(metadata['teamId']);
  }

  String? get resolvedSondageId {
    if (pointsToSondage && contextId != null) {
      return contextId;
    }
    return _trimOrNull(metadata['sondageId']);
  }

  String? get resolvedAssignmentId {
    if (pointsToShift && contextId != null) {
      return contextId;
    }
    return _trimOrNull(metadata['assignmentId']) ??
        _trimOrNull(metadata['shiftId']);
  }

  String? get resolvedConversationId {
    if (pointsToChat && contextId != null) {
      return contextId;
    }
    return _trimOrNull(metadata['conversationId']);
  }

  static String? _normalizeType(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.replaceAll('-', '_').replaceAll(' ', '_');
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static bool _matchesAny(String? value, Set<String> allowed) {
    if (value == null) {
      return false;
    }
    return allowed.contains(value);
  }
}
