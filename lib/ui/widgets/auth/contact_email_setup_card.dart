import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class ContactEmailSetupCard extends StatelessWidget {
  const ContactEmailSetupCard({super.key, this.compact = false});

  final bool compact;
  static final BackendAuthDataSource _backendAuth = BackendAuthDataSource();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        if (user.provider != AuthProvider.phone) {
          return const SizedBox.shrink();
        }

        final colorScheme = Theme.of(context).colorScheme;
        final authEmail = user.email.trim();

        return FutureBuilder<String?>(
          future: authEmail.isEmpty ? _backendAuth.getMyProfileEmail() : null,
          builder: (context, snapshot) {
            final currentValue = authEmail.isNotEmpty
                ? authEmail
                : (snapshot.data?.trim() ?? '');
            final subtitle = currentValue.isNotEmpty
                ? 'Current invitation email: $currentValue'
                : 'Add an email so team invitations can keep using the current email-based flow.';

            return Container(
              margin: compact ? null : const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.alternate_email_rounded,
                    color: colorScheme.selectItem,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invitation email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () async {
                      final updatedEmail = await showDialog<String>(
                        context: context,
                        builder: (_) =>
                            _ContactEmailDialog(initialValue: currentValue),
                      );
                      if (!context.mounted || updatedEmail == null) return;
                      context.read<AuthBloc>().add(
                        AuthProfileEmailUpdated(updatedEmail),
                      );
                    },
                    child: Text(currentValue.isEmpty ? 'Add email' : 'Edit'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ContactEmailDialog extends StatefulWidget {
  const _ContactEmailDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_ContactEmailDialog> createState() => _ContactEmailDialogState();
}

class _ContactEmailDialogState extends State<_ContactEmailDialog> {
  final _controller = TextEditingController();
  final _authUseCase = getIt<AuthUseCase>();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final email = _controller.text.trim().toLowerCase();
      await _authUseCase.updateContactEmail(email: email);
      if (!mounted) return;
      Navigator.of(context).pop(email);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthUserMessageResolver.resolve(
          error,
          fallback:
              'We could not save the invitation email right now. Please try again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitation email'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This email will be used for team invitations and other flows that already rely on email.',
              ),
              const SizedBox(height: 16),
              CustomInputField(
                hintText: 'name@example.com',
                controller: _controller,
                prefixIcon: Icons.email_outlined,
                validator: emailValidator,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
