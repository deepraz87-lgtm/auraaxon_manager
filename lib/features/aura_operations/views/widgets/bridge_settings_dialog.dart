import 'package:flutter/material.dart';
import '../../services/ops_storage_service.dart';

class BridgeSettingsDialog extends StatefulWidget {
  final OpsStorageService storage;
  final VoidCallback onSaved;

  const BridgeSettingsDialog({
    super.key,
    required this.storage,
    required this.onSaved,
  });

  @override
  State<BridgeSettingsDialog> createState() => _BridgeSettingsDialogState();
}

class _BridgeSettingsDialogState extends State<BridgeSettingsDialog> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final host = await widget.storage.getHostUrl();
    final token = await widget.storage.getAuthToken();
    setState(() {
      _hostController.text = host;
      _tokenController.text = token;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF252538),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.settings_ethernet, color: Color(0xFF6C63FF)),
          SizedBox(width: 10),
          Text(
            'Bridge Connection Setup',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gateway / Bridge Host URL:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _hostController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'e.g. http://192.168.1.50:8484 or http://localhost:8484',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: Color(0xFF1E1E2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Security Bearer Token (Optional):',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _tokenController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter API Token if enabled',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: Color(0xFF1E1E2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tip: Use your PC\'s Wi-Fi IP or Tailscale IP when accessing from your mobile phone.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            await widget.storage.setHostUrl(_hostController.text);
            await widget.storage.setAuthToken(_tokenController.text);
            widget.onSaved();
            if (mounted) nav.pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}
