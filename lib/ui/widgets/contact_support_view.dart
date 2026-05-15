import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportView extends StatefulWidget {
  const ContactSupportView({super.key, this.compact = false});

  final bool compact;

  @override
  State<ContactSupportView> createState() => _ContactSupportViewState();
}

class _ContactSupportViewState extends State<ContactSupportView> {
  static const _supportEmail = 'Junibetto@gmail.com';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _didPrefillUser = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefillUser) {
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState.user.isNotEmpty) {
      final displayName = authState.user.displayName?.trim() ?? '';
      final email = authState.user.email.trim();
      if (displayName.isNotEmpty) {
        _nameController.text = displayName;
      }
      if (email.isNotEmpty) {
        _emailController.text = email;
      }
    }
    _didPrefillUser = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final loc = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    final subject = name.isEmpty
        ? loc.contactUsEmailSubject
        : '${loc.contactUsEmailSubject} - $name';
    final body = <String>[
      '${loc.yourName}: ${name.isEmpty ? '-' : name}',
      '${loc.yourEmail}: ${email.isEmpty ? '-' : email}',
      '',
      '${loc.message}:',
      message,
    ].join('\n');

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: _encodeQueryParameters({'subject': subject, 'body': body}),
    );

    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      AppSnackBar.showWarning(context, loc.couldNotOpenEmailApp);
    }
  }

  Future<void> _copyEmail() async {
    final loc = AppLocalizations.of(context)!;
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!mounted) {
      return;
    }
    AppSnackBar.showSuccess(context, loc.emailCopied, title: loc.supportEmail);
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');
  }

  InputDecoration _buildDecoration(
    BuildContext context,
    String label, {
    int? maxLines,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor =
        colorScheme.borderColor?.withValues(alpha: 0.7) ??
        colorScheme.outlineVariant;

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: fillColor ?? colorScheme.surface,
      suffixIcon: suffixIcon,
      alignLabelWithHint: maxLines != null && maxLines > 1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colorScheme.selectItem ?? colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final horizontalPadding = widget.compact ? 16.0 : 28.0;
    final topPadding = widget.compact ? 16.0 : 28.0;
    final cardBackground =
        colorScheme.homeSecondary ??
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          24,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920 && !widget.compact;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SupportHeroCard(
                  title: loc.contactUs,
                  description: loc.contactUsDescription,
                  supportEmail: _supportEmail,
                  replyTime: loc.contactUsReplyTime,
                  compact: widget.compact,
                ),
                const SizedBox(height: 20),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 10,
                        child: _SupportInfoPanel(
                          backgroundColor: cardBackground,
                          supportEmailLabel: loc.supportEmail,
                          supportEmail: _supportEmail,
                          topicsTitle: loc.contactUsTopicsTitle,
                          topicsBody: loc.contactUsTopicsBody,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 14,
                        child: _SupportFormCard(
                          backgroundColor: cardBackground,
                          nameController: _nameController,
                          emailController: _emailController,
                          messageController: _messageController,
                          buildDecoration: _buildDecoration,
                          onSendEmail: _sendEmail,
                          onCopyEmail: _copyEmail,
                          sendLabel: loc.sendEmail,
                          copyLabel: loc.copyEmail,
                          yourNameLabel: loc.yourName,
                          yourEmailLabel: loc.yourEmail,
                          messageLabel: loc.message,
                          formHint: loc.contactUsFormHint,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _SupportInfoPanel(
                        backgroundColor: cardBackground,
                        supportEmailLabel: loc.supportEmail,
                        supportEmail: _supportEmail,
                        topicsTitle: loc.contactUsTopicsTitle,
                        topicsBody: loc.contactUsTopicsBody,
                      ),
                      const SizedBox(height: 20),
                      _SupportFormCard(
                        backgroundColor: cardBackground,
                        nameController: _nameController,
                        emailController: _emailController,
                        messageController: _messageController,
                        buildDecoration: _buildDecoration,
                        onSendEmail: _sendEmail,
                        onCopyEmail: _copyEmail,
                        sendLabel: loc.sendEmail,
                        copyLabel: loc.copyEmail,
                        yourNameLabel: loc.yourName,
                        yourEmailLabel: loc.yourEmail,
                        messageLabel: loc.message,
                        formHint: loc.contactUsFormHint,
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SupportHeroCard extends StatelessWidget {
  const _SupportHeroCard({
    required this.title,
    required this.description,
    required this.supportEmail,
    required this.replyTime,
    required this.compact,
  });

  final String title;
  final String description;
  final String supportEmail;
  final String replyTime;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.selectItem ?? colorScheme.primary;
    final secondaryAccent =
        colorScheme.primaryColor ??
        colorScheme.secondary.withValues(alpha: 0.9);
    final baseSurface = colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.12), baseSurface),
            Color.alphaBlend(
              secondaryAccent.withValues(alpha: 0.08),
              baseSurface,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accent.withValues(alpha: compact ? 0.16 : 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.16)),
                  ),
                  child: Text(
                    replyTime,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.descriptionColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alternate_email_rounded,
                        color: accent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          supportEmail,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroFeatureChip(
                      icon: Icons.mail_outline_rounded,
                      label: supportEmail,
                      accent: accent,
                    ),
                    _HeroFeatureChip(
                      icon: Icons.schedule_rounded,
                      label: replyTime,
                      accent: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: compact ? 96 : 128,
            height: compact ? 96 : 128,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Icon(Icons.support_agent_rounded, color: accent, size: 62),
          ),
        ],
      ),
    );
  }
}

