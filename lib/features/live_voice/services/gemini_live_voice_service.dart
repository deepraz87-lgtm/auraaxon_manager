import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';

class GeminiLiveVoiceService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  WebSocketChannel? _channel;
  StreamSubscription? _audioStreamSub;
  StreamSubscription? _socketSub;

  void Function(String text)? onTranscriptReceived;
  void Function(String state)? onStateChanged;
  void Function(double volume)? onVolumeChanged;
  void Function(String error)? onError;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect({
    required String apiKey,
    String model = 'models/gemini-2.0-flash-exp',
    String? systemInstruction,
  }) async {
    try {
      if (onStateChanged != null) {
        onStateChanged!('Connecting to Gemini Live API...');
      }
      
      final uri = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=',
      );

      _channel = WebSocketChannel.connect(uri);

      // Send initial setup message
      final setupMessage = {
        'setup': {
          'model': model,
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': 'Puck'
                }
              }
            }
          },
          if (systemInstruction != null)
            'systemInstruction': {
              'parts': [
                {'text': systemInstruction}
              ]
            }
        }
      };

      _channel!.sink.add(jsonEncode(setupMessage));

      _socketSub = _channel!.stream.listen(
        (data) {
          _handleServerMessage(data);
        },
        onError: (err) {
          if (onError != null) {
            onError!('WebSocket error: ');
          }
          disconnect();
        },
        onDone: () {
          disconnect();
        },
      );

      _isConnected = true;
      if (onStateChanged != null) {
        onStateChanged!('Connected. Ready for voice interaction.');
      }

      // Start streaming mic audio
      await _startRecordingAndStreaming();
    } catch (e) {
      if (onError != null) {
        onError!('Connection failed: ');
      }
      disconnect();
    }
  }

  Future<void> _startRecordingAndStreaming() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (onError != null) {
        onError!('Microphone permission denied.');
      }
      return;
    }

    // 16kHz, 16-bit PCM Mono
    const recordConfig = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    final stream = await _audioRecorder.startStream(recordConfig);
    if (onStateChanged != null) {
      onStateChanged!('Listening to your voice...');
    }

    _audioStreamSub = stream.listen((Uint8List chunk) {
      if (!_isConnected || _channel == null) return;

      // Calculate approximate RMS volume for visual wave animation
      _calculateVolume(chunk);

      final base64Audio = base64Encode(chunk);
      final realtimeInput = {
        'realtimeInput': {
          'mediaChunks': [
            {
              'mimeType': 'audio/pcm;rate=16000',
              'data': base64Audio,
            }
          ]
        }
      };

      _channel!.sink.add(jsonEncode(realtimeInput));
    });
  }

  void _calculateVolume(Uint8List chunk) {
    if (chunk.isEmpty) return;
    int sum = 0;
    for (int i = 0; i < chunk.length; i += 2) {
      if (i + 1 < chunk.length) {
        int sample = (chunk[i + 1] << 8) | chunk[i];
        if (sample > 32767) sample -= 65536;
        sum += sample.abs();
      }
    }
    double avg = sum / (chunk.length / 2);
    double normalized = (avg / 5000.0).clamp(0.0, 1.0);
    if (onVolumeChanged != null) {
      onVolumeChanged!(normalized);
    }
  }

  void _handleServerMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String);
      final serverContent = json['serverContent'];
      if (serverContent != null) {
        final modelTurn = serverContent['modelTurn'];
        if (modelTurn != null && modelTurn['parts'] != null) {
          final parts = modelTurn['parts'] as List;
          for (final part in parts) {
            final text = part['text'];
            if (text != null && onTranscriptReceived != null) {
              onTranscriptReceived!(text as String);
            }

            final inlineData = part['inlineData'];
            if (inlineData != null && inlineData['data'] != null) {
              final rawAudio = base64Decode(inlineData['data'] as String);
              _playReceivedPcm(rawAudio);
            }
          }
        }

        if (serverContent['interrupted'] == true) {
          _audioPlayer.stop();
          if (onStateChanged != null) {
            onStateChanged!('Interrupted by user. Listening...');
          }
        }
      }
    } catch (_) {
      // In case message is binary or unformatted
    }
  }

  Future<void> _playReceivedPcm(Uint8List pcmData) async {
    if (onStateChanged != null) {
      onStateChanged!('Aura AI Speaking...');
    }
    // Wrap raw PCM into standard WAV header (16-bit, 24kHz Mono by Gemini)
    final wavBytes = _addWavHeader(pcmData, 24000, 1, 16);
    await _audioPlayer.play(BytesSource(wavBytes));
    _audioPlayer.onPlayerComplete.first.then((_) {
      if (onStateChanged != null) {
        onStateChanged!('Listening...');
      }
    });
  }

  Uint8List _addWavHeader(Uint8List pcmData, int sampleRate, int channels, int bitsPerSample) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final totalDataLen = pcmData.length;
    final totalAudioLen = totalDataLen + 36;

    final header = Uint8List(44);
    final view = ByteData.view(header.buffer);

    // RIFF chunk
    header.setRange(0, 4, 'RIFF'.codeUnits);
    view.setUint32(4, totalAudioLen, Endian.little);
    header.setRange(8, 12, 'WAVE'.codeUnits);

    // fmt sub-chunk
    header.setRange(12, 16, 'fmt '.codeUnits);
    view.setUint32(16, 16, Endian.little); // Subchunk1Size
    view.setUint16(20, 1, Endian.little); // PCM format
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, blockAlign, Endian.little);
    view.setUint16(34, bitsPerSample, Endian.little);

    // data sub-chunk
    header.setRange(36, 40, 'data'.codeUnits);
    view.setUint32(40, totalDataLen, Endian.little);

    final complete = BytesBuilder();
    complete.add(header);
    complete.add(pcmData);
    return complete.toBytes();
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _audioStreamSub?.cancel();
    _audioStreamSub = null;
    await _socketSub?.cancel();
    _socketSub = null;
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    await _channel?.sink.close();
    _channel = null;

    if (onStateChanged != null) {
      onStateChanged!('Disconnected');
    }
  }

  void dispose() {
    disconnect();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
