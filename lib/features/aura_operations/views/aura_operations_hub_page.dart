import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bot_agent_model.dart';
import '../providers/aura_ops_providers.dart';
import 'widgets/bot_card.dart';
import 'widgets/task_tile.dart';
import 'widgets/bridge_settings_dialog.dart';
import 'widgets/dispatch_task_dialog.dart';
import '../../live_voice/widgets/live_voice_floating_button.dart';
import '../../live_voice/views/live_voice_session_modal.dart';

class AuraOperationsHubPage extends ConsumerStatefulWidget {
  const AuraOperationsHubPage({super.key});

  @override
  ConsumerState<AuraOperationsHubPage> createState() =>
      _AuraOperationsHubPageState();
}

class _AuraOperationsHubPageState extends ConsumerState<AuraOperationsHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDispatchDialog([String? botId]) {
    final botsAsync = ref.read(botRosterProvider);
    final bots = botsAsync.asData?.value ?? [];

    showDialog(
      context: context,
      builder: (ctx) => DispatchTaskDialog(
        bots: bots,
        preselectedBotId: botId,
        onDispatch: (targetBotId, brief) async {
          final success = await ref
              .read(botTasksProvider.notifier)
              .dispatchTask(targetBotId, brief);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Task dispatched to bot successfully!'
                      : 'Task dispatch failed.',
                ),
                backgroundColor: success ? Colors.green : Colors.redAccent,
              ),
            );
          }
        },
      ),
    );
  }

  void _openSettingsDialog() {
    final storage = ref.read(opsStorageServiceProvider);
    showDialog(
      context: context,
      builder: (ctx) => BridgeSettingsDialog(
        storage: storage,
        onSaved: () {
          ref.read(botRosterProvider.notifier).refresh();
          ref.read(botTasksProvider.notifier).refresh();
          ref.read(botIncidentsProvider.notifier).refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botsAsync = ref.watch(botRosterProvider);
    final tasksAsync = ref.watch(botTasksProvider);
    final incidentsAsync = ref.watch(botIncidentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LiveVoiceFloatingButton(),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'dispatchTaskBtn',
            backgroundColor: const Color(0xFF252538),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_task),
            label: const Text('Dispatch Task'),
            onPressed: () => _openDispatchDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: const Color(0xFF252538),
            child: Row(
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
                      'Aura Operations Hub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Operations Director & Specialist Bot Roster',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => LiveVoiceSessionModal.show(context),
                  icon: const Icon(Icons.record_voice_over, size: 18, color: Color(0xFF6C63FF)),
                  label: const Text('Live Voice', style: TextStyle(color: Color(0xFF6C63FF))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  tooltip: 'Bridge Settings',
                  onPressed: _openSettingsDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Refresh All',
                  onPressed: () {
                    ref.read(botRosterProvider.notifier).refresh();
                    ref.read(botTasksProvider.notifier).refresh();
                    ref.read(botIncidentsProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),

          // Overview Status Bar / KPIs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF202030),
            child: Row(
              children: [
                _buildKpiCard(
                  'Total Bots',
                  botsAsync.asData?.value.length.toString() ?? '-',
                  Icons.smart_toy_outlined,
                  Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  'Active Tasks',
                  tasksAsync.asData?.value
                          .where((t) => t.status == TaskStatus.inProgress)
                          .length
                          .toString() ??
                      '-',
                  Icons.pending_actions,
                  Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  'Incidents',
                  incidentsAsync.asData?.value
                          .where((i) => !i.resolved)
                          .length
                          .toString() ??
                      '-',
                  Icons.warning_amber_outlined,
                  Colors.redAccent,
                ),
              ],
            ),
          ),

          // Navigation Tabs
          Container(
            color: const Color(0xFF252538),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF6C63FF),
              labelColor: const Color(0xFF6C63FF),
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(
                  icon: Icon(Icons.groups_outlined),
                  text: 'Bot Roster',
                ),
                Tab(
                  icon: Icon(Icons.task_alt_outlined),
                  text: 'Tasks & Threads',
                ),
                Tab(
                  icon: Icon(Icons.warning_amber_outlined),
                  text: 'Incidents',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Bot Roster Tab
                botsAsync.when(
                  data: (botList) => RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(botRosterProvider.notifier).refresh();
                    },
                    child: botList.isEmpty
                        ? const Center(
                            child: Text(
                              'No bots registered in roster.\nConfigure Bridge Settings.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: botList.length,
                            itemBuilder: (ctx, idx) {
                              final bot = botList[idx];
                              return BotCard(
                                bot: bot,
                                onAssignTask: () => _openDispatchDialog(bot.id),
                              );
                            },
                          ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading bots: ',
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),

                // 2. Tasks & Threads Tab
                tasksAsync.when(
                  data: (taskList) => RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(botTasksProvider.notifier).refresh();
                    },
                    child: taskList.isEmpty
                        ? const Center(
                            child: Text(
                              'No active tasks found.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: taskList.length,
                            itemBuilder: (ctx, idx) {
                              final task = taskList[idx];
                              return TaskTile(task: task);
                            },
                          ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading tasks: ',
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),

                // 3. Incidents Tab
                incidentsAsync.when(
                  data: (incidentList) => RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(botIncidentsProvider.notifier).refresh();
                    },
                    child: incidentList.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified,
                                    color: Colors.greenAccent, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'All Systems Operational.\nNo active blockers.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: incidentList.length,
                            itemBuilder: (ctx, idx) {
                              final incident = incidentList[idx];
                              return Card(
                                color: const Color(0xFF252538),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: incident.resolved
                                        ? Colors.white10
                                        : Colors.redAccent.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            incident.resolved
                                                ? Icons.check_circle
                                                : Icons.error_outline,
                                            color: incident.resolved
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              incident.botName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          if (incident.resolved)
                                            const Chip(
                                              label: Text('Resolved',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.greenAccent)),
                                              backgroundColor: Color(0xFF1E1E2C),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        incident.reason,
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 13),
                                      ),
                                      if (!incident.resolved) ...[
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              await ref
                                                  .read(botIncidentsProvider.notifier)
                                                  .retryIncident(incident.id);
                                            },
                                            icon: const Icon(Icons.replay,
                                                size: 16),
                                            label: const Text('Resume Thread'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading incidents: ',
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
      String title, String count, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.white54),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

