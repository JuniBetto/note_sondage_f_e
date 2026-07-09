class PlanningWorkerTypeEntity {
  const PlanningWorkerTypeEntity({
    required this.code,
    required this.label,
    this.defaultMaxHoursPerDay,
    this.isCustom = false,
  });

  final String code;
  final String label;
  final int? defaultMaxHoursPerDay;
  final bool isCustom;

  static const List<PlanningWorkerTypeEntity> builtIns = [
    PlanningWorkerTypeEntity(
      code: 'STANDARD_EMPLOYEE',
      label: 'Standard employee',
      defaultMaxHoursPerDay: 8,
    ),
    PlanningWorkerTypeEntity(
      code: 'PART_TIME',
      label: 'Part-time',
      defaultMaxHoursPerDay: 5,
    ),
    PlanningWorkerTypeEntity(
      code: 'FULL_TIME',
      label: 'Full-time',
      defaultMaxHoursPerDay: 8,
    ),
    PlanningWorkerTypeEntity(
      code: 'INTERN',
      label: 'Intern',
      defaultMaxHoursPerDay: 4,
    ),
  ];

  PlanningWorkerTypeEntity copyWith({
    String? code,
    String? label,
    int? defaultMaxHoursPerDay,
    bool? isCustom,
  }) {
    return PlanningWorkerTypeEntity(
      code: code ?? this.code,
      label: label ?? this.label,
      defaultMaxHoursPerDay:
          defaultMaxHoursPerDay ?? this.defaultMaxHoursPerDay,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
