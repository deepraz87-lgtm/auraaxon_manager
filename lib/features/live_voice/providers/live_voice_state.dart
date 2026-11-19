enum VoiceConnectionState {
  disconnected,
  connecting,
  connected,
  listening,
  speaking,
  error,
}

class LiveVoiceState {
  final VoiceConnectionState connectionState;
  final String statusMessage;
  final String activeTranscript;
  final List<String> conversationHistory;
  final double inputVolume;
  final String? errorMessage;

  const LiveVoiceState({
    this.connectionState = VoiceConnectionState.disconnected,
    this.statusMessage = 'Tap to Connect',
    this.activeTranscript = '',
    this.conversationHistory = const [],
    this.inputVolume = 0.0,
    this.errorMessage,
  });

  LiveVoiceState copyWith({
    VoiceConnectionState? connectionState,
    String? statusMessage,
    String? activeTranscript,
    List<String>? conversationHistory,
    double? inputVolume,
    String? errorMessage,
  }) {
    return LiveVoiceState(
      connectionState: connectionState ?? this.connectionState,
      statusMessage: statusMessage ?? this.statusMessage,
      activeTranscript: activeTranscript ?? this.activeTranscript,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      inputVolume: inputVolume ?? this.inputVolume,
      errorMessage: errorMessage,
    );
  }
}
