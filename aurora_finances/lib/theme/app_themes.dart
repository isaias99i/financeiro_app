import 'package:flutter/material.dart';

import 'app_tokens.dart';

// Preset de tema com tokens e modo.
class AppThemePreset {
  final String id;
  final String name;
  final Brightness brightness;
  final AppThemeTokens tokens;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.brightness,
    required this.tokens,
  });
}

// Ordem exibida das cores de indicadores.
const List<MetricColorRole> _metricPaletteOrder = [
  MetricColorRole.receitas,
  MetricColorRole.despesas,
  MetricColorRole.saldoMensalPositivo,
  MetricColorRole.saldoMensalNegativo,
  MetricColorRole.saldoAposReservaPositivo,
  MetricColorRole.saldoAtual,
  MetricColorRole.segurancaAno,
  MetricColorRole.fallback,
];

const AppThemePreset _auroraDawn = AppThemePreset(
  id: 'aurora_dawn',
  name: 'Aurora Dawn',
  brightness: Brightness.light,
  tokens: AppThemeTokens(
    background: Color(0xFFF3F7FB),
    backgroundAlt: Color(0xFFE7F0F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F6FB),
    surfaceStrong: Color(0xFFE4EEF6),
    border: Color(0xFFD5E3EF),
    borderStrong: Color(0xFFC2D7E8),
    focus: Color(0xFF3C8FD9),
    textPrimary: Color(0xFF0B1B2B),
    textSecondary: Color(0xFF20384F),
    textMuted: Color(0xFF5A7085),
    primary: Color(0xFF1C8EC9),
    secondary: Color(0xFF1FAF86),
    accent: Color(0xFF3C8FD9),
    success: Color(0xFF1FAF86),
    warning: Color(0xFFE19932),
    danger: Color(0xFFE36A4F),
    info: Color(0xFF2E7AD1),
    shadow: Color(0x220B1B2B),
    heroGradient: [
      Color(0xFFB9E6FF),
      Color(0xFFC6F2E4),
    ],
    panelGradient: [
      Color(0xFFEAF3FB),
      Color(0xFFDFF0F8),
    ],
    backgroundGradient: [
      Color(0xFFF5FAFF),
      Color(0xFFEAF3FB),
      Color(0xFFE3F6F0),
    ],
    glowColors: [
      Color(0xFF7DE6FF),
      Color(0xFF4FF3C7),
      Color(0xFF9BC3FF),
    ],
    glowOpacity: 0.32,
    metricColors: {
      MetricColorRole.receitas: Color(0xFF1FAF86),
      MetricColorRole.despesas: Color(0xFF1C8EC9),
      MetricColorRole.saldoMensalPositivo: Color(0xFFE19932),
      MetricColorRole.saldoMensalNegativo: Color(0xFFE36A4F),
      MetricColorRole.saldoAposReservaPositivo: Color(0xFF3D5BA9),
      MetricColorRole.saldoAposReservaNegativo: Color(0xFFE36A4F),
      MetricColorRole.saldoAtual: Color(0xFF254A6A),
      MetricColorRole.segurancaAno: Color(0xFF2ECC71),
      MetricColorRole.fallback: Color(0xFF8E44AD),
    },
    metricPaletteOrder: _metricPaletteOrder,
  ),
);

