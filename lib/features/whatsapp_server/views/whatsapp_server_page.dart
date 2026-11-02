import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/whatsapp_server_provider.dart';

class WhatsAppServerPage extends ConsumerWidget {
  const WhatsAppServerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(whatsappServerProvider);
    final notifier = ref.read(whatsappServerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Integration Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configure API Keys',
            onPressed: () => _showConfigDialog(context, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Logs',
            onPressed: notifier.clearLogs,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          serverState.isRunning ? Icons.circle : Icons.circle_outlined,
                          color: serverState.isRunning ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          serverState.isRunning ? 'Server Running' : 'Server Stopped',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!serverState.isRunning)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Server'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: notifier.startServer,
                          ),
                        if (serverState.isRunning)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Server'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: notifier.stopServer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Server Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: serverState.logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      serverState.logs[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Click the Settings icon in the top right to configure API Keys & Database Password.'),
                    Text('2. Configure the WhatsApp Webhook URL to point to this server (e.g., using Ngrok).'),
                    Text('3. Provide the Verify Token configured in the settings to Meta.'),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showConfigDialog(BuildContext context, WhatsAppServerNotifier notifier) async {
    final config = notifier.getEnvConfig();
    final geminiController = TextEditingController(text: config['GEMINI_API_KEY']);
    final whatsappTokenController = TextEditingController(text: config['WHATSAPP_ACCESS_TOKEN']);
    final whatsappPhoneController = TextEditingController(text: config['WHATSAPP_PHONE_NUMBER_ID']);
    final whatsappVerifyController = TextEditingController(text: config['WHATSAPP_VERIFY_TOKEN']);
    final dbPassController = TextEditingController(text: config['DB_PASSWORD']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configure API Keys & Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: geminiController,
                  decoration: const InputDecoration(labelText: 'Gemini API Key'),
                ),
                TextField(
                  controller: whatsappTokenController,
                  decoration: const InputDecoration(labelText: 'WhatsApp Access Token'),
                ),
                TextField(
                  controller: whatsappPhoneController,
                  decoration: const InputDecoration(labelText: 'WhatsApp Phone Number ID'),
                ),
                TextField(
                  controller: whatsappVerifyController,
                  decoration: const InputDecoration(labelText: 'WhatsApp Verify Token'),
                ),
                TextField(
                  controller: dbPassController,
                  decoration: const InputDecoration(labelText: 'Database Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await notifier.saveEnvConfig({
                  'GEMINI_API_KEY': geminiController.text,
                  'WHATSAPP_ACCESS_TOKEN': whatsappTokenController.text,
                  'WHATSAPP_PHONE_NUMBER_ID': whatsappPhoneController.text,
                  'WHATSAPP_VERIFY_TOKEN': whatsappVerifyController.text,
                  'DB_PASSWORD': dbPassController.text,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
