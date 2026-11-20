import 'package:flutter/services.dart';
import 'leads_management_view.dart';
import 'deployments_management_view.dart';
import 'id_requests_management_view.dart';
import 'package:flutter/material.dart';
import 'responsive_helpers.dart';
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

  
  Widget _buildRoleBadge(String role) {
    Color color;
    Color bg;
    IconData icon;
    String label = role;

    switch (role) {
      case 'Agent Manager':
        color = const Color(0xFFFFB703);
        bg = const Color(0xFFFFB703).withValues(alpha: 0.18);
        icon = Icons.military_tech_rounded;
        label = 'Agent Manager 👑';
        break;
      case 'Sales & Setup Agent':
        color = const Color(0xFF2EC4B6);
        bg = const Color(0xFF2EC4B6).withValues(alpha: 0.15);
        icon = Icons.build_circle_outlined;
        break;
      case 'Sales Agent':
        color = const Color(0xFF6C63FF);
        bg = const Color(0xFF6C63FF).withValues(alpha: 0.15);
        icon = Icons.assignment_ind_outlined;
        break;
      case 'Trainee Agent':
      default:
        color = Colors.white60;
        bg = Colors.white.withValues(alpha: 0.08);
        icon = Icons.school_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
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

  void _showChangeRoleDialog(BuildContext context, RegisteredAgentModel agent) {
    String selectedRole = agent.role;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: const Color(0xFF252538),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFFFFB703), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Change Agent Role',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${agent.name} (${agent.displayId})',
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
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
                    const SizedBox(height: 12),
                    const Text(
                      'Select an authorized role to assign to this agent:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    // Role Option: Agent Manager (EXCLUSIVE)
                    _roleSelectionCard(
                      title: 'Agent Manager 👑 (AuraAxon Admin Exclusive)',
                      description: 'Full supervisory authority over agents, deployments, leads, and operational oversight.',
                      roleValue: 'Agent Manager',
                      selectedRole: selectedRole,
                      accentColor: const Color(0xFFFFB703),
                      icon: Icons.military_tech_rounded,
                      isExclusive: true,
                      onTap: () => setModalState(() => selectedRole = 'Agent Manager'),
                    ),
                    const SizedBox(height: 8),

                    // Role Option: Sales & Setup Agent
                    _roleSelectionCard(
                      title: 'Sales & Setup Agent (Level 2 Master)',
                      description: 'Authorized for hardware integrations, POS printers, cash drawers & on-site deployments.',
                      roleValue: 'Sales & Setup Agent',
                      selectedRole: selectedRole,
                      accentColor: const Color(0xFF2EC4B6),
                      icon: Icons.build_circle_outlined,
                      onTap: () => setModalState(() => selectedRole = 'Sales & Setup Agent'),
                    ),
                    const SizedBox(height: 8),

                    // Role Option: Sales Agent
                    _roleSelectionCard(
                      title: 'Sales Agent (Level 1 Certified)',
                      description: 'Authorized for sales lead pipelines, client demos, quotations & commission accrual.',
                      roleValue: 'Sales Agent',
                      selectedRole: selectedRole,
                      accentColor: const Color(0xFF6C63FF),
                      icon: Icons.assignment_ind_outlined,
                      onTap: () => setModalState(() => selectedRole = 'Sales Agent'),
                    ),
                    const SizedBox(height: 8),

                    // Role Option: Trainee Agent
                    _roleSelectionCard(
                      title: 'Trainee Agent',
                      description: 'Introductory level enrolled in Learn & Earn interactive certification chat.',
                      roleValue: 'Trainee Agent',
                      selectedRole: selectedRole,
                      accentColor: Colors.white60,
                      icon: Icons.school_outlined,
                      onTap: () => setModalState(() => selectedRole = 'Trainee Agent'),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: selectedRole == agent.role
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  await AuraAgentFirebaseService.updateAgentRole(agent.id, selectedRole);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Agent role updated to $selectedRole successfully!'),
                                        backgroundColor: selectedRole == 'Agent Manager'
                                            ? const Color(0xFFFFB703)
                                            : const Color(0xFF2EC4B6),
                                      ),
                                    );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: selectedRole == 'Agent Manager'
                                ? const Color(0xFFFFB703)
                                : const Color(0xFF2EC4B6),
                            foregroundColor: selectedRole == 'Agent Manager' ? Colors.black : Colors.white,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Save Role Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
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

  Widget _roleSelectionCard({
    required String title,
    required String description,
    required String roleValue,
    required String selectedRole,
    required Color accentColor,
    required IconData icon,
    bool isExclusive = false,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedRole == roleValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? accentColor : Colors.white54, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? accentColor : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (isExclusive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB703).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN ONLY',
                            style: TextStyle(color: Color(0xFFFFB703), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? accentColor : Colors.white38, width: 2),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: isExclusive ? Colors.black : Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
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
        String currentRole = agent.role;
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
                                          content: Text('Agent ID ${agent.displayId} copied!'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
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
                    if (agent.hasCoordinates) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF00B4D8)),
                            const SizedBox(width: 8),
                            const Text(
                              'Registration GPS: ',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                agent.coordinatesDisplay,
                                style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final uri = Uri.parse(agent.mapsUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF00B4D8)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_outlined, size: 13, color: Color(0xFF00B4D8)),
                                    SizedBox(width: 4),
                                    Text('Google Maps', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (agent.nic.isNotEmpty) ...[
                      _detailRow(Icons.badge_outlined, 'National ID (NIC)', agent.nic),
                      const SizedBox(height: 10),
                    ],
                    _detailRow(Icons.phone_outlined, 'Phone', agent.phone),
                    const SizedBox(height: 10),
                    _detailRow(Icons.email_outlined, 'Email', agent.email),
                    const SizedBox(height: 10),
                    _detailRow(Icons.calendar_today_outlined, 'Registered At', createdStr),
                    if (agent.bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _detailRow(Icons.notes_outlined, 'Bio / Profile', agent.bio),
                    ],

                    // Pending ID Change Request Banner inside detail dialog
                    if (agent.hasPendingIdRequest) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB703).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions, size: 20, color: Color(0xFFFFB703)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pending ID Change Request',
                                    style: TextStyle(color: Color(0xFFFFB703), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Requested: ${agent.pendingRequestedId ?? ""} (Check ID Requests tab)',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 14),

                    
                    // Assign Agent Role row
                    Row(
                      children: [
                        const Icon(Icons.manage_accounts_outlined, size: 16, color: Color(0xFFFFB703)),
                        const SizedBox(width: 8),
                        const Text(
                          'Assign Role:',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2C),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: currentRole == 'Agent Manager' ? const Color(0xFFFFB703) : Colors.white12,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentRole,
                              dropdownColor: const Color(0xFF1E1E2C),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              items: const [
                                DropdownMenuItem(value: 'Trainee Agent', child: Text('Trainee Agent')),
                                DropdownMenuItem(value: 'Sales Agent', child: Text('Sales Agent')),
                                DropdownMenuItem(value: 'Sales & Setup Agent', child: Text('Sales & Setup Agent')),
                                DropdownMenuItem(
                                  value: 'Agent Manager',
                                  child: Text('Agent Manager 👑 (Admin)', style: TextStyle(color: Color(0xFFFFB703), fontWeight: FontWeight.bold)),
                                ),
                              ],
                              onChanged: (newVal) async {
                                if (newVal != null && newVal != currentRole) {
                                  setDialogState(() => currentRole = newVal);
                                  await AuraAgentFirebaseService.updateAgentRole(agent.id, newVal);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Agent role updated to $newVal successfully!'),
                                        backgroundColor: newVal == 'Agent Manager' ? const Color(0xFFFFB703) : const Color(0xFF6C63FF),
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
                    if (currentRole == 'Agent Manager') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB703).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFFFB703), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AuraAxon Operations Exclusive: "Agent Manager" role can only be assigned by AuraAxon Admin and grants managerial level privileges.',
                                style: TextStyle(color: Color(0xFFFFB703), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
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
                        if (currentStatus == 'Pending Verification') ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              setDialogState(() => currentStatus = 'Active');
                              await AuraAgentFirebaseService.updateAgentStatus(agent.id, 'Active');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${agent.name} approved & activated!'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Approve & Activate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
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
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDeleteAgent(context, agent);
                          },
                          icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF476F)),
                          label: const Text('Delete Agent', style: TextStyle(color: Color(0xFFEF476F), fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF476F)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
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

  void _confirmDeleteAgent(BuildContext context, RegisteredAgentModel agent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF476F).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF476F), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Agent',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete agent "${agent.name}" (${agent.displayId})? This will remove the agent and all their pending requests from the system.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuraAgentFirebaseService.deleteAgent(agent.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Agent "${agent.name}" deleted successfully.'),
                    backgroundColor: const Color(0xFFEF476F),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete Agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF476F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
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

  Tab _mobileTab(IconData icon, String text) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildMobileAgentCard(BuildContext context, RegisteredAgentModel agent) {
    final isSetupAgent = agent.role == 'Sales & Setup Agent';
    final accent = isSetupAgent ? const Color(0xFF2EC4B6) : const Color(0xFF6C63FF);
    final hasPhone = agent.phone.isNotEmpty && agent.phone != 'No phone';

    Widget infoRow(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              Icon(icon, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
              ),
            ],
          ),
        );

    return InkWell(
      onTap: () => _showAgentDetails(context, agent),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  child: Icon(
                    isSetupAgent ? Icons.build_circle_outlined : Icons.person_outline,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Agent ID: ${agent.displayId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildRoleBadge(agent.role),
                _buildStatusBadge(agent.status),
                if (agent.displayPin.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                if (agent.hasPendingIdRequest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB703).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'ID REQ: ${agent.pendingRequestedId ?? ""}',
                      style: const TextStyle(color: Color(0xFFFFB703), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            if (agent.nic.isNotEmpty) infoRow(Icons.badge_outlined, 'NIC: ${agent.nic}'),
            infoRow(Icons.location_on_outlined, agent.territory),
            infoRow(Icons.phone_outlined, agent.phone),
            infoRow(Icons.email_outlined, agent.email),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (agent.status == 'Pending Verification') ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      await AuraAgentFirebaseService.updateAgentStatus(agent.id, 'Active');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${agent.name} approved & activated!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('Approve & Activate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (hasPhone) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.phone_outlined, color: Color(0xFF00B4D8), size: 20),
                    tooltip: 'Call Agent',
                    onPressed: () => _launchCall(agent.phone),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 20),
                    tooltip: 'WhatsApp',
                    onPressed: () => _launchWhatsApp(agent.phone, agent.name),
                  ),
                ],
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.manage_accounts_outlined, color: Color(0xFFFFB703), size: 20),
                  tooltip: 'Assign / Change Role',
                  onPressed: () => _showChangeRoleDialog(context, agent),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF476F), size: 20),
                  tooltip: 'Delete Agent',
                  onPressed: () => _confirmDeleteAgent(context, agent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAgentsTabContent(AsyncValue<List<RegisteredAgentModel>> agentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrics Summary Cards
        agentsAsync.maybeWhen(
          data: (agents) {
            final total = agents.length;
            final salesAgents = agents.where((a) => a.role == 'Sales Agent').length;
            final setupAgents = agents.where((a) => a.role == 'Sales & Setup Agent').length;
            final activeAgents = agents.where((a) => a.status.toLowerCase() == 'active').length;

            return ResponsiveMetricRow(
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
        ResponsiveFilterBar(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by agent ID, security PIN, name, email, phone, or territory...',
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
                  isExpanded: isMobileLayout(context),
                  value: _selectedRoleFilter,
                  dropdownColor: const Color(0xFF252538),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Roles')),
                    DropdownMenuItem(value: 'Agent Manager', child: Text('Agent Manager 👑')),
                    DropdownMenuItem(value: 'Sales & Setup Agent', child: Text('Sales & Setup Agent')),
                    DropdownMenuItem(value: 'Sales Agent', child: Text('Sales Agent')),
                    DropdownMenuItem(value: 'Trainee Agent', child: Text('Trainee Agent')),
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
                  isExpanded: isMobileLayout(context),
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
                    agent.displayId.toLowerCase().contains(_searchQuery) ||
                    agent.displayPin.contains(_searchQuery);

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

                      if (isMobileLayout(context)) return _buildMobileAgentCard(context, agent);
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
                            _buildRoleBadge(agent.role),
                            const SizedBox(width: 8),
                            _buildStatusBadge(agent.status),
                            if (agent.hasPendingIdRequest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB703).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.pending_actions, size: 11, color: Color(0xFFFFB703)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ID REQ: ${agent.pendingRequestedId ?? ""}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFB703),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                              if (agent.nic.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF38BDF8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'NIC: ${agent.nic}',
                                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600),
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
                            if (agent.status == 'Pending Verification') ...[
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await AuraAgentFirebaseService.updateAgentStatus(agent.id, 'Active');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${agent.name} approved & activated!'),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 15),
                                label: const Text('Approve & Activate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
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
                            IconButton(
                                icon: const Icon(Icons.manage_accounts_outlined, color: Color(0xFFFFB703), size: 20),
                                tooltip: 'Assign / Change Role',
                                onPressed: () => _showChangeRoleDialog(context, agent),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF476F), size: 20),
                                tooltip: 'Delete Agent',
                                onPressed: () => _confirmDeleteAgent(context, agent),
                              ),
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
    final pendingIdCount = ref.watch(pendingIdRequestsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: DefaultTabController(
        length: 4,
        child: Padding(
          padding: EdgeInsets.all(isMobileLayout(context) ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobileLayout(context) ? 8 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups_outlined,
                      color: const Color(0xFF6C63FF),
                      size: isMobileLayout(context) ? 22 : 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aura Agents & Field Operations',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobileLayout(context) ? 17 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isMobileLayout(context)
                              ? 'Roster, ID requests, leads & deployments'
                              : 'Live Roster, ID Requests, Pipeline Leads, and Deployments synced from aura-agent',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobileLayout(context) ? 11 : 13,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'Refresh All Streams',
                    onPressed: () {
                      ref.invalidate(agentsStreamProvider);
                      ref.invalidate(axonLeadsStreamProvider);
                      ref.invalidate(axonSetupsStreamProvider);
                      ref.invalidate(agentIdRequestsStreamProvider);
                    },
                  ),
                ],
              ),              const SizedBox(height: 20),

              // TabBar Navigation
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF252538),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TabBar(
                  isScrollable: isMobileLayout(context),
                  tabAlignment: isMobileLayout(context) ? TabAlignment.start : null,
                  indicator: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    isMobileLayout(context)
                        ? _mobileTab(Icons.people_alt_outlined, 'Agents')
                        : const Tab(
                            icon: Icon(Icons.people_alt_outlined, size: 18),
                            text: 'Registered Agents',
                          ),
                    isMobileLayout(context)
                        ? _mobileTab(Icons.trending_up, 'Leads')
                        : const Tab(
                            icon: Icon(Icons.trending_up, size: 18),
                            text: 'Sales Pipeline & Leads',
                          ),
                    isMobileLayout(context)
                        ? _mobileTab(Icons.rocket_launch_outlined, 'Deployments')
                        : const Tab(
                            icon: Icon(Icons.rocket_launch_outlined, size: 18),
                            text: 'Deployments & Onboarding',
                          ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined, size: 18),
                          const SizedBox(width: 8),
                          const Text('ID Requests'),
                          if (pendingIdCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB703),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingIdCount',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
                    const IdRequestsManagementView(),
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
    return buildMetricCardShared(context, title: title, value: count, icon: icon, color: color);
  }
}
