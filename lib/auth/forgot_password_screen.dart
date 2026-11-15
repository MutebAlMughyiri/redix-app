import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/act_once.dart';
import '../ui/app_color.dart';
import '../ui/form_button_style.dart';
import '../ui/form_error.dart';
import '../ui/messages.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'password_reset.dart';
import 'sign_in_screen.dart';

/// «نسيت كلمة المرور؟» (redix-api #127, AC-02.6): one screen, two steps, open without a session. The first sends a code to the email of the account whose username or email
/// is typed (D5), and says the same sentence whether or not the account or its email exists (R5, AC-02.7); the second takes the code and the new password twice, and once it
/// is changed returns to sign-in saying so. Every session of the person ends with it (AC-02.9).
class ForgotPasswordScreen extends StatefulWidget {
  /// The screen.
  const ForgotPasswordScreen({super.key});

  /// The screen's route, which the router lets anyone reach.
  static const path = '/forgot-password';

  /// The username or email field.
  static const loginKey = Key('forgotPassword.login');

  /// The button that sends the code.
  static const sendKey = Key('forgotPassword.send');

  /// The sentence saying a code was sent if the account has an email.
  static const sentKey = Key('forgotPassword.sent');

  /// The code field.
  static const codeKey = Key('forgotPassword.code');

  /// The new password field.
  static const newKey = Key('forgotPassword.new');

  /// The field that repeats the new password.
  static const confirmKey = Key('forgotPassword.confirm');

  /// The button that changes the password.
  static const resetKey = Key('forgotPassword.reset');

  /// The line that says why a step was refused.
  static const messageKey = Key('forgotPassword.message');

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _login = TextEditingController();
  final _code = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  var _isSent = false;
  var _message = '';

  @override
  void dispose() {
    _login.dispose();
    _code.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _message = '');
    final refusal = await askResetCode(_login.text.trim(), Localizations.localeOf(context).languageCode);
    if (mounted) {
      setState(() {
        _message = refusal;
        _isSent = _isSent || refusal.isEmpty;
      });
    }
  }

  Future<void> _reset() async {
    if (_new.text != _confirm.text) {
      setState(() => _message = 'changePassword.mismatch');
      return;
    }
    final refusal = await resetWithCode(_login.text.trim(), _code.text.trim(), _new.text);
    if (!mounted) {
      return;
    }
    setState(() => _message = refusal);
    if (refusal.isEmpty) {
      showMessage(ScaffoldMessenger.of(context), Words.of(context), 'auth.passwordReset');
      context.go(SignInScreen.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return ActOnce(builder: (once) => Scaffold(
      appBar: AppBar(title: Text(words.authForgotPassword, key: ScreenTitle.titleKey)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_message.isNotEmpty) FormError(text: words.text(_message), textKey: ForgotPasswordScreen.messageKey),
              TextField(
                key: ForgotPasswordScreen.loginKey,
                controller: _login,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: words.authLoginOrEmail),
                onSubmitted: (_) => once(_send)?.call(),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                key: ForgotPasswordScreen.sendKey,
                onPressed: once(_send),
                style: formButtonStyle,
                child: Text(words.authSendCode, key: ForgotPasswordScreen.sendKey.label),
              ),
              if (_isSent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColor.noticeSurface.of(context), borderRadius: BorderRadius.circular(8)),
                  child: Text(words.authCodeSent, key: ForgotPasswordScreen.sentKey, style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: ForgotPasswordScreen.codeKey,
                  controller: _code,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: words.authCode),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: ForgotPasswordScreen.newKey,
                  controller: _new,
                  obscureText: true,
                  decoration: InputDecoration(labelText: words.changePasswordNew, helperText: words.commonPasswordRules, helperMaxLines: 2),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: ForgotPasswordScreen.confirmKey,
                  controller: _confirm,
                  obscureText: true,
                  decoration: InputDecoration(labelText: words.changePasswordConfirm),
                  onSubmitted: (_) => once(_reset)?.call(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: ForgotPasswordScreen.resetKey,
                  onPressed: once(_reset),
                  style: formButtonStyle,
                  child: Text(words.authResetWithCode, key: ForgotPasswordScreen.resetKey.label),
                ),
              ],
            ],
          ),
        ),
      ),
    ));
  }
}
