import 'package:flutter/widgets.dart';

import '../data/settings_store.dart';

// Escopo para acessar AppSettingsStore na arvore de widgets.
class AppSettingsScope extends InheritedNotifier<AppSettingsStore> {
  const AppSettingsScope({
    super.key,
    required AppSettingsStore settings,
    required super.child,
  }) : super(notifier: settings);

  // Obtém settings a partir do BuildContext.
  static AppSettingsStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in widget tree.');
    return scope!.notifier!;
  }
}
