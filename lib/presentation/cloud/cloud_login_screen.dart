import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../state/providers.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class CloudLoginScreen extends ConsumerStatefulWidget {
  const CloudLoginScreen({super.key});

  @override
  ConsumerState<CloudLoginScreen> createState() => _CloudLoginScreenState();
}

class _CloudLoginScreenState extends ConsumerState<CloudLoginScreen> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = l.cloudLoginEmailInvalid);
      return;
    }
    setState(() {
      _emailError = null;
      _sending = true;
    });
    try {
      await ref.read(authServiceProvider).signInWithMagicLink(email);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (_) {
      if (!mounted) return;
      showFToast(context: context, title: Text(l.cloudLoginGenericError));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    return FScaffold(
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(title: l.cloudLoginTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSizes.screenPadding,
                child: AppSectionCard(
                  icon: FIcons.cloud,
                  title: l.cloudLoginTitle,
                  child: _sent
                      ? Text(
                          l.cloudLoginCheckEmail,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.foreground,
                          ),
                        )
                      : FTextField(
                          control: FTextFieldControl.managed(
                            controller: _emailCtrl,
                            onChange: (_) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                          ),
                          label: Text(l.cloudLoginEmailLabel),
                          hint: l.cloudLoginEmailHint,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          error: _emailError != null
                              ? Text(_emailError!)
                              : null,
                        ),
                ),
              ),
            ),
            if (!_sent)
              AppActionBar(
                primary: AppPrimaryButton(
                  label: l.cloudLoginSendButton,
                  prefixIcon: FIcons.send,
                  loading: _sending,
                  onPress: _sending ? null : _submit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
