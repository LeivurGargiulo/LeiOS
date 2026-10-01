import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/sync/auth_service.dart';
import '../../l10n/app_localizations.dart';

enum AuthMode { signIn, signUp, forgot }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode});
  final AuthMode mode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final auth = ref.read(authServiceProvider);
    final l = L10n.of(context);
    try {
      switch (widget.mode) {
        case AuthMode.signIn:
          await auth.signIn(_email.text, _password.text);
        case AuthMode.signUp:
          final ready = await auth.signUp(_email.text, _password.text);
          if (!ready && mounted) setState(() => _info = l.authAccountCreated);
        case AuthMode.forgot:
          await auth.sendPasswordReset(_email.text);
          if (mounted) setState(() => _info = l.authResetSent);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mode = widget.mode;
    final title = switch (mode) { AuthMode.signIn => l.authSignIn, AuthMode.signUp => l.authCreateAccount, AuthMode.forgot => l.authResetPassword };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Layout.maxAuthWidth),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.spa_outlined, size: 56, color: cs.primary),
                      const SizedBox(height: Space.sm),
                      Text(l.appName, style: tt.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: Space.xl),
                      Text(title, style: tt.titleLarge),
                      const SizedBox(height: Space.lg),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(labelText: l.fieldEmail),
                        validator: (v) => (v == null || !v.contains('@')) ? l.authEnterValidEmail : null,
                        textInputAction: mode == AuthMode.forgot ? TextInputAction.done : TextInputAction.next,
                      ),
                      if (mode != AuthMode.forgot) ...[
                        const SizedBox(height: Space.md),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: [mode == AuthMode.signUp ? AutofillHints.newPassword : AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: l.fieldPassword,
                            suffixIcon: IconButton(
                              tooltip: _obscure ? l.authShowPassword : l.authHidePassword,
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? l.authPasswordMin : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (_error != null) Padding(padding: const EdgeInsets.only(top: Space.md), child: Text(_error!, style: TextStyle(color: cs.error), key: const Key('auth-error'))),
                      if (_info != null) Padding(padding: const EdgeInsets.only(top: Space.md), child: Text(_info!, style: TextStyle(color: cs.primary))),
                      const SizedBox(height: Space.lg),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(title),
                      ),
                      const SizedBox(height: Space.sm),
                      if (mode == AuthMode.signIn) ...[
                        TextButton(onPressed: () => context.go('/auth/forgot'), child: Text(l.authForgotPassword)),
                        TextButton(onPressed: () => context.go('/auth/sign-up'), child: Text(l.authCreateAnAccount)),
                      ] else
                        TextButton(onPressed: () => context.go('/auth/sign-in'), child: Text(l.authBackToSignIn)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
