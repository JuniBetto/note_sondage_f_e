import 'package:flutter/foundation.dart';
import 'package:note_sondage/feature/assistant/infrastructure/data_source/assistant_remote_data_source.dart';

enum AssistantMessageKind { user, assistant, error, unavailable }

class AssistantMessage {
  const AssistantMessage(this.kind, [this.text = '']);

  final AssistantMessageKind kind;

  /// Vuoto per `error`/`unavailable`: il testo localizzato lo sceglie la UI.
  final String text;
}

/// Stato della chat con l'assistente. Vive fuori dalla finestra, cosi'
/// chiudendola e riaprendola la conversazione resta visibile.
class AssistantSession extends ChangeNotifier {
  AssistantSession({AssistantRemoteDataSource? remote})
    : _remote = remote ?? AssistantRemoteDataSource();

  static final AssistantSession instance = AssistantSession();

  final AssistantRemoteDataSource _remote;
  final List<AssistantMessage> _messages = <AssistantMessage>[];
  String? _conversationId;
  String? _userId;
  bool _sending = false;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get sending => _sending;

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _sending) {
      return;
    }
    _messages.add(AssistantMessage(AssistantMessageKind.user, message));
    _sending = true;
    notifyListeners();
    try {
      final reply = await _remote.sendMessage(
        message: message,
        conversationId: _conversationId,
      );
      _conversationId = reply.conversationId;
      _messages.add(
        AssistantMessage(AssistantMessageKind.assistant, reply.reply),
      );
    } on AssistantUnavailableException {
      _messages.add(const AssistantMessage(AssistantMessageKind.unavailable));
    } catch (_) {
      _messages.add(const AssistantMessage(AssistantMessageKind.error));
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  /// Lega la chat all'utente collegato: se e' cambiato (logout e nuovo
  /// login) la conversazione precedente non deve essere visibile.
  void bindUser(String userId) {
    if (_userId != null && _userId != userId) {
      _conversationId = null;
      _messages.clear();
    }
    _userId = userId;
  }

  /// Svuota la chat e chiude la conversazione sul server.
  void reset() {
    final previous = _conversationId;
    _conversationId = null;
    _messages.clear();
    notifyListeners();
    if (previous != null) {
      _remote.deleteConversation(previous).catchError((_) {});
    }
  }
}
