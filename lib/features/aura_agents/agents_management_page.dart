import 'package:flutter/services.dart';
import 'leads_management_view.dart';
import 'deployments_management_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'agent_model.dart';
import 'agent_provider.dart';
import 'aura_agent_firebase_service.dart';

class AgentsManagementPage extends ConsumerStatefulWidget {
  const AgentsManagementPage({super.key});

  @override
  ConsumerState<AgentsManagementPage> createState() => _AgentsManagementPageState();
}

class _AgentsManagementPageState extends ConsumerState<AgentsManagementPage> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  Future<void> _launchWhatsApp(String phone, String name) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '94${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('94')) {
      cleanPhone = '94$cleanPhone';
    }
    final message = Uri.encodeComponent(
        'Hello $name, this is AuraAxon Operations Team regarding your AuraAgent portal account.');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
    }
  }

  Future<void> _launchCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Call launch error: $e');
    }
  }

  Future<void> _launchEmail(String email, String name) async {
    final url = Uri.parse(
        'mailto:$email?subject=${Uri.encodeComponent("AuraAxon Operations - AuraAgent")}&body=${Uri.encodeComponent("Hello $name,\n\n")}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Email launch error: $e');
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;
    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF2EC4B6);
        bg = const Color(0xFF2EC4B6).withValues(alpha: 0.15);
        break;
      case 'pending verification':
      case 'pending':
        color = const Color(0xFFFFB703);
        bg = const Color(0xFFFFB703).withValues(alpha: 0.15);
        break;
      case 'inactive':
      default:
        color = Colors.white54;
        bg = Colors.white.withValues(alpha: 0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAgentDetails(BuildContext context, RegisteredAgentModel agent) {
    showDialog(
      context: context,
      builder: (ctx) {
        String currentStatus = agent.status;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSetupAgent = agent.role == 'Sales & Setup Agent';
            final createdStr = agent.createdAt != null
                ? '${agent.createdAt!.year}-${agent.createdAt!.month.toString().padLeft(2, '0')}-${agent.createdAt!.day.toString().padLeft(2, '0')} ${agent.createdAt!.hour.toString().padLeft(2, '0')}:${agent.createdAt!.minute.toString().padLeft(2, '0')}'
                : 'Not available';

            return Dialog(
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
                          radius: 26,
                          backgroundColor: isSetupAgent
                              ? const Color(0xFF2EC4B6).withValues(alpha: 0.2)
                              : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          child: Icon(
                            isSetupAgent ? Icons.build_circle_outlined : Icons.person_outline,
                            color: isSetupAgent ? const Color(0xFF2EC4B6) : const Color(0xFF6C63FF),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      agent.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: agent.displayId));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Agent ID "${agent.displayId}" copied'),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: const Color(0xFF00B4D8),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00B4D8).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF00B4D8)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            agent.displayId,
                                            style: const TextStyle(
                                              color: Color(0xFF00B4D8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.copy, size: 12, color: Color(0xFF00B4D8)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              SelectableText(
                                'Auth UID: ${agent.id}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
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
                    const SizedBox(height: 14),

                    _detailRow(Icons.badge_outlined, 'Official Agent ID', agent.displayId,
                        badgeColor: const Color(0xFF00B4D8)),
                    const SizedBox(height: 10),
                    if (agent.displayPin.isNotEmpty) ...[
                      _detailRow(Icons.pin_outlined, 'Security PIN', agent.displayPin,
                          badgeColor: const Color(0xFFFFB703)),
                      const SizedBox(height: 10),
                    ],
                    _detailRow(Icons.work_outline, 'Role', agent.role,
                        badgeColor: isSetupAgent ? const Color(0xFF2EC4B6) : const Color(0xFF6C63FF)),
                    const SizedBox(height: 10),
                    _detailRow(Icons.location_on_outlined, 'Territory', agent.territory),
                    const SizedBox(height: 10),
                    _detailRow(Icons.phone_outlined, 'Phone', agent.phone),
                    const SizedBox(height: 10),
                    _detailRow(Icons.email_outlined, 'Email', agent.email),
                    const SizedBox(height: 10),
                    _detailRow(Icons.calendar_today_outlined, 'Registered At', createdStr),
                    if (agent.bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _detailRow(Icons.notes_outlined, 'Bio / Profile', agent.bio),
                    ],

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 14),

                    // Change status row
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 16, color: Colors.white54),
                        const SizedBox(width: 8),
                        const Text(
                          'Update Status:',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2C),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentStatus,
                              dropdownColor: const Color(0xFF1E1E2C),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              items: const [
                                DropdownMenuItem(value: 'Active', child: Text('Active')),
                                DropdownMenuItem(value: 'Pending Verification', child: Text('Pending Verification')),
                                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                              ],
                              onChanged: (newVal) async {
                                if (newVal != null && newVal != currentStatus) {
                                  setDialogState(() => currentStatus = newVal);
                                  await AuraAgentFirebaseService.updateAgentStatus(agent.id, newVal);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Agent status updated to $newVal'),
                                        backgroundColor: const Color(0xFF6C63FF),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (agent.phone.isNotEmpty && agent.phone != 'No phone') ...[
                          OutlinedButton.icon(
                            onPressed: () => _launchCall(agent.phone),
                            icon: const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF00B4D8)),
                            label: const Text('Call', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF00B4D8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _launchWhatsApp(agent.phone, agent.name),
                            icon: const Icon(Icons.chat_outlined, size: 15, color: Colors.white),
                            label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (agent.email.isNotEmpty && agent.email != 'No email') ...[
                          OutlinedButton.icon(
                            onPressed: () => _launchEmail(agent.email, agent.name),
                            icon: const Icon(Icons.email_outlined, size: 15, color: Colors.white70),
                            label: const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? badgeColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Expanded(
          child: badgeColor != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
        ),
      ],
    );
  }

  Widget _buildAgentsTabContent(AsyncValue<List<RegisteredAgentModel>> agentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.groups_outlined,
                            color: Color(0xFF6C63FF),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aura Agents & Field Operations',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Live Roster, Sales Pipeline Opportunities, and Deployments synced from aura-agent',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      tooltip: 'Refresh Agents',
                      onPressed: () => ref.invalidate(agentsStreamProvider),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Summary Cards
            agentsAsync.maybeWhen(
              data: (agents) {
                final total = agents.length;
                final salesAgents = agents.where((a) => a.role == 'Sales Agent').length;
                final setupAgents = agents.where((a) => a.role == 'Sales & Setup Agent').length;
                final activeAgents = agents.where((a) => a.status.toLowerCase() == 'active').length;

                return Row(
                  children: [
                    _buildMetricCard(
                      'Total Agents',
                      total.toString(),
                      Icons.badge_outlined,
                      const Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 16),
                    _buildMetricCard(
                      'Sales Agents',
                      salesAgents.toString(),
                      Icons.trending_up,
                      const Color(0xFF00B4D8),
                    ),
                    const SizedBox(width: 16),
                    _buildMetricCard(
                      'Sales & Setup Agents',
                      setupAgents.toString(),
                      Icons.build_circle_outlined,
                      const Color(0xFF2EC4B6),
                    ),
                    const SizedBox(width: 16),
                    _buildMetricCard(
                      'Active Status',
                      activeAgents.toString(),
                      Icons.check_circle_outline,
                      const Color(0xFFFFB703),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Search & Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by Agent ID, name, email, phone, or territory...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF252538),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.toLowerCase().trim());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252538),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoleFilter,
                      dropdownColor: const Color(0xFF252538),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Roles')),
                        DropdownMenuItem(value: 'Sales Agent', child: Text('Sales Agent')),
                        DropdownMenuItem(value: 'Sales & Setup Agent', child: Text('Sales & Setup Agent')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoleFilter = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252538),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      dropdownColor: const Color(0xFF252538),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Pending Verification', child: Text('Pending Verification')),
                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatusFilter = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data Table / List
            Expanded(
              child: agentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                ),
                error: (err, stack) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Error loading agents: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
                data: (agents) {
                  final filtered = agents.where((agent) {
                    final matchesQuery = _searchQuery.isEmpty ||
                        agent.name.toLowerCase().contains(_searchQuery) ||
                        agent.email.toLowerCase().contains(_searchQuery) ||
                        agent.phone.contains(_searchQuery) ||
                        agent.territory.toLowerCase().contains(_searchQuery) ||
                        agent.agentId.toLowerCase().contains(_searchQuery) ||
                        agent.displayId.toLowerCase().contains(_searchQuery) ||
                        agent.id.toLowerCase().contains(_searchQuery);

                    final matchesRole = _selectedRoleFilter == 'All' || agent.role == _selectedRoleFilter;
                    final matchesStatus = _selectedStatusFilter == 'All' ||
                        agent.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

                    return matchesQuery && matchesRole && matchesStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No registered agents match the criteria',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Agents registered through the AuraAgent portal will appear here in real-time.',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF252538),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final agent = filtered[index];
                          final isSetupAgent = agent.role == 'Sales & Setup Agent';

                          return ListTile(
                            onTap: () => _showAgentDetails(context, agent),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isSetupAgent
                                  ? const Color(0xFF2EC4B6).withValues(alpha: 0.2)
                                  : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              child: Icon(
                                isSetupAgent ? Icons.build_circle_outlined : Icons.person_outline,
                                color: isSetupAgent ? const Color(0xFF2EC4B6) : const Color(0xFF6C63FF),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  agent.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B4D8).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    agent.displayId,
                                    style: const TextStyle(
                                      color: Color(0xFF00B4D8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSetupAgent
                                        ? const Color(0xFF2EC4B6).withValues(alpha: 0.15)
                                        : const Color(0xFF6C63FF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    agent.role,
                                    style: TextStyle(
                                      color: isSetupAgent ? const Color(0xFF2EC4B6) : const Color(0xFF6C63FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(agent.status),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF00B4D8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Agent ID: ${agent.displayId}',
                                        style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      if (agent.displayPin.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            'PIN: ${agent.displayPin}',
                                            style: const TextStyle(color: Color(0xFFFFB703), fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00B4D8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        agent.territory,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 14, color: Colors.white38),
                                      const SizedBox(width: 4),
                                      Text(
                                        agent.phone,
                                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.email_outlined, size: 14, color: Colors.white38),
                                      const SizedBox(width: 4),
                                      Text(
                                        agent.email,
                                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (agent.phone.isNotEmpty && agent.phone != 'No phone') ...[
                                  IconButton(
                                    icon: const Icon(Icons.phone_outlined, color: Color(0xFF00B4D8)),
                                    tooltip: 'Call Agent',
                                    onPressed: () => _launchCall(agent.phone),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                                    tooltip: 'WhatsApp',
                                    onPressed: () => _launchWhatsApp(agent.phone, agent.name),
                                  ),
                                ],
                                const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(agentsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: DefaultTabController(
        length: 3,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.groups_outlined,
                              color: Color(0xFF6C63FF),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aura Agents & Field Operations',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Live Roster, Sales Pipeline Opportunities, and Deployments synced from aura-agent',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        tooltip: 'Refresh All Streams',
                        onPressed: () {
                          ref.invalidate(agentsStreamProvider);
                          ref.invalidate(axonLeadsStreamProvider);
                          ref.invalidate(axonSetupsStreamProvider);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // TabBar Navigation
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF252538),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.people_alt_outlined, size: 18),
                      text: 'Registered Agents',
                    ),
                    Tab(
                      icon: Icon(Icons.trending_up, size: 18),
                      text: 'Sales Pipeline & Leads',
                    ),
                    Tab(
                      icon: Icon(Icons.rocket_launch_outlined, size: 18),
                      text: 'Deployments & Onboarding',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TabBar Views
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAgentsTabContent(agentsAsync),
                    const LeadsManagementView(),
                    const DeploymentsManagementView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252538),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