const AppThemePreset _auroraMist = AppThemePreset(
  id: 'aurora_mist',
  name: 'Aurora Mist',
  brightness: Brightness.light,
  tokens: AppThemeTokens(
    background: Color(0xFFF6F7FA),
    backgroundAlt: Color(0xFFE9EEF3),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F5F9),
    surfaceStrong: Color(0xFFE6EDF4),
    border: Color(0xFFD6DEE7),
    borderStrong: Color(0xFFC4D1DE),
    focus: Color(0xFF4A9EDC),
    textPrimary: Color(0xFF101E2C),
    textSecondary: Color(0xFF2A3B4F),
    textMuted: Color(0xFF5E6E82),
    primary: Color(0xFF287BBE),
    secondary: Color(0xFF2F9F8D),
    accent: Color(0xFF4A9EDC),
    success: Color(0xFF2F9F8D),
    warning: Color(0xFFDE9A3B),
    danger: Color(0xFFE26F58),
    info: Color(0xFF3B7FD7),
    shadow: Color(0x220B1B2B),
    heroGradient: [
      Color(0xFFC7E1F4),
      Color(0xFFCFF0E8),
    ],
    panelGradient: [
      Color(0xFFEFF3F8),
      Color(0xFFE6EEF6),
    ],
    backgroundGradient: [
      Color(0xFFF8FAFD),
      Color(0xFFEFF5FB),
      Color(0xFFE6F5F0),
    ],
    glowColors: [
      Color(0xFF8ADFFF),
      Color(0xFF5DE7C0),
      Color(0xFFADC7FF),
    ],
    glowOpacity: 0.3,
    metricColors: {
      MetricColorRole.receitas: Color(0xFF2F9F8D),
      MetricColorRole.despesas: Color(0xFF287BBE),
      MetricColorRole.saldoMensalPositivo: Color(0xFFDE9A3B),
      MetricColorRole.saldoMensalNegativo: Color(0xFFE26F58),
      MetricColorRole.saldoAposReservaPositivo: Color(0xFF3C5BAA),
      MetricColorRole.saldoAposReservaNegativo: Color(0xFFE26F58),
      MetricColorRole.saldoAtual: Color(0xFF2C4E68),
      MetricColorRole.segurancaAno: Color(0xFF37C57B),
      MetricColorRole.fallback: Color(0xFF8F5FD2),
    },
    metricPaletteOrder: _metricPaletteOrder,
  ),
);

const AppThemePreset _auroraBloom = AppThemePreset(
  id: 'aurora_bloom',
  name: 'Aurora Bloom',
  brightness: Brightness.light,
  tokens: AppThemeTokens(
    background: Color(0xFFF2F8F6),
    backgroundAlt: Color(0xFFE3F1F0),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F7F7),
    surfaceStrong: Color(0xFFE0EEF0),
    border: Color(0xFFCFDEE3),
    borderStrong: Color(0xFFB7CFD6),
    focus: Color(0xFF4AB3D4),
    textPrimary: Color(0xFF0D2024),
    textSecondary: Color(0xFF224148),
    textMuted: Color(0xFF5B747A),
    primary: Color(0xFF2F8DB6),
    secondary: Color(0xFF2AA982),
    accent: Color(0xFF4AB3D4),
    success: Color(0xFF2AA982),
    warning: Color(0xFFE5A24A),
    danger: Color(0xFFE06D63),
    info: Color(0xFF2F7ED8),
    shadow: Color(0x220C1A1F),
    heroGradient: [
      Color(0xFFC2EDF1),
      Color(0xFFCCF2DE),
    ],
    panelGradient: [
      Color(0xFFEAF5F4),
      Color(0xFFDFF3EE),
    ],
    backgroundGradient: [
      Color(0xFFF4FBFB),
      Color(0xFFEAF5F4),
      Color(0xFFE2F6EE),
    ],
    glowColors: [
      Color(0xFF7DE6FF),
      Color(0xFF5DE7C0),
      Color(0xFF9BC3FF),
    ],
    glowOpacity: 0.3,
    metricColors: {
      MetricColorRole.receitas: Color(0xFF2AA982),
      MetricColorRole.despesas: Color(0xFF2F8DB6),
      MetricColorRole.saldoMensalPositivo: Color(0xFFE5A24A),
      MetricColorRole.saldoMensalNegativo: Color(0xFFE06D63),
      MetricColorRole.saldoAposReservaPositivo: Color(0xFF3D5BA9),
      MetricColorRole.saldoAposReservaNegativo: Color(0xFFE06D63),
      MetricColorRole.saldoAtual: Color(0xFF215B66),
      MetricColorRole.segurancaAno: Color(0xFF2ECC71),
      MetricColorRole.fallback: Color(0xFF8F5FD2),
    },
    metricPaletteOrder: _metricPaletteOrder,
  ),
);

