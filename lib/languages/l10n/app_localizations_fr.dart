// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get login => 'Entre';

  @override
  String get logout => 'Deconnexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get gladYouAreBack => 'Content de vous revoir.!';

  @override
  String get welcomeBack => 'Bon retour.!';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get justSomeInfoToGetStarted => 'Quelques informations pour commencer';

  @override
  String get fullName => 'Nom complet';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get pleaseEnterYourEmail => 'Veuillez saisir votre adresse e-mail';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get donthaveAnAccount => 'Vous n\'avez pas de compte ? Inscrivez-vous';

  @override
  String get signup => 'Inscription';

  @override
  String get home => 'Accueil';

  @override
  String get about => 'À propos';

  @override
  String get team => 'Équipe';

  @override
  String get settings => 'Configuraion';

  @override
  String get attendance => 'Presence';

  @override
  String get clockingInOut => 'Le pointage';

  @override
  String get explorer => 'explorateur';

  @override
  String get sondage => 'Sondage';

  @override
  String get selectedTeam => 'Selection equipe';

  @override
  String get createTeam => 'Cree equipe';

  @override
  String get teamMember => 'effectif del l\'equipe';

  @override
  String member(num membersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      membersCount,
      locale: localeName,
      other: '$membersCount membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get createNewTeam => 'Créer une nouvelle équipe';

  @override
  String get teamName => 'Nom de l\'équipe';

  @override
  String get teamDescription => 'Description de l\'équipe';

  @override
  String get role => 'Role';

  @override
  String get permission => 'Permission';

  @override
  String get status => 'Statut';

  @override
  String get selectedTeamcolor => 'Selectione la couleur de l\'equipe';

  @override
  String get roleManager => 'Gestione des ruoles';

  @override
  String get permissionManager => 'Gestione des permissions';

  @override
  String get grantList => 'Liste des permissions';

  @override
  String get createGrant => 'Cree une permission';

  @override
  String get roleList => 'Liste des ruoles';

  @override
  String get createRole => 'Cree un ruole';

  @override
  String get permissionName => 'Nom de la permission';

  @override
  String get permissionDescription => 'Description de la permission';

  @override
  String get save => 'Enregister';

  @override
  String get editRoleManager => 'Modificier permission';

  @override
  String get roleName => 'Nom du role';

  @override
  String get roleDescription => 'Description du role';

  @override
  String get selectedPermission => 'Selection de la Permission';

  @override
  String get editTeam => 'Modifier equipe';

  @override
  String get language => 'Langue';

  @override
  String get notification => 'Notification';

  @override
  String get contactUs => 'Contactez nous';

  @override
  String get privacy => 'Confidentialité';
}
