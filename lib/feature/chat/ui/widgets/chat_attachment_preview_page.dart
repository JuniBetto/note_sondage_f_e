import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

/// Un allegato confermato dalla schermata di anteprima, con la sua didascalia.
class ChatAttachmentSendItem {
  const ChatAttachmentSendItem({
    required this.attachment,
    required this.caption,
  });

  final ChatDraftAttachment attachment;
  final String caption;
}

/// Anteprima a tutto schermo degli allegati selezionati (stile WhatsApp):
/// foto/file grandi, miniature per passare dall'uno all'altro, didascalia per
/// ciascun allegato e pulsante di invio con il numero di elementi.
///
/// Restituisce la lista da inviare, oppure `null` se l'utente chiude.
class ChatAttachmentPreviewPage extends StatefulWidget {
  const ChatAttachmentPreviewPage({
    super.key,
    required this.attachments,
    required this.accentColor,
    this.initialCaption = '',
    this.onAddMorePressed,
  });

  final List<ChatDraftAttachment> attachments;
  final Color accentColor;

  /// Testo già scritto nel composer: diventa la didascalia del primo allegato.
  final String initialCaption;

  /// Apre di nuovo il selettore e restituisce altri allegati da aggiungere.
  final Future<List<ChatDraftAttachment>> Function()? onAddMorePressed;

  static Future<List<ChatAttachmentSendItem>?> show(
    BuildContext context, {
    required List<ChatDraftAttachment> attachments,
    required Color accentColor,
    String initialCaption = '',
    Future<List<ChatDraftAttachment>> Function()? onAddMorePressed,
  }) {
    return Navigator.of(context).push<List<ChatAttachmentSendItem>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChatAttachmentPreviewPage(
          attachments: attachments,
          accentColor: accentColor,
          initialCaption: initialCaption,
          onAddMorePressed: onAddMorePressed,
        ),
      ),
    );
  }

  @override
  State<ChatAttachmentPreviewPage> createState() =>
      _ChatAttachmentPreviewPageState();
}

class _PreviewEntry {
  _PreviewEntry(this.attachment, String caption)
    : bytes = Uint8List.fromList(attachment.bytes),
      captionController = TextEditingController(text: caption);

  final ChatDraftAttachment attachment;
  final Uint8List bytes;
  final TextEditingController captionController;
}

class _ChatAttachmentPreviewPageState extends State<ChatAttachmentPreviewPage> {
  static const _backgroundColor = Color(0xFF0B0B0D);

  final PageController _pageController = PageController();
  late final List<_PreviewEntry> _entries;
  int _currentIndex = 0;
  bool _addingMore = false;

  _PreviewEntry get _current => _entries[_currentIndex];

