import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'data/settings_store.dart';
import 'theme/aurora_theme.dart';
import 'widgets/app_settings_scope.dart';

// Ponto de entrada do app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('pt_BR', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('es_ES', null);
  final settingsStore = AppSettingsStore();
  await settingsStore.loadForUser(null);
  runApp(FinanceApp(settingsStore: settingsStore));
}

// Widget raiz que aplica tema e localizacao.
class FinanceApp extends StatelessWidget {
  final AppSettingsStore settingsStore;

  const FinanceApp({super.key, required this.settingsStore});

  // Construi MaterialApp com tema e escopo de settings.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsStore,
      builder: (context, _) {
        final localeParts = settingsStore.currencyLocale.split('_');
        final locale = localeParts.length == 2
            ? Locale(localeParts[0], localeParts[1])
            : Locale(localeParts.first);
        Intl.defaultLocale = settingsStore.currencyLocale;

        return AppSettingsScope(
          settings: settingsStore,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gerenciador de Financas',
            theme: buildAuroraTheme(settingsStore),
            locale: locale,
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
              Locale('es', 'ES'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final scale = settingsStore.textScaleFactor();
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: AuthGate(settingsStore: settingsStore),
          ),
        );
      },
    );
  }
}

// Gate de autenticacao para decidir login ou dashboard.
class AuthGate extends StatefulWidget {
  final AppSettingsStore settingsStore;

  const AuthGate({super.key, required this.settingsStore});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStream;
  User? _user;
  Future<void>? _settingsLoad;

  // Escuta mudancas de autenticacao.
  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  // Renderiza login, loading ou dashboard conforme o estado.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (_user?.uid != user?.uid) {
          _user = user;
          _settingsLoad = widget.settingsStore.loadForUser(user?.uid);
        }
        if (user == null) {
          return const AuthScreen();
        }
        return FutureBuilder<void>(
          future: _settingsLoad,
          builder: (context, loadSnapshot) {
            if (loadSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return DashboardScreen(userId: user.uid);
          },
        );
      },
    );
  }
}
