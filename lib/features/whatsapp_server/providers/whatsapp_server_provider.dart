import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServerState {
  final bool isRunning;
  final List<String> logs;

  ServerState({this.isRunning = false, this.logs = const []});

  ServerState copyWith({bool? isRunning, List<String>? logs}) {
    return ServerState(
      isRunning: isRunning ?? this.isRunning,
      logs: logs ?? this.logs,
    );
  }
}

class WhatsAppServerNotifier extends StateNotifier<ServerState> {
  WhatsAppServerNotifier() : super(ServerState());

  Process? _process;

  Future<void> startServer() async {
    if (_process != null) return;
    
    // Determine path to whatsapp_backend
    final Directory currentDir = Directory.current;
    final String backendPath = '${currentDir.path}/whatsapp_backend';

    try {
      _addLog('Starting server in $backendPath...');
      _process = await Process.start(
        'dart',
        ['run', 'bin/server.dart'],
        workingDirectory: backendPath,
        runInShell: true,
      );

      state = state.copyWith(isRunning: true);

      _process!.stdout.transform(utf8.decoder).listen((data) {
        _addLog(data.trim());
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        _addLog('[ERROR] ${data.trim()}');
      });

      _process!.exitCode.then((code) {
        _addLog('Server exited with code $code');
        _process = null;
        state = state.copyWith(isRunning: false);
      });
    } catch (e) {
      _addLog('Failed to start server: $e');
    }
  }

  void stopServer() {
    if (_process != null) {
      _addLog('Stopping server...');
      _process!.kill();
      _process = null;
      state = state.copyWith(isRunning: false);
    }
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  void _addLog(String log) {
    if (log.isEmpty) return;
    state = state.copyWith(logs: [...state.logs, log]);
  }
  
  @override
  void dispose() {
    stopServer();
    super.dispose();
  }

  Map<String, String> getEnvConfig() {
    final Directory currentDir = Directory.current;
    final String envPath = '${currentDir.path}/whatsapp_backend/.env';
    final file = File(envPath);
    
    if (!file.existsSync()) return {};

    final Map<String, String> config = {};
    for (var line in file.readAsLinesSync()) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        config[key] = value;
      }
    }
    return config;
  }

  Future<void> saveEnvConfig(Map<String, String> updates) async {
    final Directory currentDir = Directory.current;
    final String envPath = '${currentDir.path}/whatsapp_backend/.env';
    final file = File(envPath);

    List<String> lines = [];
    if (file.existsSync()) {
      lines = await file.readAsLines();
    }

    // Update existing keys
    for (var key in updates.keys) {
      bool found = false;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('$key=')) {
          lines[i] = '$key=${updates[key]}';
          found = true;
          break;
        }
      }
      if (!found) {
        lines.add('$key=${updates[key]}');
      }
    }

    await file.writeAsString(lines.join('\n'));
    _addLog('Configuration saved. Please restart the server to apply changes.');
  }
}

final whatsappServerProvider =
    StateNotifierProvider<WhatsAppServerNotifier, ServerState>(
        (ref) => WhatsAppServerNotifier());
