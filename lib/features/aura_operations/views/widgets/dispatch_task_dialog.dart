import 'package:flutter/material.dart';
import '../../models/bot_agent_model.dart';

class DispatchTaskDialog extends StatefulWidget {
  final List<BotAgent> bots;
  final String? preselectedBotId;
  final Function(String botId, String brief) onDispatch;

  const DispatchTaskDialog({
    super.key,
    required this.bots,
    this.preselectedBotId,
    required this.onDispatch,
  });

  @override
  State<DispatchTaskDialog> createState() => _DispatchTaskDialogState();
}

class _DispatchTaskDialogState extends State<DispatchTaskDialog> {
  late String _selectedBotId;
  final TextEditingController _briefController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedBotId = widget.preselectedBotId ??
        (widget.bots.isNotEmpty ? widget.bots.first.id : '');
  }

  @override
  void dispose() {
    _briefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF252538),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.rocket_launch, color: Color(0xFF6C63FF)),
          SizedBox(width: 10),
          Text(
            'Dispatch Bot Task',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Agent / Lead:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBotId.isNotEmpty ? _selectedBotId : null,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1E2C),
                  items: widget.bots.map((bot) {
                    return DropdownMenuItem<String>(
                      value: bot.id,
                      child: Text(
                        '${bot.name} (${bot.role})',
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedBotId = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Task Brief / Instructions:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _briefController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Build clean responsive UI for SciRoad analytics...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E1E2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
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
          onPressed: _isSubmitting
              ? null
              : () async {
                  final text = _briefController.text.trim();
                  if (text.isEmpty) return;

                  final nav = Navigator.of(context);
                  setState(() => _isSubmitting = true);
                  await widget.onDispatch(_selectedBotId, text);
                  if (mounted) nav.pop();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Dispatch'),
        ),
      ],
    );
  }
}
