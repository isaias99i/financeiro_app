import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/aurora_scaffold.dart';

// Tela de configuracao de moeda e data.
class FormattingScreen extends StatelessWidget {
  const FormattingScreen({super.key});

  @override
  // Monta as opcoes de formato e moeda.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Moeda e formato'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Moeda',
            subtitle: 'Escolha a moeda principal',
            child: RadioGroup<_CurrencyOption>(
              groupValue: _currencyFromSettings(settings),
              onChanged: (value) {
                if (value == null) return;
                settings.updateCurrency(value.locale, value.symbol);
              },
              child: Column(
                children: _currencies.map((currency) {
                  return RadioListTile<_CurrencyOption>(
                    value: currency,
                    title: Text(currency.label, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${currency.symbol} - ${currency.locale}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    activeColor: Colors.white,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Formato de data',
            subtitle: 'Padrao exibido no app',
            child: RadioGroup<DateFormatStyle>(
              groupValue: settings.dateFormatStyle,
              onChanged: (value) {
                if (value == null) return;
                settings.updateDateFormat(value);
              },
              child: Column(
                children: DateFormatStyle.values.map((style) {
                  return RadioListTile<DateFormatStyle>(
                    value: style,
                    title: Text(_dateLabel(style), style: const TextStyle(color: Colors.white)),
                    activeColor: Colors.white,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Resolve a opcao de moeda atual.
  _CurrencyOption _currencyFromSettings(AppSettingsStore settings) {
    return _currencies.firstWhere(
      (option) =>
          option.locale == settings.currencyLocale && option.symbol == settings.currencySymbol,
      orElse: () => _currencies.first,
    );
  }

  // Retorna label de exibicao do formato de data.
  String _dateLabel(DateFormatStyle style) {
    return switch (style) {
      DateFormatStyle.dayMonthYear => 'DD/MM/AAAA',
      DateFormatStyle.monthDayYear => 'MM/DD/AAAA',
      DateFormatStyle.yearMonthDay => 'AAAA-MM-DD',
    };
  }
}

// Modelo interno de moeda suportada.
class _CurrencyOption {
  final String label;
  final String locale;
  final String symbol;

  const _CurrencyOption({
    required this.label,
    required this.locale,
    required this.symbol,
  });
}

const List<_CurrencyOption> _currencies = [
  _CurrencyOption(label: 'Real brasileiro', locale: 'pt_BR', symbol: 'R\$'),
  _CurrencyOption(label: 'Dolar americano', locale: 'en_US', symbol: '\$'),
  _CurrencyOption(label: 'Euro', locale: 'es_ES', symbol: '€'),
];

// Card de secao para as configuracoes.
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  // Monta o card de secao.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
