import 'package:note_sondage/domain/entities/all_enum.dart';

class SettingType {
  final SettingCategory title;
  final String subtitle;
  final String category;

  SettingType({
    required this.title,
    required this.subtitle,
    required this.category,
  });
}
