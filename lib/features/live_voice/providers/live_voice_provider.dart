import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_live_voice_service.dart';
import 'live_voice_state.dart';

final liveVoiceServiceProvider = Provider<GeminiLiveVoiceService>((ref) {
  final service = GeminiLiveVoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});

final liveVoiceNotifierProvider =
    StateNotifierProvider<LiveVoiceNotifier, LiveVoiceState>((ref) {
  final service = ref.watch(liveVoiceServiceProvider);
  return LiveVoiceNotifier(service);
});

class LiveVoiceNotifier extends StateNotifier<LiveVoiceState> {
  final GeminiLiveVoiceService _service;

  LiveVoiceNotifier(this._service) : super(const LiveVoiceState()) {
    _service.onStateChanged = (status) {
      VoiceConnectionState connState = state.connectionState;
      if (status.contains('Connecting')) {
        connState = VoiceConnectionState.connecting;
      } else if (status.contains('Connected') || status.contains('Listening')) {
        connState = VoiceConnectionState.listening;
      } else if (status.contains('Speaking')) {
        connState = VoiceConnectionState.speaking;
      } else if (status.contains('Disconnected')) {
        connState = VoiceConnectionState.disconnected;
      }

      state = state.copyWith(
        statusMessage: status,
        connectionState: connState,
      );
    };

    _service.onVolumeChanged = (volume) {
      state = state.copyWith(inputVolume: volume);
    };

    _service.onTranscriptReceived = (text) {
      final updatedHistory = List<String>.from(state.conversationHistory);
      if (text.trim().isNotEmpty) {
        updatedHistory.add('Aura: ');
      }
      state = state.copyWith(
        activeTranscript: text,
        conversationHistory: updatedHistory,
      );
    };

    _service.onError = (err) {
      state = state.copyWith(
        connectionState: VoiceConnectionState.error,
        errorMessage: err,
        statusMessage: 'Error occurred',
      );
    };
  }

  Future<void> startSession(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      state = state.copyWith(
        connectionState: VoiceConnectionState.error,
        errorMessage: 'Gemini API Key is missing. Please configure in Settings.',
      );
      return;
    }

    state = state.copyWith(
      connectionState: VoiceConnectionState.connecting,
      errorMessage: null,
      activeTranscript: '',
      conversationHistory: [],
    );

    const systemInstruction = 
      'You are Aura Director, the AI Operations Director & Chief of Staff for AuraAxon. '
      'You are speaking live to Lahiru (Owner). '
      'Speak natural, friendly Sinhala mixed with English technical terms. '
      'Keep your spoken voice answers concise, direct, helpful, and natural.';

    await _service.connect(
      apiKey: apiKey.trim(),
      systemInstruction: systemInstruction,
    );
  }

  Future<void> endSession() async {
    await _service.disconnect();
    state = state.copyWith(
      connectionState: VoiceConnectionState.disconnected,
      statusMessage: 'Session ended. Tap mic to restart.',
      inputVolume: 0.0,
    );
  }
}
