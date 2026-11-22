import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static const int currentBuildNumber = 2;
  static const String currentVersionName = '1.0.1';

  static Future<void> checkForUpdates(BuildContext context, {bool silent = true}) async {
    if (kIsWeb) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_config')
          .doc('app_version')
          .get();

      if (!doc.exists || doc.data() == null) {
        if (!silent && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are using the latest version of AuraAxon Manager.')),
          );
        }
        return;
      }

      final data = doc.data()!;
      final int latestBuildNumber = (data['latest_build_number'] as num?)?.toInt() ?? currentBuildNumber;
      final String latestVersion = (data['latest_version'] ?? currentVersionName).toString();
      final String apkUrl = (data['apk_url'] ?? 'https://auraaxon-manager.web.app/downloads/auraaxon_manager.apk').toString();
      final String changelog = (data['changelog'] ?? 'Bug fixes and performance improvements.').toString();
      final bool forceUpdate = data['force_update'] == true;

      if (latestBuildNumber > currentBuildNumber && context.mounted) {
        _showUpdateDialog(
          context: context,
          latestVersion: latestVersion,
          apkUrl: apkUrl,
          changelog: changelog,
          forceUpdate: forceUpdate,
        );
      } else if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AuraAxon Manager is up to date.')),
        );
      }
    } catch (e) {
      debugPrint('Update check note: $e');
    }
  }

  static void _showUpdateDialog({
    required BuildContext context,
    required String latestVersion,
    required String apkUrl,
    required String changelog,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            backgroundColor: const Color(0xFF252538),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Color(0xFF6C63FF), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Update Available',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('New Version: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v$latestVersion',
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '(Current: v$currentVersionName)',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Updates & Changes:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    changelog,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Later', style: TextStyle(color: Colors.white54)),
                ),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(apkUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
