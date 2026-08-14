class SondageCreatePrefill {
  const SondageCreatePrefill({
    required this.question,
    required this.options,
    this.description,
    this.teamId,
    this.allowMultipleResponses = false,
    this.expiryDate,
  });

  final String question;
  final String? description;
  final String? teamId;
  final List<String> options;
  final bool allowMultipleResponses;
  final DateTime? expiryDate;
}