  @override
  void initState() {
    super.initState();
    _entries = [
      for (var i = 0; i < widget.attachments.length; i++)
        _PreviewEntry(
          widget.attachments[i],
          i == 0 ? widget.initialCaption : '',
        ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final entry in _entries) {
      entry.captionController.dispose();
    }
    super.dispose();
  }

  void _goTo(int index) {
    if (index == _currentIndex) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _removeCurrent() {
    if (_entries.length == 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      final removed = _entries.removeAt(_currentIndex);
      removed.captionController.dispose();
      if (_currentIndex >= _entries.length) {
        _currentIndex = _entries.length - 1;
      }
    });
    _pageController.jumpToPage(_currentIndex);
  }

  Future<void> _addMore() async {
    final onAddMorePressed = widget.onAddMorePressed;
    if (onAddMorePressed == null || _addingMore) {
      return;
    }
    setState(() => _addingMore = true);
    try {
      final added = await onAddMorePressed();
      if (!mounted || added.isEmpty) {
        return;
      }
      final firstNewIndex = _entries.length;
      setState(() {
        _entries.addAll(added.map((item) => _PreviewEntry(item, '')));
      });
      _goTo(firstNewIndex);
    } finally {
      if (mounted) {
        setState(() => _addingMore = false);
      }
    }
  }

  void _send() {
    Navigator.of(context).pop([
      for (final entry in _entries)
        ChatAttachmentSendItem(
          attachment: entry.attachment,
          caption: entry.captionController.text.trim(),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final materialLoc = MaterialLocalizations.of(context);
    final showStrip = _entries.length > 1 || widget.onAddMorePressed != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: _current.attachment.fileName,
              counter: _entries.length > 1
                  ? '${_currentIndex + 1}/${_entries.length}'
                  : null,
              closeTooltip: materialLoc.closeButtonTooltip,
              removeTooltip: loc.chatRemoveAttachment,
              onClosePressed: () => Navigator.of(context).pop(),
              onRemovePressed: _removeCurrent,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _entries.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return entry.attachment.isImage
                      ? InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: Image.memory(
                              entry.bytes,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                                size: 56,
                              ),
                            ),
                          ),
                        )
                      : _DocumentPreview(
                          attachment: entry.attachment,
                          accentColor: widget.accentColor,
                        );
                },
              ),
            ),
            if (showStrip)
              _ThumbnailStrip(
                entries: _entries,
                currentIndex: _currentIndex,
                accentColor: widget.accentColor,
                addingMore: _addingMore,
                addMoreTooltip: loc.chatAttachmentAddMore,
                onSelected: _goTo,
                onAddMorePressed: widget.onAddMorePressed == null
                    ? null
                    : _addMore,
              ),
            _CaptionBar(
              // La chiave forza un nuovo TextField per ogni allegato, così
              // ognuno mantiene la propria didascalia.
              key: ValueKey(_current),
              controller: _current.captionController,
              hintText: loc.chatAttachmentCaptionHint,
              accentColor: widget.accentColor,
              count: _entries.length,
              onSendPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.counter,
    required this.closeTooltip,
    required this.removeTooltip,
    required this.onClosePressed,
    required this.onRemovePressed,
  });

  final String title;
  final String? counter;
  final String closeTooltip;
  final String removeTooltip;
  final VoidCallback onClosePressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClosePressed,
            tooltip: closeTooltip,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (counter != null)
                  Text(
                    counter!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemovePressed,
            tooltip: removeTooltip,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.attachment, required this.accentColor});

  final ChatDraftAttachment attachment;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = _extensionOf(attachment.fileName);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_drive_file_rounded,
                    size: 56,
                    color: accentColor,
                  ),
                  if (extension.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      extension.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              attachment.fileName,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatSize(attachment.sizeBytes),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.entries,
    required this.currentIndex,
    required this.accentColor,
    required this.addingMore,
    required this.addMoreTooltip,
    required this.onSelected,
    required this.onAddMorePressed,
  });

  static const double _tileSize = 56;

  final List<_PreviewEntry> entries;
  final int currentIndex;
  final Color accentColor;
  final bool addingMore;
  final String addMoreTooltip;
  final ValueChanged<int> onSelected;
  final VoidCallback? onAddMorePressed;

  @override
  Widget build(BuildContext context) {
    final itemCount = entries.length + (onAddMorePressed == null ? 0 : 1);

    return SizedBox(
      height: _tileSize + 16,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == entries.length) {
            return Tooltip(
              message: addMoreTooltip,
              child: InkWell(
                onTap: addingMore ? null : onAddMorePressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: _tileSize,
                  height: _tileSize,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: addingMore
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        )
                      : const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            );
          }

          final entry = entries[index];
          final selected = index == currentIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _tileSize,
              height: _tileSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? accentColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: entry.attachment.isImage
                    ? Image.memory(
                        entry.bytes,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        cacheWidth: 168,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Colors.white10,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                          ),
                        ),
                      )
                    : ColoredBox(
                        color: Colors.white,
                        child: Icon(
                          Icons.insert_drive_file_rounded,
                          color: accentColor,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CaptionBar extends StatelessWidget {
  const _CaptionBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.accentColor,
    required this.count,
    required this.onSendPressed,
  });

  final TextEditingController controller;
  final String hintText;
  final Color accentColor;
  final int count;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
              cursorColor: accentColor,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white54,
                ),
                filled: true,
                fillColor: Colors.white12,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: accentColor,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSendPressed,
                  child: const SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ),
              if (count > 1)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0 || dot == fileName.length - 1) {
    return '';
  }
  return fileName.substring(dot + 1);
}

String _formatSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  }
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
