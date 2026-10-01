import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/sync/auth_service.dart';

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
    try {
      switch (widget.mode) {
        case AuthMode.signIn:
          await auth.signIn(_email.text, _password.text);
        case AuthMode.signUp:
          final ready = await auth.signUp(_email.text, _password.text);
          if (!ready && mounted) setState(() => _info = 'Account created. Check your inbox to confirm your email, then sign in.');
        case AuthMode.forgot:
          await auth.sendPasswordReset(_email.text);
          if (mounted) setState(() => _info = 'If an account exists, a reset link is on its way.');
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mode = widget.mode;
    final title = switch (mode) { AuthMode.signIn => 'Sign in', AuthMode.signUp => 'Create account', AuthMode.forgot => 'Reset password' };
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
                      Text('LeiOS', style: tt.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: Space.xl),
                      Text(title, style: tt.titleLarge),
                      const SizedBox(height: Space.lg),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email.' : null,
                        textInputAction: mode == AuthMode.forgot ? TextInputAction.done : TextInputAction.next,
                      ),
                      if (mode != AuthMode.forgot) ...[
                        const SizedBox(height: Space.md),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: [mode == AuthMode.signUp ? AutofillHints.newPassword : AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Use at least 6 characters.' : null,
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
                        TextButton(onPressed: () => context.go('/auth/forgot'), child: const Text('Forgot password?')),
                        TextButton(onPressed: () => context.go('/auth/sign-up'), child: const Text('Create an account')),
                      ] else
                        TextButton(onPressed: () => context.go('/auth/sign-in'), child: const Text('Back to sign in')),
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
