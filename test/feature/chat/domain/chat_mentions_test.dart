import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/chat_mentions.dart';

const _anna = ChatMentionCandidate(
  userId: 'u-anna',
  displayName: 'Anna',
  secondaryLabel: 'anna@example.com',
);
const _annaRossi = ChatMentionCandidate(
  userId: 'u-anna-rossi',
  displayName: 'Anna Rossi',
  secondaryLabel: 'rossi@example.com',
);
const _luca = ChatMentionCandidate(
  userId: 'u-luca',
  displayName: 'Luca',
  secondaryLabel: 'luca@example.com',
);
const _members = [_anna, _annaRossi, _luca];

void main() {
  group('findChatMentionSpans / extractChatMentions', () {
    test('finds a single name mention', () {
      final mentions = extractChatMentions('ciao @Luca come va?', _members);
      expect(mentions.userIds, ['u-luca']);
      expect(mentions.all, isFalse);
    });

    test('prefers the longest matching name', () {
      final spans = findChatMentionSpans('@Anna Rossi ok', _members);
      expect(spans, hasLength(1));
      expect(spans.single.userId, 'u-anna-rossi');
      expect(spans.single.end, '@Anna Rossi'.length);
    });

    test('falls back to the shorter name when the longer does not fit', () {
      final mentions = extractChatMentions('@Anna Bianchi', _members);
      expect(mentions.userIds, ['u-anna']);
    });

    test('is case-insensitive and deduplicates', () {
      final mentions = extractChatMentions('@luca e ancora @LUCA', _members);
      expect(mentions.userIds, ['u-luca']);
    });

    test('recognises @tutti and the other languages', () {
      for (final keyword in ['tutti', 'all', 'everyone', 'tous', 'todos']) {
        final mentions = extractChatMentions('@$keyword riunione', _members);
        expect(mentions.all, isTrue, reason: keyword);
      }
    });

    test('ignores emails and partial words', () {
      expect(
        extractChatMentions('scrivi a luca@example.com', _members).isEmpty,
        isTrue,
      );
      expect(extractChatMentions('@Lucas', _members).isEmpty, isTrue);
      expect(extractChatMentions('@tuttifrutti', _members).isEmpty, isTrue);
    });

    test('mention followed by punctuation still counts', () {
      final mentions = extractChatMentions('@Luca, @tutti!', _members);
      expect(mentions.userIds, ['u-luca']);
      expect(mentions.all, isTrue);
    });

    test('text without @ has no spans', () {
      expect(findChatMentionSpans('ciao a tutti', _members), isEmpty);
    });
  });

  group('activeChatMentionQuery', () {
    test('detects the token being typed', () {
      const text = 'ciao @An';
      final query = activeChatMentionQuery(text, text.length)!;
      expect(query.start, 5);
      expect(query.query, 'An');
    });

    test('empty query right after @', () {
      final query = activeChatMentionQuery('@', 1)!;
      expect(query.query, '');
    });

    test('allows a space for first and last name', () {
      const text = '@Anna Ro';
      expect(activeChatMentionQuery(text, text.length)!.query, 'Anna Ro');
    });

    test('no query inside an email or after a newline', () {
      const email = 'luca@exa';
      expect(activeChatMentionQuery(email, email.length), isNull);
      const multiline = '@Luca\nciao';
      expect(activeChatMentionQuery(multiline, multiline.length), isNull);
    });

    test('a trailing space closes the query', () {
      const text = '@Anna Rossi ';
      expect(activeChatMentionQuery(text, text.length), isNull);
    });

    test('no query when the cursor is before the @', () {
      expect(activeChatMentionQuery('ciao @Luca', 2), isNull);
    });
  });

  group('filterChatMentionCandidates', () {
    test('prefix and word-prefix matches come first', () {
      final result = filterChatMentionCandidates(_members, 'ro');
      expect(result.map((c) => c.userId), ['u-anna-rossi']);
    });

    test('matches on secondary label (email)', () {
      final result = filterChatMentionCandidates(_members, 'example');
      expect(result, hasLength(3));
    });

    test('empty query lists everyone up to the limit', () {
      expect(filterChatMentionCandidates(_members, '', limit: 2), hasLength(2));
    });
  });

  test('chatMentionAllMatches', () {
    expect(chatMentionAllMatches('', 'tutti'), isTrue);
    expect(chatMentionAllMatches('tu', 'tutti'), isTrue);
    expect(chatMentionAllMatches('ev', 'tutti'), isTrue);
    expect(chatMentionAllMatches('lu', 'tutti'), isFalse);
  });

  group('applyChatMention', () {
    test('replaces the typed token and adds a trailing space', () {
      const text = 'ciao @An';
      final query = activeChatMentionQuery(text, text.length)!;
      final edit = applyChatMention(text, query, 'Anna Rossi', text.length);
      expect(edit.text, 'ciao @Anna Rossi ');
      expect(edit.cursor, edit.text.length);
    });

    test('keeps the text after the cursor without doubling spaces', () {
      const text = '@Lu come va';
      final query = activeChatMentionQuery(text, 3)!;
      final edit = applyChatMention(text, query, 'Luca', 3);
      expect(edit.text, '@Luca come va');
      expect(edit.cursor, '@Luca '.length);
    });
  });
}
