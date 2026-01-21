import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/despesas_store.dart';
import '../data/carteira_store.dart';
import '../data/menu_store.dart';
import '../data/receitas_store.dart';
import '../data/categories_store.dart';
import '../screens/settings_screen.dart';
import '../widgets/carteira_widget.dart';
import '../widgets/resumo_financeiro_widget.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/app_settings_scope.dart';
import '../theme/app_tokens.dart';

// Tela principal com resumo e indicadores financeiros.
class DashboardScreen extends StatefulWidget {
  final double reserva;
  final String userId;

  const DashboardScreen({super.key, required this.userId, this.reserva = 0.0});

  @override
  // Cria o estado da tela do dashboard.
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// Estado do dashboard com cargas e filtros.
class _DashboardScreenState extends State<DashboardScreen> {
  late final MenuStore _menuStore;
  late final ReceitasStore _receitasStore;
  late final DespesasStore _despesasStore;
  late final CarteiraStore _carteiraStore;
  late final CategoriesStore _categoriesStore;
  DashboardPeriod _period = DashboardPeriod.month;
  int _forecastMonths = 12;

  @override
  // Inicializa stores e carrega dados iniciais.
  void initState() {
    super.initState();
    _menuStore = MenuStore();
    _receitasStore = ReceitasStore(userId: widget.userId);
    _despesasStore = DespesasStore(userId: widget.userId);
    _carteiraStore = CarteiraStore(userId: widget.userId);
    _categoriesStore = CategoriesStore(userId: widget.userId);
    _receitasStore.load();
    _despesasStore.load();
    _carteiraStore.load();
    _categoriesStore.load();
  }

  @override
  // Libera os stores ao sair da tela.
  void dispose() {
    _menuStore.dispose();
    _receitasStore.dispose();
    _despesasStore.dispose();
    _carteiraStore.dispose();
    _categoriesStore.dispose();
    super.dispose();
  }

  @override
  // Monta a UI principal do dashboard.
  Widget build(BuildContext context) {
    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Configuracoes',
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _receitasStore,
          _despesasStore,
          _carteiraStore,
        ]),
        builder: (context, _) {
          if (!_receitasStore.isLoaded ||
              !_despesasStore.isLoaded ||
              !_carteiraStore.isLoaded ||
              !_categoriesStore.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = AppSettingsScope.of(context);
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month, 1);

          final receitasMes = _receitasStore.totalForMonth(currentMonth);
          final despesasMes = _despesasStore.totalForMonth(currentMonth);

          final double saldoMensal = receitasMes + despesasMes;
          final double saldoAposReserva = saldoMensal - widget.reserva;
          final double saldoAtual = _carteiraStore.totalBalance;
          final int periodMonths = _period.months;
          final double receitasPeriodo = _sumForPeriod(
            now,
            periodMonths,
            _receitasStore.totalForMonth,
          );
          final double despesasPeriodo = _sumForPeriod(
            now,
            periodMonths,
            _despesasStore.totalForMonth,
          );
          final double saldoPeriodo = receitasPeriodo + despesasPeriodo;
          final double saldoMesAnterior =
              _receitasStore.totalForMonth(_monthOffset(now, 1)) +
              _despesasStore.totalForMonth(_monthOffset(now, 1));
          final _Variation variation = _buildVariation(
            saldoMensal,
            saldoMesAnterior,
          );
          final forecast = _buildForecast(now, _forecastMonths);

          return RefreshIndicator(
            onRefresh: _refreshAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroSaldoCard(
                    saldoAtual: saldoAtual,
                    saldoPeriodo: saldoPeriodo,
                    periodLabel: _period.label,
                    variation: variation,
                    formatter: settings.currencyFormatter(),
                  ),
                  const SizedBox(height: 12),
                  _PeriodChips(
                    selected: _period,
                    onSelected: (value) => setState(() => _period = value),
                  ),
                  const SizedBox(height: 16),
                  ResumoFinanceiroWidget(
                    menuStore: _menuStore,
                    receitasStore: _receitasStore,
                    despesasStore: _despesasStore,
                    categoriesStore: _categoriesStore,
                    receitas: receitasMes,
                    despesas: despesasMes,
                    saldoMensal: saldoMensal,
                    saldoAposReserva: saldoAposReserva,
                    saldoAtual: saldoAtual,
                    segurancaAno: despesasMes.abs() * 12,
                  ),
                  const SizedBox(height: 16),
                  _ForecastCard(
                    months: _forecastMonths,
                    values: forecast.values,
                    monthLabels: forecast.months
                        .map(
                          (date) =>
                              settings.shortMonthYearFormatter().format(date),
                        )
                        .toList(),
                    formatter: settings.currencyFormatter(),
                    onChanged: (value) =>
                        setState(() => _forecastMonths = value),
                  ),
                  const SizedBox(height: 20),
                  CarteiraWidget(
                    store: _carteiraStore,
                    expectedBalance: saldoMensal,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Retorna a data de um mes anterior.
  DateTime _monthOffset(DateTime base, int offset) {
    return DateTime(base.year, base.month - offset, 1);
  }

  // Soma valores em uma janela de meses.
  double _sumForPeriod(
    DateTime base,
    int months,
    double Function(DateTime month) resolver,
  ) {
    var total = 0.0;
    for (var i = 0; i < months; i++) {
      total += resolver(_monthOffset(base, i));
    }
    return total;
  }

  // Calcula variacao percentual entre meses.
  _Variation _buildVariation(double current, double previous) {
    if (previous.abs() < 0.01) {
      return const _Variation.unavailable();
    }
    final diff = current - previous;
    final percent = (diff / previous.abs()) * 100.0;
    return _Variation.available(diff: diff, percent: percent);
  }

  // Constroi a projecao de saldo para os proximos meses.
  _ForecastData _buildForecast(DateTime start, int months) {
    final appStart = DateTime(2026, 1, 1);
    var base = DateTime(start.year, start.month, 1);
    if (base.isBefore(appStart)) {
      base = appStart;
    }
    final values = <double>[];
    final labels = <DateTime>[];
    var lastSalary = _receitasStore.salaryForMonth(base);
    var lastDespesas = _despesasStore.totalForMonth(base);
    var runningTotal = 0.0;
    for (var i = 0; i < months; i++) {
      final month = DateTime(base.year, base.month + i, 1);
      final salary = _receitasStore.salaryForMonth(month);
      final extras = _receitasStore.extrasTotalForMonth(month);
      final hasSalary = _receitasStore.hasSalaryForMonth(month);
      final receitas = (hasSalary ? salary : lastSalary) + extras;
      final despesas = _despesasStore.totalForMonth(month);
      final effectiveReceitas = receitas == 0 && despesas == 0
          ? lastSalary
          : receitas;
      final effectiveDespesas = receitas == 0 && despesas == 0
          ? lastDespesas
          : despesas;
      if (hasSalary && salary != 0) {
        lastSalary = salary;
      } else if (!hasSalary && receitas != 0) {
        lastSalary = receitas - extras;
      }
      if (despesas != 0) {
        lastDespesas = despesas;
      }
      runningTotal += effectiveReceitas + effectiveDespesas;
      values.add(runningTotal);
      labels.add(month);
    }
    return _ForecastData(values: values, months: labels);
  }

  // Abre a tela de configuracoes.
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          categoriesStore: _categoriesStore,
          receitasStore: _receitasStore,
          despesasStore: _despesasStore,
          carteiraStore: _carteiraStore,
        ),
      ),
    );
  }

  // Atualiza todos os dados do dashboard.
  Future<void> _refreshAll() async {
    await Future.wait([
      _receitasStore.load(),
      _despesasStore.load(),
      _carteiraStore.load(),
      _categoriesStore.load(),
    ]);
  }

  // Desloga o usuario atual.
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

