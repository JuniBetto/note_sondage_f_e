import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/feature/notification/push/push_diagnostics_snapshot.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class PushDiagnosticsPanel extends StatelessWidget {
  const PushDiagnosticsPanel({
    required this.isLoading,
    required this.onRefresh,
    required this.onSyncNow,
    this.snapshot,
    super.key,
  });

  final PushDiagnosticsSnapshot? snapshot;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSyncNow;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final data = snapshot;
    final hint = data == null ? null : _buildHint(data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.homePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.borderColor!.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Push diagnostic',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: isLoading ? null : () => onRefresh(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isLoading ? null : () => onSyncNow(),
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Sync device'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use this panel to verify remote push registration for this device.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.descriptionColor,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (snapshot == null)
            Text('No diagnostic data loaded yet.', style: textTheme.bodyMedium)
          else if (data != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hint != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hint.isError
                          ? const Color(0xFFFFF4F4)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hint.isError
                            ? const Color(0xFFFFCDD2)
                            : const Color(0xFFFFE082),
                      ),
                    ),
                    child: Text(
                      hint.message,
                      style: textTheme.bodySmall?.copyWith(
                        color: hint.isError
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF7A4B00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: 'Permission',
                      value: data.authorizationStatus,
                      ok: data.notificationsAuthorized,
                    ),
                    _StatusChip(
                      label: 'APNs',
                      value: _usesApns(data)
                          ? (data.hasApnsToken ? 'ok' : 'missing')
                          : 'n/a',
                      ok: !_usesApns(data) || data.hasApnsToken,
                    ),
                    _StatusChip(
                      label: 'FCM',
                      value: data.hasFcmToken ? 'ok' : 'missing',
                      ok: data.hasFcmToken,
                    ),
                    _StatusChip(
                      label: 'Backend',
                      value: data.hasBackendMatchingDevice
                          ? 'matched'
                          : 'missing',
                      ok: data.hasBackendMatchingDevice,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DiagnosticLine(label: 'Platform', value: data.platformLabel),
                _DiagnosticLine(
                  label: 'API base URL',
                  value: data.apiBaseUrl,
                  secondary: data.hasCustomApiBaseUrl
                      ? 'Provided with --dart-define=API_BASE_URL'
                      : 'Using built-in fallback host',
                  isError:
                      data.isUsingFallbackApiBaseUrl &&
                      data.isUsingLoopbackOrEmulatorHost,
                ),
                _DiagnosticLine(
                  label: 'Service available',
                  value: data.serviceAvailable ? 'yes' : 'no',
                ),
                _DiagnosticLine(
                  label: 'Current user',
                  value: data.userId ?? 'missing',
                ),
                _DiagnosticLine(
                  label: 'Device fingerprint',
                  value: data.deviceFingerprint ?? 'missing',
                ),
                _DiagnosticLine(
                  label: 'APNs token',
                  value: _usesApns(data) ? data.apnsTokenPreview : 'n/a',
                ),
                _DiagnosticLine(
                  label: 'FCM token',
                  value: data.fcmTokenPreview,
                ),
                _DiagnosticLine(
                  label: 'Cached registered user',
                  value: data.cachedRegisteredUserId ?? 'missing',
                ),
                _DiagnosticLine(
                  label: 'Cached registered token',
                  value: data.cachedTokenPreview,
                ),
                _DiagnosticLine(
                  label: 'Cached registered at',
                  value: _formatDateTime(data.cachedRegisteredAt),
                ),
                _DiagnosticLine(
                  label: 'Backend devices',
                  value: '${data.backendDevices.length}',
                ),
                if (data.backendDevices.isNotEmpty)
                  ...data.backendDevices.map(
                    (device) => _DiagnosticLine(
                      label: 'Device',
                      value:
                          '${device.platform ?? 'n/a'} • ${device.pushProvider ?? 'n/a'} • ${device.deviceName ?? 'unnamed'}',
                      secondary:
                          'fingerprint=${device.deviceFingerprint ?? 'missing'} • lastSeen=${_formatDateTime(device.lastSeenAt)}',
                    ),
                  ),
                if (data.lastRegistrationError?.trim().isNotEmpty ?? false)
                  _DiagnosticLine(
                    label: 'Last sync error',
                    value: data.lastRegistrationError!,
                    isError: true,
                  ),
                if (data.backendFetchError?.trim().isNotEmpty ?? false)
                  _DiagnosticLine(
                    label: 'Backend fetch error',
                    value: data.backendFetchError!,
                    isError: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static bool _usesApns(PushDiagnosticsSnapshot snapshot) {
    return snapshot.platformLabel.trim().toLowerCase() == 'ios';
  }

  static _PushDiagnosticHint? _buildHint(PushDiagnosticsSnapshot snapshot) {
    if (_usesApns(snapshot) &&
        snapshot.notificationsAuthorized &&
        !snapshot.hasApnsToken &&
        !snapshot.hasFcmToken) {
      return const _PushDiagnosticHint(
        message:
            'This iOS device is authorized, but APNs/FCM tokens are still missing. '
            'If this is an iOS Simulator, remote push will not be a valid test here. '
            'Use a physical iPhone for end-to-end push checks.',
        isError: false,
      );
    }
    if (snapshot.isUsingFallbackApiBaseUrl &&
        snapshot.isUsingLoopbackOrEmulatorHost &&
        snapshot.notificationsAuthorized &&
        !snapshot.hasBackendMatchingDevice) {
      return const _PushDiagnosticHint(
        message:
            'This build is using a local fallback API host '
            '(127.0.0.1 or 10.0.2.2). That works for simulator/emulator only. '
            'On a real phone, rebuild with --dart-define=API_BASE_URL=http(s)://<reachable-host>:8080.',
        isError: true,
      );
    }
    if (!_usesApns(snapshot) &&
        snapshot.notificationsAuthorized &&
        snapshot.hasFcmToken &&
        snapshot.hasBackendMatchingDevice) {
      return const _PushDiagnosticHint(
        message:
            'Android push registration looks healthy on this device. '
            'If one feature still fails in background, the next check is the backend event path for that feature.',
        isError: false,
      );
    }
    if (snapshot.notificationsAuthorized &&
        !snapshot.hasBackendMatchingDevice) {
      return const _PushDiagnosticHint(
        message:
            'The device has notification permission, but backend registration is missing. '
            'Try Sync device and verify the signed-in user matches the device registration.',
        isError: true,
      );
    }
    return null;
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'missing';
    }
    return value.toIso8601String();
  }
}

class _PushDiagnosticHint {
  const _PushDiagnosticHint({required this.message, required this.isError});

  final String message;
  final bool isError;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.textColor),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticLine extends StatelessWidget {
  const _DiagnosticLine({
    required this.label,
    required this.value,
    this.secondary,
    this.isError = false,
  });

  final String label;
  final String value;
  final String? secondary;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: textTheme.bodySmall?.copyWith(
                color: isError
                    ? const Color(0xFFC62828)
                    : colorScheme.textColor,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
          if (secondary != null && secondary!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                secondary!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.descriptionColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
