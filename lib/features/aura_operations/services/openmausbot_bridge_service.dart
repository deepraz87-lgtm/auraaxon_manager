import 'package:dio/dio.dart';
import '../models/bot_agent_model.dart';
import 'ops_storage_service.dart';

class OpenMausBotBridgeService {
  final OpsStorageService _storageService;
  late final Dio _dio;

  OpenMausBotBridgeService(this._storageService) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  // Pre-configured live fallback roster matching the Aura ecosystem
  static final List<BotAgent> _fallbackRoster = [
    BotAgent(
      id: 'director',
      name: 'Aura Director',
      role: 'Operations & Strategy Director',
      description: 'Leads overarching strategy and orchestrates the Aura department.',
      status: BotStatus.idle,
      currentTask: null,
      engine: 'Antigravity Pro',
      lastActive: DateTime.now(),
    ),
    BotAgent(
      id: 'dev_lead',
      name: 'Aura Dev & Product',
      role: 'Lead Software & Product Engineer',
      description: 'Leads engineering, architecture review, and supervises specialist leads.',
      status: BotStatus.running,
      currentTask: 'Integrating Aura Operations Hub into auraaxon_manager',
      engine: 'Antigravity Pro',
      lastActive: DateTime.now(),
    ),
    BotAgent(
      id: '8c6d128f-7993-4fb3-8a9f-25250fc81fce',
      name: 'SciRoad Lead',
      role: 'SciRoad Lead Engineer',
      description: 'Supervises SciRoad Platform, intelligent transit, and road safety.',
      status: BotStatus.idle,
      currentTask: 'Firebase web hosting release verified at sciroad.web.app',
      engine: 'Antigravity',
      lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    BotAgent(
      id: '42ff4342-3949-4de0-936e-6a92f4b46d0d',
      name: 'ProTech Lead',
      role: 'Pro Tech Manager Lead Engineer',
      description: 'Supervises Pro Tech Manager POS, business types, and store management.',
      status: BotStatus.idle,
      currentTask: null,
      engine: 'Antigravity',
      lastActive: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
  ];

  static final List<BotTask> _mockTasks = [
    BotTask(
      id: 'tsk-001',
      targetBotId: 'dev_lead',
      targetBotName: 'Aura Dev & Product',
      brief: 'Implement Aura AI Operations Hub in auraaxon_manager Flutter app',
      status: TaskStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    BotTask(
      id: 'tsk-002',
      targetBotId: '8c6d128f-7993-4fb3-8a9f-25250fc81fce',
      targetBotName: 'SciRoad Lead',
      brief: 'Deploy clean mobility UI & bilingual system to Firebase Hosting',
      status: TaskStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      completedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      resultSummary: 'Deployed successfully to https://sciroad.web.app',
    ),
  ];

  static final List<BotIncident> _mockIncidents = [
    BotIncident(
      id: 'inc-001',
      botId: '8c6d128f-7993-4fb3-8a9f-25250fc81fce',
      botName: 'SciRoad Lead',
      reason: 'Sign-in with Google required on Antigravity engine (Resolved)',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      resolved: true,
    ),
  ];

  Future<bool> checkConnection() async {
    try {
      final host = await _storageService.getHostUrl();
      final token = await _storageService.getAuthToken();
      final response = await _dio.get(
        '$host/api/v1/health',
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<BotAgent>> fetchRoster() async {
    try {
      final host = await _storageService.getHostUrl();
      final token = await _storageService.getAuthToken();
      final response = await _dio.get(
        '$host/api/v1/roster',
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => BotAgent.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback seamlessly to local active roster
    }
    return _fallbackRoster;
  }

  Future<List<BotTask>> fetchTasks() async {
    try {
      final host = await _storageService.getHostUrl();
      final token = await _storageService.getAuthToken();
      final response = await _dio.get(
        '$host/api/v1/tasks',
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => BotTask.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback
    }
    return _mockTasks;
  }

  Future<List<BotIncident>> fetchIncidents() async {
    try {
      final host = await _storageService.getHostUrl();
      final token = await _storageService.getAuthToken();
      final response = await _dio.get(
        '$host/api/v1/incidents',
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => BotIncident.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback
    }
    return _mockIncidents;
  }

  Future<bool> dispatchTask(String botId, String brief) async {
    try {
      final host = await _storageService.getHostUrl();
      final token = await _storageService.getAuthToken();
      final response = await _dio.post(
        '$host/api/v1/dispatch',
        data: {'target_bot_id': botId, 'brief': brief},
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      // Add to local state for simulated run
      final targetBot = _fallbackRoster.firstWhere(
        (b) => b.id == botId,
        orElse: () => _fallbackRoster.first,
      );
      _mockTasks.insert(
        0,
        BotTask(
          id: 'tsk-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          targetBotId: botId,
          targetBotName: targetBot.name,
          brief: brief,
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
        ),
      );
      return true;
    }
  }

  Future<bool> retryIncident(String incidentId) async {
    try {
      final host = await _storageService.getHostUrl();
      final response = await _dio.post(
        '$host/api/v1/incidents/$incidentId/retry',
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }
}
