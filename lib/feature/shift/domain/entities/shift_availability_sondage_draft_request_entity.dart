class ShiftAvailabilitySondageDraftRequestEntity {
  const ShiftAvailabilitySondageDraftRequestEntity({
    required this.title,
    required this.options,
    this.description,
    this.allowMultipleResponses = false,
    this.expiryDate,
  });

  final String title;
  final String? description;
  final List<String> options;
  final bool allowMultipleResponses;
  final DateTime? expiryDate;
}
