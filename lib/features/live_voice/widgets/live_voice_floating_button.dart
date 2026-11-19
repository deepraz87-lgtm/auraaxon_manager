import 'package:flutter/material.dart';
import '../views/live_voice_session_modal.dart';

class LiveVoiceFloatingButton extends StatelessWidget {
  const LiveVoiceFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'auraLiveVoiceLauncher',
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        tooltip: 'Aura Live Voice Call',
        onPressed: () => LiveVoiceSessionModal.show(context),
        child: const Icon(Icons.record_voice_over, size: 26),
      ),
    );
  }
}
