import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bot_agent_model.dart';
import '../services/ops_storage_service.dart';
import '../services/openmausbot_bridge_service.dart';

final opsStorageServiceProvider = Provider<OpsStorageService>((ref) {
  return OpsStorageService();
});

final bridgeServiceProvider = Provider<OpenMausBotBridgeService>((ref) {
  final storage = ref.watch(opsStorageServiceProvider);
  return OpenMausBotBridgeService(storage);
});

// Bridge health / connection state
final bridgeConnectedProvider = FutureProvider<bool>((ref) async {
  final bridge = ref.watch(bridgeServiceProvider);
  return await bridge.checkConnection();
});

// Roster StateNotifier
class BotRosterNotifier extends StateNotifier<AsyncValue<List<BotAgent>>> {
  final OpenMausBotBridgeService _bridge;

  BotRosterNotifier(this._bridge) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final bots = await _bridge.fetchRoster();
      state = AsyncValue.data(bots);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final botRosterProvider =
    StateNotifierProvider<BotRosterNotifier, AsyncValue<List<BotAgent>>>((ref) {
  final bridge = ref.watch(bridgeServiceProvider);
  return BotRosterNotifier(bridge);
});

// Tasks StateNotifier
class BotTasksNotifier extends StateNotifier<AsyncValue<List<BotTask>>> {
  final OpenMausBotBridgeService _bridge;

  BotTasksNotifier(this._bridge) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final tasks = await _bridge.fetchTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> dispatchTask(String botId, String brief) async {
    final success = await _bridge.dispatchTask(botId, brief);
    await refresh();
    return success;
  }
}

final botTasksProvider =
    StateNotifierProvider<BotTasksNotifier, AsyncValue<List<BotTask>>>((ref) {
  final bridge = ref.watch(bridgeServiceProvider);
  return BotTasksNotifier(bridge);
});

// Incidents StateNotifier
class BotIncidentsNotifier extends StateNotifier<AsyncValue<List<BotIncident>>> {
  final OpenMausBotBridgeService _bridge;

  BotIncidentsNotifier(this._bridge) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final incidents = await _bridge.fetchIncidents();
      state = AsyncValue.data(incidents);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> retryIncident(String id) async {
    await _bridge.retryIncident(id);
    await refresh();
  }
}

final botIncidentsProvider =
    StateNotifierProvider<BotIncidentsNotifier, AsyncValue<List<BotIncident>>>(
        (ref) {
  final bridge = ref.watch(bridgeServiceProvider);
  return BotIncidentsNotifier(bridge);
});
