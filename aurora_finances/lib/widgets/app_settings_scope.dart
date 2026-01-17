import 'package:flutter/widgets.dart';

import '../data/settings_store.dart';

class AppSettingsScope extends InheritedNotifier<AppSettingsStore> {
  const AppSettingsScope({
    super.key,
    required AppSettingsStore settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettingsStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in widget tree.');
    return scope!.notifier!;
  }
}
