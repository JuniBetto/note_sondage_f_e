import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class AuthenticatedUserSummaryCard extends StatelessWidget {
  const AuthenticatedUserSummaryCard({
    super.key,
    this.compact = false,
    this.margin,
    this.onTap,
  });

  final bool compact;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final displayName = _resolveDisplayName(user);
        final email = user.email.trim();
        final photoUrl = _resolvePhotoUrl(user);
        final showSecondaryEmail = email.isNotEmpty && email != displayName;

        final card = Container(
          margin: margin,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.selectItem!.withValues(alpha: 0.84),
                colorScheme.selectItem!.withValues(alpha: 0.64),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 18 : 20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.selectItem!.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 18 : 20),
            child: Row(
              children: [
                _UserAvatar(
                  displayName: displayName,
                  photoUrl: photoUrl,
                  size: compact ? 54 : 60,
                ),
                SizedBox(width: compact ? 14 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (showSecondaryEmail) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  SizedBox(width: compact ? 10 : 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ],
              ],
            ),
          ),
        );

        if (onTap == null) {
          return card;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(compact ? 18 : 20),
            onTap: onTap,
            child: card,
          ),
        );
      },
    );
  }

  String _resolveDisplayName(AuthUserEntity user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email.trim();
    if (email.isNotEmpty) {
      return email;
    }

    return 'Account';
  }

  String? _resolvePhotoUrl(AuthUserEntity user) {
    final photoUrl = user.photoUrl?.trim();
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }
    return photoUrl;
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.displayName,
    required this.photoUrl,
    required this.size,
  });

  final String displayName;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = photoUrl != null
        ? DioClient.resolveImageUrl(photoUrl!)
        : null;
    final requiresAuth =
        photoUrl != null && DioClient.usesAuthenticatedImageProxy(photoUrl!);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: FutureBuilder<Map<String, String>?>(
          future: requiresAuth
              ? DioClient.resolveImageHeaders(photoUrl!)
              : Future.value(null),
          builder: (context, snapshot) {
            if (requiresAuth &&
                snapshot.connectionState != ConnectionState.done) {
              return CircleAvatar(
                backgroundColor: Colors.transparent,
                child: SizedBox(
                  width: size * 0.45,
                  height: size * 0.45,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (requiresAuth &&
                (snapshot.data == null || snapshot.data!.isEmpty)) {
              return CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Text(
                  _buildInitials(displayName),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            return CircleAvatar(
              backgroundColor: Colors.transparent,
              foregroundImage: resolvedUrl != null
                  ? NetworkImage(resolvedUrl, headers: snapshot.data)
                  : null,
              child: photoUrl == null
                  ? Text(
                      _buildInitials(displayName),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : const Icon(Icons.person_rounded, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}
