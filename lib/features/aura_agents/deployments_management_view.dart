import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'setup_model.dart';
import 'agent_provider.dart';

class DeploymentsManagementView extends ConsumerStatefulWidget {
  const DeploymentsManagementView({super.key});

  @override
  ConsumerState<DeploymentsManagementView> createState() => _DeploymentsManagementViewState();
}

class _DeploymentsManagementViewState extends ConsumerState<DeploymentsManagementView> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  Color _getStatusColor(AxonSetupStatus status) {
    switch (status) {
      case AxonSetupStatus.pending:
        return const Color(0xFFFFB703);
      case AxonSetupStatus.inProgress:
        return const Color(0xFF00B4D8);
      case AxonSetupStatus.completed:
        return const Color(0xFF2EC4B6);
    }
  }

  void _showChecklistDialog(BuildContext context, AxonSetupModel task) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF252538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF2EC4B6).withValues(alpha: 0.2),
                    child: const Icon(Icons.rocket_launch_outlined, color: Color(0xFF2EC4B6), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.companyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          task.targetSoftwareVersion,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              Text(
                'Deployment Checklist (${task.checklist.where((c) => c.isCompleted).length} / ${task.checklist.length} Complete):',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: task.checklist.length,
                  itemBuilder: (context, i) {
                    final item = task.checklist[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: item.isCompleted ? const Color(0xFF2EC4B6) : Colors.white30,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (item.description.isNotEmpty)
                                  Text(
                                    item.description,
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (task.isSignedOff) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2EC4B6).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Color(0xFF2EC4B6), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Client Handover & Digital Sign-off Confirmed',
                            style: TextStyle(color: Color(0xFF2EC4B6), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      if (task.signOffNotes?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Notes: ${task.signOffNotes}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252538),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final setupsAsync = ref.watch(axonSetupsStreamProvider);

    return setupsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2EC4B6)),
      ),
      error: (err, stack) => Center(
        child: Text('Error loading setups: $err', style: const TextStyle(color: Colors.redAccent)),
      ),
      data: (setups) {
        final total = setups.length;
        final inProgress = setups.where((s) => s.status == AxonSetupStatus.inProgress).length;
        final completed = setups.where((s) => s.status == AxonSetupStatus.completed).length;

        var filtered = setups;
        if (_selectedStatusFilter != 'All') {
          filtered = filtered.where((s) => s.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase()).toList();
        }

        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase().trim();
          filtered = filtered.where((s) =>
              s.companyName.toLowerCase().contains(q) ||
              s.targetSoftwareVersion.toLowerCase().contains(q) ||
              s.agentName.toLowerCase().contains(q)).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            Row(
              children: [
                _buildMetricCard('Total Deployments', total.toString(), Icons.rocket_launch_outlined, const Color(0xFF6C63FF)),
                const SizedBox(width: 14),
                _buildMetricCard('In Progress Setups', inProgress.toString(), Icons.engineering_outlined, const Color(0xFF00B4D8)),
                const SizedBox(width: 14),
                _buildMetricCard('Completed & Handed Over', completed.toString(), Icons.verified_outlined, const Color(0xFF2EC4B6)),
              ],
            ),
            const SizedBox(height: 18),

            // Search
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF252538),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by client business, software package, or setup engineer...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF1E1E2C),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        dropdownColor: const Color(0xFF1E1E2C),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                          ...AxonSetupStatus.values.map((s) => DropdownMenuItem(value: s.name, child: Text(s.label))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatusFilter = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Deployments List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 54, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'No setups matching filter.' : 'No active installations/deployments yet.',
                            style: const TextStyle(color: Colors.white38, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final setup = filtered[index];
                        final statusCol = _getStatusColor(setup.status);
                        final completedCount = setup.checklist.where((c) => c.isCompleted).length;
                        final totalItems = setup.checklist.length;
                        final progress = setup.progress;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252538),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: statusCol.withValues(alpha: 0.15),
                                child: Icon(Icons.rocket_launch_outlined, color: statusCol, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      setup.companyName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      setup.targetSoftwareVersion,
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Checklist Progress: $completedCount/$totalItems',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${(progress * 100).toInt()}%)',
                                          style: TextStyle(color: statusCol, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor: Colors.white10,
                                        valueColor: AlwaysStoppedAnimation<Color>(statusCol),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusCol.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusCol.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  setup.status.label,
                                  style: TextStyle(
                                    color: statusCol,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              OutlinedButton.icon(
                                onPressed: () => _showChecklistDialog(context, setup),
                                icon: const Icon(Icons.checklist, size: 16, color: Color(0xFF2EC4B6)),
                                label: const Text('Checklist', style: TextStyle(color: Color(0xFF2EC4B6), fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF2EC4B6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}