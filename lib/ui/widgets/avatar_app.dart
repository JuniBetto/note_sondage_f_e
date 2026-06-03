import 'package:flutter/material.dart';
import 'package:note_sondage/core/network/setup_dio.dart';

class AvatarApp extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const AvatarApp({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 40.0,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final originalUrl = imageUrl?.trim();
    final resolvedUrl = originalUrl != null && originalUrl.isNotEmpty
        ? DioClient.resolveImageUrl(originalUrl)
        : null;
    final authImageUrl = originalUrl;
    final requiresAuth =
        originalUrl != null &&
        originalUrl.isNotEmpty &&
        DioClient.usesAuthenticatedImageProxy(originalUrl);
    final authHeadersFuture = requiresAuth && authImageUrl != null
        ? DioClient.resolveImageHeaders(authImageUrl)
        : Future<Map<String, String>?>.value(null);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: resolvedUrl != null
            ? FutureBuilder<Map<String, String>?>(
                future: authHeadersFuture,
                builder: (context, snapshot) {
                  if (requiresAuth &&
                      snapshot.connectionState != ConnectionState.done) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: size * 0.5,
                          height: size * 0.5,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }

                  if (requiresAuth &&
                      (snapshot.data == null || snapshot.data!.isEmpty)) {
                    return _buildFallback();
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(size / 2),
                    child: Image.network(
                      resolvedUrl,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      headers: snapshot.data,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          '❌ AvatarApp: Failed to load image: $resolvedUrl – $error',
                        );
                        return _buildFallback();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: size * 0.5,
                              height: size * 0.5,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: initials != null
          ? Center(
              child: Text(
                initials!,
                style: TextStyle(
                  color: textColor,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Center(
              child: Icon(Icons.person, size: size * 0.5, color: textColor),
            ),
    );
  }
}
