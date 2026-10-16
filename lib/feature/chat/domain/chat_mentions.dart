/// Menzioni nelle chat di team ("@nome persona" / "@tutti"), stile Telegram.
///
/// Le menzioni non hanno un markup dedicato: restano testo semplice nel
/// messaggio ("@Anna Rossi guarda qui") e vengono riconosciute confrontando
/// il testo con i nomi dei membri del team. Al momento dell'invio il client
/// calcola gli userId menzionati e li manda al backend, che li usa solo per
/// le notifiche.
library;

/// Parole chiave riconosciute per "@tutti" (tutte le lingue dell'app).
const Set<String> chatMentionAllKeywords = <String>{
  'tutti',
  'all',
  'everyone',
  'tous',
  'todos',
};

class ChatMentionCandidate {
  const ChatMentionCandidate({
    required this.userId,
    required this.displayName,
    this.secondaryLabel,
    this.avatarUrl,
  });

  final String userId;

  /// Testo inserito dopo "@" e usato per riconoscere la menzione.
  final String displayName;

  /// Es. l'email, mostrata sotto il nome nei suggerimenti.
  final String? secondaryLabel;
  final String? avatarUrl;
}

class ChatMentions {
  const ChatMentions({this.userIds = const <String>[], this.all = false});

  static const ChatMentions none = ChatMentions();

  final List<String> userIds;
  final bool all;

  bool get isEmpty => userIds.isEmpty && !all;
}

class ChatMentionSpan {
  const ChatMentionSpan({
    required this.start,
    required this.end,
    this.userId,
    this.isAll = false,
  });

  /// Indice del carattere "@".
  final int start;

  /// Fine esclusiva.
  final int end;
  final String? userId;
  final bool isAll;

  bool mentions(String userId) => isAll || this.userId == userId;
}

/// Token "@..." che l'utente sta scrivendo subito prima del cursore.
class ChatMentionQuery {
  const ChatMentionQuery({required this.start, required this.query});

  /// Indice del carattere "@".
  final int start;

  /// Testo digitato dopo "@" (può essere vuoto).
  final String query;
}

class ChatMentionEdit {
  const ChatMentionEdit({required this.text, required this.cursor});

  final String text;
  final int cursor;
}

bool _isBoundaryBefore(String text, int index) =>
    index == 0 || RegExp(r'\s|[(\[{"«]').hasMatch(text[index - 1]);

bool _isBoundaryAfter(String text, int index) =>
    index >= text.length ||
    !RegExp(r'[\p{L}\p{N}_@]', unicode: true).hasMatch(text[index]);

/// Trova tutte le menzioni valide in [text]. Per i nomi vince la
/// corrispondenza più lunga ("@Anna Rossi" prima di "@Anna").
List<ChatMentionSpan> findChatMentionSpans(
  String text,
  List<ChatMentionCandidate> candidates,
) {
  if (!text.contains('@')) {
    return const <ChatMentionSpan>[];
  }
  final sorted =
      candidates.where((c) => c.displayName.trim().isNotEmpty).toList()..sort(
        (a, b) =>
            b.displayName.trim().length.compareTo(a.displayName.trim().length),
      );
  final lower = text.toLowerCase();
  final spans = <ChatMentionSpan>[];
  var index = 0;
  while (true) {
    final at = text.indexOf('@', index);
    if (at < 0) {
      break;
    }
    index = at + 1;
    if (!_isBoundaryBefore(text, at)) {
      continue;
    }
    final rest = lower.substring(at + 1);
    ChatMentionSpan? match;
    for (final candidate in sorted) {
      final name = candidate.displayName.trim().toLowerCase();
      final end = at + 1 + name.length;
      if (rest.startsWith(name) && _isBoundaryAfter(text, end)) {
        match = ChatMentionSpan(start: at, end: end, userId: candidate.userId);
        break;
      }
    }
    if (match == null) {
      for (final keyword in chatMentionAllKeywords) {
        final end = at + 1 + keyword.length;
        if (rest.startsWith(keyword) && _isBoundaryAfter(text, end)) {
          match = ChatMentionSpan(start: at, end: end, isAll: true);
          break;
        }
      }
    }
    if (match != null) {
      spans.add(match);
      index = match.end;
    }
  }
  return spans;
}

/// Menzioni da inviare al backend per [text].
ChatMentions extractChatMentions(
  String text,
  List<ChatMentionCandidate> candidates,
) {
  final spans = findChatMentionSpans(text, candidates);
  if (spans.isEmpty) {
    return ChatMentions.none;
  }
  final userIds = <String>[];
  var all = false;
  for (final span in spans) {
    if (span.isAll) {
      all = true;
    } else if (span.userId != null && !userIds.contains(span.userId)) {
      userIds.add(span.userId!);
    }
  }
  return ChatMentions(userIds: userIds, all: all);
}

/// Il token "@..." in corso di scrittura prima di [cursor], oppure `null`.
/// Come Telegram, il token si interrompe a capo; sono ammessi al massimo
/// due spazi per poter cercare "nome cognome".
ChatMentionQuery? activeChatMentionQuery(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) {
    return null;
  }
  final before = text.substring(0, cursor);
  final at = before.lastIndexOf('@');
  if (at < 0 || !_isBoundaryBefore(text, at)) {
    return null;
  }
  final query = before.substring(at + 1);
  if (query.contains('\n') ||
      query.length > 40 ||
      ' '.allMatches(query).length > 2 ||
      query.startsWith(' ') ||
      // Spazio finale = menzione completata (o abbandonata): chiude i
      // suggerimenti, che riappaiono se si continua a scrivere il cognome.
      query.endsWith(' ')) {
    return null;
  }
  return ChatMentionQuery(start: at, query: query);
}

/// Suggerimenti per [query]: prima chi inizia con la query, poi chi la
/// contiene (nome o etichetta secondaria).
List<ChatMentionCandidate> filterChatMentionCandidates(
  List<ChatMentionCandidate> candidates,
  String query, {
  int limit = 6,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return candidates.take(limit).toList();
  }
  final prefix = <ChatMentionCandidate>[];
  final contains = <ChatMentionCandidate>[];
  for (final candidate in candidates) {
    final name = candidate.displayName.toLowerCase();
    final secondary = candidate.secondaryLabel?.toLowerCase() ?? '';
    final wordPrefix = name.split(RegExp(r'\s+')).any((w) => w.startsWith(q));
    if (name.startsWith(q) || wordPrefix) {
      prefix.add(candidate);
    } else if (name.contains(q) || secondary.contains(q)) {
      contains.add(candidate);
    }
  }
  return [...prefix, ...contains].take(limit).toList();
}

/// `true` se "@tutti" (o equivalenti) va suggerito per [query].
bool chatMentionAllMatches(String query, String localizedKeyword) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return true;
  }
  return localizedKeyword.toLowerCase().startsWith(q) ||
      chatMentionAllKeywords.any((k) => k.startsWith(q));
}

/// Sostituisce il token [query] in [text] con "@[mention] ".
ChatMentionEdit applyChatMention(
  String text,
  ChatMentionQuery query,
  String mention,
  int cursor,
) {
  final replacement = '@$mention ';
  final end = cursor.clamp(query.start, text.length);
  final hasSpaceAfter = end < text.length && text[end] == ' ';
  final newText = text.replaceRange(
    query.start,
    hasSpaceAfter ? end + 1 : end,
    replacement,
  );
  return ChatMentionEdit(
    text: newText,
    cursor: query.start + replacement.length,
  );
}