const AppThemePreset _auroraHalo = AppThemePreset(
  id: 'aurora_halo',
  name: 'Aurora Halo',
  brightness: Brightness.light,
  tokens: AppThemeTokens(
    background: Color(0xFFF7F8FB),
    backgroundAlt: Color(0xFFE7ECF5),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F4FA),
    surfaceStrong: Color(0xFFE5EBF6),
    border: Color(0xFFD3DDF0),
    borderStrong: Color(0xFFBDCCE6),
    focus: Color(0xFF6BA8FF),
    textPrimary: Color(0xFF121A2A),
    textSecondary: Color(0xFF2B3A55),
    textMuted: Color(0xFF5C6B84),
    primary: Color(0xFF3B7ED8),
    secondary: Color(0xFF3BAF9A),
    accent: Color(0xFF6BA8FF),
    success: Color(0xFF3BAF9A),
    warning: Color(0xFFE2A043),
    danger: Color(0xFFE07057),
    info: Color(0xFF2F7ED8),
    shadow: Color(0x2210182C),
    heroGradient: [
      Color(0xFFD2E5FF),
      Color(0xFFD0F4E9),
    ],
    panelGradient: [
      Color(0xFFEFF2FA),
      Color(0xFFE5ECF7),
    ],
    backgroundGradient: [
      Color(0xFFF9FAFE),
      Color(0xFFF0F4FB),
      Color(0xFFE7F6F1),
    ],
    glowColors: [
      Color(0xFF9BC3FF),
      Color(0xFF7DE6FF),
      Color(0xFFB2FF7D),
    ],
    glowOpacity: 0.28,
    metricColors: {
      MetricColorRole.receitas: Color(0xFF3BAF9A),
      MetricColorRole.despesas: Color(0xFF3B7ED8),
      MetricColorRole.saldoMensalPositivo: Color(0xFFE2A043),
      MetricColorRole.saldoMensalNegativo: Color(0xFFE07057),
      MetricColorRole.saldoAposReservaPositivo: Color(0xFF3D5BA9),
      MetricColorRole.saldoAposReservaNegativo: Color(0xFFE07057),
      MetricColorRole.saldoAtual: Color(0xFF254A6A),
      MetricColorRole.segurancaAno: Color(0xFF2ECC71),
      MetricColorRole.fallback: Color(0xFF8E44AD),
    },
    metricPaletteOrder: _metricPaletteOrder,
  ),
);

const AppThemePreset _auroraNight = AppThemePreset(
  id: 'aurora_night',
  name: 'Aurora Night',
  brightness: Brightness.dark,
  tokens: AppThemeTokens(
    background: Color(0xFF06141F),
    backgroundAlt: Color(0xFF0B1F2F),
    surface: Color(0xFF0E1E2B),
    surfaceAlt: Color(0xFF122636),
    surfaceStrong: Color(0xFF152B3E),
    border: Color(0xFF20394A),
    borderStrong: Color(0xFF2A4660),
    focus: Color(0xFF9AD7FF),
    textPrimary: Color(0xFFE9F2FA),
    textSecondary: Color(0xFFB6CADB),
    textMuted: Color(0xFF7C95AB),
    primary: Color(0xFF6FC6FF),
    secondary: Color(0xFF53E1B6),
    accent: Color(0xFF9AD7FF),
    success: Color(0xFF53E1B6),
    warning: Color(0xFFF5C16E),
    danger: Color(0xFFFF8D6C),
    info: Color(0xFF6BA8FF),
    shadow: Color(0x66000000),
    heroGradient: [
      Color(0xFF17324B),
      Color(0xFF143A3A),
    ],
    panelGradient: [
      Color(0xFF0F2232),
      Color(0xFF112839),
    ],
    backgroundGradient: [
      Color(0xFF06141F),
      Color(0xFF0B2C36),
      Color(0xFF123E4B),
    ],
    glowColors: [
      Color(0xFF1FE6A8),
      Color(0xFF2AD3FF),
      Color(0xFFB2FF7D),
    ],
    glowOpacity: 0.4,
    metricColors: {
      MetricColorRole.receitas: Color(0xFF53E1B6),
      MetricColorRole.despesas: Color(0xFF6FC6FF),
      MetricColorRole.saldoMensalPositivo: Color(0xFFF5C16E),
      MetricColorRole.saldoMensalNegativo: Color(0xFFFF8D6C),
      MetricColorRole.saldoAposReservaPositivo: Color(0xFF8EA0FF),
      MetricColorRole.saldoAposReservaNegativo: Color(0xFFFF8D6C),
      MetricColorRole.saldoAtual: Color(0xFF5B8BA8),
      MetricColorRole.segurancaAno: Color(0xFF6CFFAE),
      MetricColorRole.fallback: Color(0xFFC08BFF),
    },
    metricPaletteOrder: _metricPaletteOrder,
  ),
);

