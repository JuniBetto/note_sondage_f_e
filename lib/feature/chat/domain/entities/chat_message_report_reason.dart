enum ChatMessageReportReason {
  spam,
  harassment,
  hateSpeech,
  sexualContent,
  violence,
  other,
}

extension ChatMessageReportReasonValue on ChatMessageReportReason {
  String get wireValue => switch (this) {
    ChatMessageReportReason.spam => 'SPAM',
    ChatMessageReportReason.harassment => 'HARASSMENT',
    ChatMessageReportReason.hateSpeech => 'HATE_SPEECH',
    ChatMessageReportReason.sexualContent => 'SEXUAL_CONTENT',
    ChatMessageReportReason.violence => 'VIOLENCE',
    ChatMessageReportReason.other => 'OTHER',
  };
}
