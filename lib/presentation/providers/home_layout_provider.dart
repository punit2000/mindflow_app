import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/home_layout.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';

/// Controls the order and visibility of home screen tabs. Any change is
/// persisted so the user's layout survives app restarts.
final homeLayoutProvider = StateNotifierProvider<HomeLayoutNotifier, HomeLayout>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return HomeLayoutNotifier(storage);
});

class HomeLayoutNotifier extends StateNotifier<HomeLayout> {
  final StorageService _storage;

  HomeLayoutNotifier(this._storage) : super(_storage.loadHomeLayout());

  Future<void> _persist(HomeLayout next) async {
    state = next;
    await _storage.saveHomeLayout(next);
  }

  /// Moves a visible tab from [oldIndex] to [newIndex] (ReorderableListView
  /// semantics: when oldIndex < newIndex, newIndex is already decremented).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final order = List<HomeTab>.from(state.order);
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    await _persist(state.copyWith(order: order));
  }

  Future<void> hide(HomeTab tab) async {
    if (!state.hidden.contains(tab)) {
      await _persist(state.copyWith(hidden: [...state.hidden, tab]));
    }
  }

  Future<void> show(HomeTab tab) async {
    if (state.hidden.contains(tab)) {
      await _persist(state.copyWith(hidden: state.hidden.where((t) => t != tab).toList()));
    }
  }

  Future<void> resetToDefault() async {
    await _persist(HomeLayout.defaultLayout());
  }
}