const AppThemePreset _borealDeep = AppThemePreset(
  id: 'boreal_deep',
  name: 'Boreal Deep',
  brightness: Brightness.dark,
  tokens: AppThemeTokens(
    background: Color(0xFF07111D),
    backgroundAlt: Color(0xFF0A1A2A),
    surface: Color(0xFF0F1B2A),
    surfaceAlt: Color(0xFF122233),
    surfaceStrong: Color(0xFF15283B),
    border: Color(0xFF223448),
    borderStrong: Color(0xFF2A4560),
    focus: Color(0xFF7FD7FF),
    textPrimary: Color(0xFFEAF1F7),
    textSecondary: Color(0xFFB7C8D8),
    textMuted: Color(0xFF7E92A5),
    primary: Color(0xFF58C7FF),
    secondary: Color(0xFF51D9C1),
    accent: Color(0xFF7FD7FF),
    success: Color(0xFF51D9C1),
    warning: Color(0xFFF2B56A),
    danger: Color(0xFFFF8F73),
    info: Color(0xFF6BA8FF),
    shadow: Color(0x66000000),
    heroGradient: [
      Color(0xFF16314A),
      Color(0xFF173942),
    ],
    panelGradient: [
      Color(0xFF0F1F2E),
      Color(0xFF13263A),
    ],
    backgroundGradient: [
      Color(0xFF07111D),
      Color(0xFF0A2B3A),
      Color(0xFF0F3C4F),
    ],
    glowColors: [
      Color(0xFF1FE6A8),
      Color(0xFF2AD3FF),
      Color(0xFFB2FF7D),
    ],
    glowOpacity: 0.38,
    metricColors: {
      MetricColorRole.receitas: Color(0xFF51D9C1),
      MetricColorRole.despesas: Color(0xFF58C7FF),
      MetricColorRole.saldoMensalPositivo: Color(0xFFF2B56A),
      MetricColorRole.saldoMensalNegativo: Color(0xFFFF8F73),
      MetricColorRole.saldoAposReservaPositivo: Color(0xFF8EA0FF),
      MetricColorRole.saldoAposReservaNegativo: Color(0xFFFF8F73),
      MetricColorRole.saldoAtual: Color(0xFF4B90B0),
      MetricColorRole.segurancaAno: Color(0xFF52F4A6),
      MetricColorRole.fallback: Color(0xFFC08BFF),
    },
    metricPaletteOrder: _metricPaletteOrder,
  ),
);

const AppThemePreset _polarVeil = AppThemePreset(
  id: 'polar_veil',
  name: 'Polar Veil',
  brightness: Brightness.dark,
  tokens: AppThemeTokens(
    background: Color(0xFF0C0F1B),
    backgroundAlt: Color(0xFF141726),
    surface: Color(0xFF161A2C),
    surfaceAlt: Color(0xFF1B2033),
    surfaceStrong: Color(0xFF232A3E),
    border: Color(0xFF2B354C),
    borderStrong: Color(0xFF3A4A68),
    focus: Color(0xFFA48BFF),
    textPrimary: Color(0xFFEAF1FF),
    textSecondary: Color(0xFFB8C6E6),
    textMuted: Color(0xFF8592B2),
    primary: Color(0xFF8E7BFF),
    secondary: Color(0xFF4BC3FF),
    accent: Color(0xFFA48BFF),
    success: Color(0xFF52E0B6),
    warning: Color(0xFFF5C16E),
    danger: Color(0xFFFFA657),
    info: Color(0xFF6BA8FF),
    shadow: Color(0x66000000),
    heroGradient: [
      Color(0xFF23284A),
      Color(0xFF1B1C33),
    ],
    panelGradient: [
      Color(0xFF1B2033),
      Color(0xFF20283D),
    ],
    backgroundGradient: [
      Color(0xFF0C0F1B),
      Color(0xFF1B1C33),
      Color(0xFF23284A),
    ],
    glowColors: [
      Color(0xFF8E7BFF),
      Color(0xFF4BC3FF),
      Color(0xFFFFA657),
    ],
    glowOpacity: 0.35,
    metricColors: {
      MetricColorRole.receitas: Color(0xFF4BC3FF),
      MetricColorRole.despesas: Color(0xFF8E7BFF),
      MetricColorRole.saldoMensalPositivo: Color(0xFFF5C16E),
      MetricColorRole.saldoMensalNegativo: Color(0xFFFFA657),
      MetricColorRole.saldoAposReservaPositivo: Color(0xFF7E9CFF),
      MetricColorRole.saldoAposReservaNegativo: Color(0xFFFFA657),
      MetricColorRole.saldoAtual: Color(0xFF5A6C9C),
      MetricColorRole.segurancaAno: Color(0xFF52E0B6),
      MetricColorRole.fallback: Color(0xFFC08BFF),
    },
    metricPaletteOrder: _metricPaletteOrder,
  ),
);

