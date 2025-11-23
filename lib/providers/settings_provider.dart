import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_provider.dart';

final unitsMetricProvider = StateNotifierProvider<UnitsNotifier, bool>((ref) {
  return UnitsNotifier(ref);
});

class UnitsNotifier extends StateNotifier<bool> {
  final Ref ref;

  UnitsNotifier(this.ref) : super(false) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final storage = await ref.read(storageServiceProvider.future);
    state = storage.unitsMetric;
  }

  Future<void> toggle() async {
    state = !state;
    final storage = await ref.read(storageServiceProvider.future);
    await storage.setUnitsMetric(state);
  }
}

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsNotifier extends StateNotifier<bool> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final storage = await ref.read(storageServiceProvider.future);
    state = storage.notificationsEnabled;
  }

  Future<void> toggle() async {
    state = !state;
    final storage = await ref.read(storageServiceProvider.future);
    await storage.setNotificationsEnabled(state);
  }
}

