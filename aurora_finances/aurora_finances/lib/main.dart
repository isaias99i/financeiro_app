import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/dashboard_screen.dart';
import 'theme/aurora_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null); // Inicializa o locale pt_BR
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gerenciador de Finanças',
      theme: buildAuroraTheme(),
      home: const DashboardScreen(),
    );
  }
}




// Telas específicas para Receitas, Despesas e Saldo Mensal