class _SupportInfoPanel extends StatelessWidget {
  const _SupportInfoPanel({
    required this.backgroundColor,
    required this.supportEmailLabel,
    required this.supportEmail,
    required this.topicsTitle,
    required this.topicsBody,
  });

  final Color backgroundColor;
  final String supportEmailLabel;
  final String supportEmail;
  final String topicsTitle;
  final String topicsBody;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor =
        colorScheme.borderColor?.withValues(alpha: 0.32) ??
        colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoTile(
            icon: Icons.mail_outline_rounded,
            title: supportEmailLabel,
            body: supportEmail,
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.auto_awesome_rounded,
            title: topicsTitle,
            body: topicsBody,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.selectItem ?? colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.descriptionColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportFormCard extends StatelessWidget {
  const _SupportFormCard({
    required this.backgroundColor,
    required this.nameController,
    required this.emailController,
    required this.messageController,
    required this.buildDecoration,
    required this.onSendEmail,
    required this.onCopyEmail,
    required this.sendLabel,
    required this.copyLabel,
    required this.yourNameLabel,
    required this.yourEmailLabel,
    required this.messageLabel,
    required this.formHint,
  });

  final Color backgroundColor;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController messageController;
  final InputDecoration Function(
    BuildContext context,
    String label, {
    int? maxLines,
    Widget? suffixIcon,
    Color? fillColor,
  })
  buildDecoration;
  final VoidCallback onSendEmail;
  final VoidCallback onCopyEmail;
  final String sendLabel;
  final String copyLabel;
  final String yourNameLabel;
  final String yourEmailLabel;
  final String messageLabel;
  final String formHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor =
        colorScheme.borderColor?.withValues(alpha: 0.32) ??
        colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sendLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.descriptionColor,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: nameController,
            readOnly: true,
            decoration: buildDecoration(
              context,
              yourNameLabel,
              fillColor: colorScheme.surface.withValues(alpha: 0.65),
              suffixIcon: Icon(
                Icons.lock_outline_rounded,
                color: colorScheme.descriptionColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: emailController,
            readOnly: true,
            keyboardType: TextInputType.emailAddress,
            decoration: buildDecoration(
              context,
              yourEmailLabel,
              fillColor: colorScheme.surface.withValues(alpha: 0.65),
              suffixIcon: Icon(
                Icons.lock_outline_rounded,
                color: colorScheme.descriptionColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: messageController,
            maxLines: 7,
            minLines: 5,
            decoration: buildDecoration(context, messageLabel, maxLines: 7),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onSendEmail,
                icon: const Icon(Icons.send_rounded),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor:
                      colorScheme.selectItem ?? colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                label: Text(sendLabel),
              ),
              OutlinedButton.icon(
                onPressed: onCopyEmail,
                icon: const Icon(Icons.copy_rounded),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  side: BorderSide(
                    color:
                        colorScheme.selectItem?.withValues(alpha: 0.35) ??
                        colorScheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                label: Text(copyLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFeatureChip extends StatelessWidget {
  const _HeroFeatureChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
