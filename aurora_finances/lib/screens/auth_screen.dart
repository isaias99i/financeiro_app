import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../widgets/aurora_scaffold.dart';
import '../theme/app_tokens.dart';

// Tela de login e cadastro com provedores sociais.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// Estado com validacao simples e carregamento.
class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isBusy = false;
  String? _error;

  // Libera controladores de texto.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Monta UI de login/cadastro.
  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return AuroraScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Aurora Finances',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin ? 'Entre com sua conta' : 'Crie sua conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration('Senha'),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: tokens.danger),
                      textAlign: TextAlign.center,
                    ),
                  if (_error != null) const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isBusy ? null : _handleEmailPassword,
                    child: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLogin ? 'Entrar' : 'Criar conta'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isBusy ? null : _toggleMode,
                    child: Text(
                      _isLogin
                          ? 'Nao tem conta? Criar agora'
                          : 'Ja tem conta? Entrar',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: tokens.border),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Entrar com Google'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _handleMicrosoftSignIn,
                    icon: const Icon(Icons.work_outline),
                    label: const Text('Entrar com Microsoft'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Estilo padrao dos inputs.
  InputDecoration _inputDecoration(String label) {
    final tokens = AppThemeTokens.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: tokens.textSecondary),
      filled: true,
      fillColor: tokens.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.border),
      ),
    );
  }

  // Alterna entre login e cadastro.
  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  // Autentica via email/senha.
  Future<void> _handleEmailPassword() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Falha ao autenticar.';
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  // Autentica via Google.
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }
      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Falha ao autenticar com Google.';
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  // Autentica via Microsoft.
  Future<void> _handleMicrosoftSignIn() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.addScope('email');
      provider.addScope('profile');
      await FirebaseAuth.instance.signInWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Falha ao autenticar com Microsoft.';
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }
}