// Modelo interno com dados de projecao.
class _ForecastData {
  final List<double> values;
  final List<DateTime> months;

  const _ForecastData({required this.values, required this.months});
}

// Periodos disponiveis para filtros de saldo.
enum DashboardPeriod {
  month(1, 'Mes atual'),
  quarter(3, 'Ultimos 3 meses'),
  year(12, 'Ultimos 12 meses');

  const DashboardPeriod(this.months, this.label);

  final int months;
  final String label;
}

// Conjunto de chips para selecionar periodo.
class _PeriodChips extends StatelessWidget {
  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onSelected;

  const _PeriodChips({required this.selected, required this.onSelected});

  @override
  // Monta os chips de periodo.
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DashboardPeriod.values.map((period) {
        return _PeriodChip(
          label: period.label,
          isSelected: period == selected,
          onTap: () => onSelected(period),
        );
      }).toList(),
    );
  }
}

// Chip individual de periodo.
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  // Monta o chip individual.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        tokens.primary.withValues(alpha: 0.5),
        tokens.secondary.withValues(alpha: 0.35),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? tokens.background.withValues(alpha: 0.0)
              : tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? tokens.borderStrong : tokens.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// Card principal de saldo e variacao.
class _HeroSaldoCard extends StatelessWidget {
  final double saldoAtual;
  final double saldoPeriodo;
  final String periodLabel;
  final _Variation variation;
  final NumberFormat formatter;

  const _HeroSaldoCard({
    required this.saldoAtual,
    required this.saldoPeriodo,
    required this.periodLabel,
    required this.variation,
    required this.formatter,
  });