const AppThemePreset _arcticPulse = AppThemePreset(
  id: 'arctic_pulse',
  name: 'Arctic Pulse',
  brightness: Brightness.dark,
  tokens: AppThemeTokens(
    background: Color(0xFF06141A),
    backgroundAlt: Color(0xFF0B2130),
    surface: Color(0xFF0D1E2A),
    surfaceAlt: Color(0xFF112838),
    surfaceStrong: Color(0xFF153146),
    border: Color(0xFF214152),
    borderStrong: Color(0xFF2A5A6D),
    focus: Color(0xFF7DE6FF),
    textPrimary: Color(0xFFE6F4F6),
    textSecondary: Color(0xFFB6D2D9),
    textMuted: Color(0xFF7F9AA4),
    primary: Color(0xFF7DE6FF),
    secondary: Color(0xFF4FF3C7),
    accent: Color(0xFF9BC3FF),
    success: Color(0xFF4FF3C7),
    warning: Color(0xFFF5C16E),
    danger: Color(0xFFFF8D6C),
    info: Color(0xFF6BA8FF),
    shadow: Color(0x66000000),
    heroGradient: [
      Color(0xFF0F2D3C),
      Color(0xFF10383E),
    ],
    panelGradient: [
      Color(0xFF102B3C),
      Color(0xFF123548),
    ],
    backgroundGradient: [
      Color(0xFF06141A),
      Color(0xFF0B2C36),
      Color(0xFF123E4B),
    ],
    glowColors: [
      Color(0xFF7DE6FF),
      Color(0xFF4FF3C7),
      Color(0xFF9BC3FF),
    ],
    glowOpacity: 0.36,
    metricColors: {
      MetricColorRole.receitas: Color(0xFF4FF3C7),
      MetricColorRole.despesas: Color(0xFF7DE6FF),
      MetricColorRole.saldoMensalPositivo: Color(0xFFF5C16E),
      MetricColorRole.saldoMensalNegativo: Color(0xFFFF8D6C),
      MetricColorRole.saldoAposReservaPositivo: Color(0xFF8EA0FF),
      MetricColorRole.saldoAposReservaNegativo: Color(0xFFFF8D6C),
      MetricColorRole.saldoAtual: Color(0xFF5B8BA8),
      MetricColorRole.segurancaAno: Color(0xFF6CFFAE),
      MetricColorRole.fallback: Color(0xFFC08BFF),
    },
    metricPaletteOrder: _metricPaletteOrder,
  ),
);

const List<AppThemePreset> appThemePresets = [
  _auroraDawn,
  _auroraMist,
  _auroraBloom,
  _auroraHalo,
  _auroraNight,
  _borealDeep,
  _polarVeil,
  _arcticPulse,
];

const List<AppThemePreset> lightThemePresets = [
  _auroraDawn,
  _auroraMist,
  _auroraBloom,
  _auroraHalo,
];

const List<AppThemePreset> darkThemePresets = [
  _auroraNight,
  _borealDeep,
  _polarVeil,
  _arcticPulse,
];

// Resolve preset pelo id com fallback.
AppThemePreset themePresetById(String? id) {
  return appThemePresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => _auroraDawn,
  );
}
