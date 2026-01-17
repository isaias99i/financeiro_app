import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'screens/dashboard_screen.dart';
import 'data/settings_store.dart';
import 'theme/aurora_theme.dart';
import 'widgets/app_settings_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('es_ES', null);
  final settingsStore = AppSettingsStore();
  await settingsStore.load();
  runApp(FinanceApp(settingsStore: settingsStore));
}

class FinanceApp extends StatelessWidget {
  final AppSettingsStore settingsStore;

  const FinanceApp({super.key, required this.settingsStore});

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
            home: const DashboardScreen(),
          ),
        );
      },
    );
  }
}
