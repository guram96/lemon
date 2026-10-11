import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_ui/rs_ui.dart';
import 'package:rs_ui_steam/rs_ui_steam.dart';

/// Every component set shipped with the app. Register new looks here.
final availableComponentSetsProvider = Provider<List<RsComponentSet>>(
  (_) => const [SteamComponentSet()],
);

/// The look the user selected. Falls back to the first available set.
final componentSetProvider =
    NotifierProvider<ComponentSetNotifier, RsComponentSet>(
      ComponentSetNotifier.new,
    );

class ComponentSetNotifier extends Notifier<RsComponentSet> {
  @override
  RsComponentSet build() => ref.watch(availableComponentSetsProvider).first;

  void select(String id) {
    final sets = ref.read(availableComponentSetsProvider);
    state = sets.firstWhere((s) => s.id == id, orElse: () => sets.first);
  }
}
