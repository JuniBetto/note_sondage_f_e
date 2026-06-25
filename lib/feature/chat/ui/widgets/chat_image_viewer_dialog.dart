import 'dart:async';

import 'package:flutter/material.dart';
import 'package:note_sondage/core/network/setup_dio.dart';

class ChatImageViewerDialog extends StatelessWidget {
  const ChatImageViewerDialog({
    super.key,
    required this.attachmentPath,
    this.attachmentName,
    this.onDownloadPressed,
  });

  final String attachmentPath;
  final String? attachmentName;
  final FutureOr<void> Function()? onDownloadPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = DioClient.resolveImageUrl(attachmentPath);
    final requiresAuth = DioClient.usesAuthenticatedImageProxy(attachmentPath);
    final headersFuture = requiresAuth
        ? DioClient.resolveImageHeaders(attachmentPath)
        : Future<Map<String, String>?>.value(null);

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            attachmentName?.trim().isNotEmpty == true
                ? attachmentName!.trim()
                : 'Image',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (onDownloadPressed != null)
              IconButton(
                onPressed: onDownloadPressed,
                icon: const Icon(Icons.download_rounded),
              ),
          ],
        ),
        body: FutureBuilder<Map<String, String>?>(
          future: headersFuture,
          builder: (context, snapshot) {
            if (requiresAuth &&
                snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            return InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  headers: snapshot.data,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 44,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
