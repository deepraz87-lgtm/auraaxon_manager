import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bot_agent_model.dart';
import '../providers/aura_ops_providers.dart';
import 'widgets/bot_card.dart';
import 'widgets/task_tile.dart';
import 'widgets/bridge_settings_dialog.dart';
import 'widgets/dispatch_task_dialog.dart';

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
          ref.invalidate(bridgeConnectedProvider);
          ref.read(botRosterProvider.notifier).refresh();
          ref.read(botTasksProvider.notifier).refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(botRosterProvider);
    final tasksAsync = ref.watch(botTasksProvider);
    final incidentsAsync = ref.watch(botIncidentsProvider);
    final bridgeConnectedAsync = ref.watch(bridgeConnectedProvider);

    final isBridgeConnected = bridgeConnectedAsync.asData?.value ?? false;

    final bots = rosterAsync.asData?.value ?? [];
    final tasks = tasksAsync.asData?.value ?? [];
    final incidents = incidentsAsync.asData?.value ?? [];

    final activeBotsCount =
        bots.where((b) => b.status == BotStatus.running).length;
    final activeTasksCount =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final unresolvedIncidentsCount =
        incidents.where((i) => !i.resolved).length;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252538),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Text(
              'Aura AI Operations Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Bridge status pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isBridgeConnected
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBridgeConnected ? Colors.green : Colors.amber,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isBridgeConnected ? Colors.greenAccent : Colors.amberAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  isBridgeConnected ? 'Live Bridge' : 'Local Fallback',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isBridgeConnected ? Colors.greenAccent : Colors.amberAccent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Bridge Settings',
            onPressed: _openSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () {
              ref.invalidate(bridgeConnectedProvider);
              ref.read(botRosterProvider.notifier).refresh();
              ref.read(botTasksProvider.notifier).refresh();
              ref.read(botIncidentsProvider.notifier).refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: const Icon(Icons.groups_outlined),
              text: 'Team (${bots.length})',
            ),
            Tab(
              icon: const Icon(Icons.task_alt_outlined),
              text: 'Tasks (${tasks.length})',
            ),
            Tab(
              icon: const Icon(Icons.warning_amber_outlined),
              text: 'Incidents ($unresolvedIncidentsCount)',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDispatchDialog(),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('Dispatch Task'),
      ),
      body: Column(
        children: [
          // KPI Metric Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF252538).withValues(alpha: 0.6),
            child: Row(
              children: [
                _buildKpiCard('Online Bots', '${bots.length}', Icons.smart_toy,
                    const Color(0xFF6C63FF)),
                const SizedBox(width: 8),
                _buildKpiCard('Active Jobs', '$activeTasksCount', Icons.flash_on,
                    Colors.greenAccent),
                const SizedBox(width: 8),
                _buildKpiCard('Running Bots', '$activeBotsCount', Icons.sync,
                    Colors.lightBlueAccent),
                const SizedBox(width: 8),
                _buildKpiCard('Incidents', '$unresolvedIncidentsCount',
                    Icons.report_problem_outlined,
                    unresolvedIncidentsCount > 0 ? Colors.redAccent : Colors.grey),
              ],
            ),
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Team Roster Tab
                rosterAsync.when(
                  data: (botList) => RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(botRosterProvider.notifier).refresh();
                    },
                    child: ListView.builder(
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
                    child: Text('Error loading bots: $err',
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),

                // 2. Tasks Tab
                tasksAsync.when(
                  data: (taskList) => RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(botTasksProvider.notifier).refresh();
                    },
                    child: taskList.isEmpty
                        ? const Center(
                            child: Text(
                              'No recent tasks dispatched.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: taskList.length,
                            itemBuilder: (ctx, idx) =>
                                TaskTile(task: taskList[idx]),
                          ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading tasks: $err',
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
                    child: Text('Error loading incidents: $err',
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
