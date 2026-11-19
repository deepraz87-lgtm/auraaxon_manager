import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/live_voice_provider.dart';
import '../providers/live_voice_state.dart';

class LiveVoiceSessionModal extends ConsumerStatefulWidget {
  const LiveVoiceSessionModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LiveVoiceSessionModal(),
    );
  }

  @override
  ConsumerState<LiveVoiceSessionModal> createState() =>
      _LiveVoiceSessionModalState();
}

class _LiveVoiceSessionModalState extends ConsumerState<LiveVoiceSessionModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showApiKeyInput = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadApiKeyAndConnect();
  }

  Future<void> _loadApiKeyAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_live_api_key') ?? '';
    _apiKeyController.text = savedKey;

    if (savedKey.isNotEmpty) {
      ref.read(liveVoiceNotifierProvider.notifier).startSession(savedKey);
    } else {
      setState(() {
        _showApiKeyInput = true;
      });
    }
  }

  Future<void> _saveApiKeyAndConnect() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_live_api_key', key);
      setState(() {
        _showApiKeyInput = false;
      });
      ref.read(liveVoiceNotifierProvider.notifier).startSession(key);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(liveVoiceNotifierProvider);
    final isConnected = voiceState.connectionState == VoiceConnectionState.listening ||
        voiceState.connectionState == VoiceConnectionState.speaking;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/auraaxon_icon.png',
                        width: 38,
                        height: 38,
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aura Live Voice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Aura Director • Realtime Call',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _showApiKeyInput ? Icons.check : Icons.vpn_key_outlined,
                      color: Colors.white70,
                    ),
                    tooltip: 'Configure Gemini API Key',
                    onPressed: () {
                      if (_showApiKeyInput) {
                        _saveApiKeyAndConnect();
                      } else {
                        setState(() {
                          _showApiKeyInput = true;
                        });
                      }
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              if (_showApiKeyInput) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252538),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gemini API Key for Live Audio:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'AIzaSy...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF1E1E2C),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _saveApiKeyAndConnect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save & Connect'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Central Visualizer
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final waveScale = isConnected
                            ? 1.0 + (voiceState.inputVolume * 0.8) + (_animController.value * 0.15)
                            : 1.0;

                        return Container(
                          width: 140 * waveScale,
                          height: 140 * waveScale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: voiceState.connectionState ==
                                      VoiceConnectionState.speaking
                                  ? [
                                      Colors.cyanAccent.withValues(alpha: 0.8),
                                      const Color(0xFF6C63FF).withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ]
                                  : [
                                      const Color(0xFF6C63FF),
                                      const Color(0xFF252538).withValues(alpha: 0.4),
                                      Colors.transparent,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                                blurRadius: 30 * waveScale,
                                spreadRadius: 10 * waveScale,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              voiceState.connectionState ==
                                      VoiceConnectionState.speaking
                                  ? Icons.volume_up_rounded
                                  : isConnected
                                      ? Icons.mic_rounded
                                      : Icons.mic_off_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Status Indicator
                    Text(
                      voiceState.statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: voiceState.connectionState ==
                                VoiceConnectionState.speaking
                            ? Colors.cyanAccent
                            : isConnected
                                ? Colors.greenAccent
                                : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (voiceState.errorMessage != null)
                      Text(
                        voiceState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),

                    if (voiceState.activeTranscript.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252538),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          voiceState.activeTranscript,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Call Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'micToggle',
                    backgroundColor: isConnected
                        ? Colors.redAccent
                        : const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      if (isConnected) {
                        ref
                            .read(liveVoiceNotifierProvider.notifier)
                            .endSession();
                      } else {
                        ref
                            .read(liveVoiceNotifierProvider.notifier)
                            .startSession(_apiKeyController.text);
                      }
                    },
                    child: Icon(
                      isConnected ? Icons.call_end : Icons.call,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