  @override
  // Monta o card de saldo principal.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final variationColor = variation.isPositive
        ? tokens.success
        : tokens.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.primary.withValues(alpha: 0.35),
            tokens.secondary.withValues(alpha: 0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Saldo atual',
                style: TextStyle(color: tokens.textMuted, fontSize: 12),
              ),
              const Spacer(),
              if (variation.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: variationColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    variation.label,
                    style: TextStyle(
                      color: variationColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatter.format(saldoAtual),
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(periodLabel, style: TextStyle(color: tokens.textSecondary)),
              const Spacer(),
              Text(
                formatter.format(saldoPeriodo),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Representa variacao percentual do saldo.
class _Variation {
  final double diff;
  final double percent;
  final bool isAvailable;

  const _Variation._({
    required this.diff,
    required this.percent,
    required this.isAvailable,
  });

  const _Variation.unavailable()
    : this._(diff: 0, percent: 0, isAvailable: false);

  const _Variation.available({required this.diff, required this.percent})
    : isAvailable = true;

  // Indica se a variacao e positiva.
  bool get isPositive => diff >= 0;

  // Gera o label formatado da variacao.
  String get label {
    if (!isAvailable) return '--';
    final sign = diff >= 0 ? '+' : '-';
    return '$sign${percent.abs().toStringAsFixed(1)}%';
  }
}

// Card com grafico de projecao de saldo.
class _ForecastCard extends StatelessWidget {
  final int months;
  final List<double> values;
  final List<String> monthLabels;
  final NumberFormat formatter;
  final ValueChanged<int> onChanged;

  const _ForecastCard({
    required this.months,
    required this.values,
    required this.monthLabels,
    required this.formatter,
    required this.onChanged,
  });

  @override
  // Monta o card de projecao e slider.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    if (values.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border),
        ),
        child: Text(
          'Sem dados para projecao.',
          style: TextStyle(color: tokens.textSecondary),
        ),
      );
    }
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final min = minValue < 0 ? minValue : 0.0;
    final max = maxValue > 0 ? maxValue : 0.0;
    final latest = values.isNotEmpty ? values.last : 0.0;
    final average = values.isNotEmpty
        ? values.reduce((a, b) => a + b) / values.length
        : 0.0;
    final trendUp = average >= 0;
    final trendLabel = trendUp ? 'Saldo positivo' : 'Saldo negativo';
    final trendColor = trendUp ? tokens.success : tokens.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Projeção Futura',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                formatter.format(latest),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: trendColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                trendLabel,
                style: TextStyle(
                  color: trendColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatter.format(average.abs()),
                style: TextStyle(color: tokens.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _ForecastChartPainter(
                values: values,
                min: min,
                max: max,
                color: trendColor,
                axisColor: tokens.border,
                labelColor: tokens.textMuted,
                labelFormatter: formatter,
              ),
            ),
          ),
          if (monthLabels.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  monthLabels.first,
                  style: TextStyle(color: tokens.textMuted, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  monthLabels.last,
                  style: TextStyle(color: tokens.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Meses: $months',
                style: TextStyle(color: tokens.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: months.toDouble(),
                  min: 3,
                  max: 24,
                  divisions: 7,
                  onChanged: (value) => onChanged(value.round()),
                  activeColor: tokens.accent,
                  inactiveColor: tokens.border,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Painter do grafico de projecao.
class _ForecastChartPainter extends CustomPainter {
  final List<double> values;
  final double min;
  final double max;
  final Color color;
  final Color axisColor;
  final Color labelColor;
  final NumberFormat labelFormatter;

  _ForecastChartPainter({
    required this.values,
    required this.min,
    required this.max,
    required this.color,
    required this.axisColor,
    required this.labelColor,
    required this.labelFormatter,
  });

  @override
  // Desenha o grafico de linha com pontos.
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    final range = (max - min).abs() < 0.01 ? 0.0 : (max - min);
    final hasZero = min < 0 && max > 0;
    final axisY = hasZero && range != 0.0
        ? size.height - (((0 - min) / range) * (size.height - 16)) - 8
        : size.height - 8;
    canvas.drawLine(Offset(0, axisY), Offset(size.width, axisY), axisPaint);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = range == 0.0
          ? size.height / 2
          : size.height -
                (((values[i] - min) / range) * (size.height - 16)) -
                8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = range == 0.0
          ? size.height / 2
          : size.height -
                (((values[i] - min) / range) * (size.height - 16)) -
                8;
      canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
    }

    if (values.length >= 2) {
      final labelStyle = TextStyle(
        color: labelColor,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      );
      _drawPointLabel(canvas, size, 0, values.first, range, labelStyle);
      _drawPointLabel(
        canvas,
        size,
        values.length - 1,
        values.last,
        range,
        labelStyle,
      );
    }
  }

  @override
  // Controla o repaint do grafico.
  bool shouldRepaint(covariant _ForecastChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.color != color;
  }

  // Desenha label de valores no grafico.
  void _drawPointLabel(
    Canvas canvas,
    Size size,
    int index,
    double value,
    double range,
    TextStyle style,
  ) {
    final x = (index / (values.length - 1)) * size.width;
    final y = range == 0.0
        ? size.height / 2
        : size.height - (((value - min) / range) * (size.height - 16)) - 8;
    final text = labelFormatter.format(value);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final dx = (x - painter.width / 2).clamp(0.0, size.width - painter.width);
    final dy = (y - painter.height - 6).clamp(
      0.0,
      size.height - painter.height,
    );
    painter.paint(canvas, Offset(dx, dy));
  }
}
