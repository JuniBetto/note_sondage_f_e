import 'package:hive_flutter/hive_flutter.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data/hive_models/clocking_hive_model.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data/hive_models/sondage_hive_model.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/permission_hive_model.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/role_hive_model.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/team_hive_model.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/team_member_hive_model.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/user_hive_model.dart';
import 'package:note_sondage/infrastructure/model/app_config_model.dart';
import 'package:note_sondage/infrastructure/model/theme_entitie.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    try {
      //  final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter();

      // Register adapters
      Hive.registerAdapter(ThemeEntitieAdapter());
      Hive.registerAdapter(AppConfigModelAdapter());
      Hive.registerAdapter(PermissionHiveModelAdapter());
      Hive.registerAdapter(RoleHiveModelAdapter());
      Hive.registerAdapter(TeamHiveModelAdapter());
      Hive.registerAdapter(TeamMemberHiveModelAdapter());
      Hive.registerAdapter(UserHiveModelAdapter());
      Hive.registerAdapter(SondageHiveModelAdapter());
      Hive.registerAdapter(ClockingHiveModelAdapter());

      // Open boxes with unique names
      // await Future.wait([Hive.openBox<AppConfigModel>(appConfigBox)]);
      await Future.wait([
        Hive.openBox<bool>(themeConfigBox),
        Hive.openBox<String>(languageConfigBox),
        Hive.openBox<PermissionHiveModel>('permissions_box'),
        Hive.openBox<RoleHiveModel>('roles_box'),
        Hive.openBox<TeamHiveModel>('teams_box'),
        Hive.openBox<TeamMemberHiveModel>('team_members_box'),
        Hive.openBox<UserHiveModel>('users_box'),
        Hive.openBox<SondageHiveModel>('sondages_box'),
        Hive.openBox<ClockingHiveModel>('clocking_box'),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> closeBoxes() async {
    // await Future.wait([Hive.box<AppConfigModel>(appConfigBox).close()]);
    await Future.wait([
      Hive.box<bool>(themeConfigBox).close(),
      Hive.box<String>(languageConfigBox).close(),
      Hive.box<PermissionHiveModel>('permissions_box').close(),
      Hive.box<RoleHiveModel>('roles_box').close(),
      Hive.box<TeamHiveModel>('teams_box').close(),
      Hive.box<TeamMemberHiveModel>('team_members_box').close(),
      Hive.box<UserHiveModel>('users_box').close(),
      Hive.box<SondageHiveModel>('sondages_box').close(),
      Hive.box<ClockingHiveModel>('clocking_box').close(),
    ]);
  }
}
