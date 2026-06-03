import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class RequestAccountDeletionDialog extends StatefulWidget {
  const RequestAccountDeletionDialog({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<RequestAccountDeletionDialog> createState() =>
      _RequestAccountDeletionDialogState();
}

class _RequestAccountDeletionDialogState
    extends State<RequestAccountDeletionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final AuthUseCase _authUseCase;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _authUseCase = GetIt.instance<AuthUseCase>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final localization = AppLocalizations.of(context)!;

    try {
      await _authUseCase.requestAccountDeletion(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppSnackBar.showSuccess(
        context,
        localization.accountDeletionRequestSentMessage,
        title: localization.accountDeletionRequestSentTitle,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        AuthUserMessageResolver.resolve(
          error,
          fallback: localization.accountDeletionRequestFailedMessage,
        ),
        title: localization.accountDeletionRequestFailedTitle,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localization.deleteAccount),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.accountDeletionDialogMessage),
            const SizedBox(height: 16),
            CustomInputField(
              hintText: localization.email,
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              validator: emailValidator,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(localization.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(localization.sendConfirmationEmail),
        ),
      ],
    );
  }
}
