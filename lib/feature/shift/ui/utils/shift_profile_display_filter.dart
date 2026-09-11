import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';

/// Filtra [profiles] per i picker (auto planner, add shift, gestione
/// profili): se un profilo personalizzato ha lo stesso nome (case-insensitive,
/// spazi ai bordi ignorati) di un profilo di sistema, quest'ultimo viene
/// escluso e resta visibile solo il duplicato personalizzato.
///
/// Serve come rete di sicurezza visiva quando la preferenza "nascondi
/// profilo di sistema" (impostata alla duplicazione) non è ancora arrivata
/// o non è stata registrata: l'utente non deve mai vedere due voci identiche
/// tra cui scegliere.
///
/// Solo un filtro per la visualizzazione: non tocca la lista usata altrove
/// (es. per risolvere per id il profilo di un turno già assegnato).
List<ShiftProfileEntity> preferCustomOverDuplicateSystemProfiles(
  List<ShiftProfileEntity> profiles,
) {
  final customNames = profiles
      .where((profile) => !profile.isSystem)
      .map((profile) => profile.name.trim().toLowerCase())
      .toSet();

  if (customNames.isEmpty) return profiles;

  return profiles
      .where(
        (profile) =>
            !(profile.isSystem &&
                customNames.contains(profile.name.trim().toLowerCase())),
      )
      .toList();
}
