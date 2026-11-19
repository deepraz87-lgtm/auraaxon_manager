import 'package:flutter/material.dart';
import 'responsive_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lead_model.dart';
import 'agent_provider.dart';
import 'aura_agent_firebase_service.dart';

class LeadsManagementView extends ConsumerStatefulWidget {
  const LeadsManagementView({super.key});

  @override
  ConsumerState<LeadsManagementView> createState() => _LeadsManagementViewState();
}

class _LeadsManagementViewState extends ConsumerState<LeadsManagementView> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  String _formatLkr(double amount) {
    final str = amount.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return 'LKR $formatted';
  }

  Color _getStatusColor(AxonLeadStatus status) {
    switch (status) {
      case AxonLeadStatus.newLead:
        return const Color(0xFF3B82F6);
      case AxonLeadStatus.demoScheduled:
        return const Color(0xFF8B5CF6);
      case AxonLeadStatus.quotationSent:
        return const Color(0xFFFFB703);
      case AxonLeadStatus.closedWon:
        return const Color(0xFF2EC4B6);
      case AxonLeadStatus.closedLost:
        return const Color(0xFFEF476F);
    }
  }

  Future<void> _launchCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchWhatsApp(String phone, String clientName, String company) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '94${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('94')) {
      cleanPhone = '94$cleanPhone';
    }
    final message = Uri.encodeComponent(
        'Hello $clientName, this is AuraAxon Operations Team regarding your Aura software opportunity for $company.');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showStatusDialog(BuildContext context, AxonLeadModel lead) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252538),
          title: Text(
            'Update Pipeline: ${lead.companyName}',
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AxonLeadStatus.values.map((st) {
              final isSel = lead.status == st;
              return ListTile(
                leading: CircleAvatar(
                  radius: 6,
                  backgroundColor: _getStatusColor(st),
                ),
                title: Text(
                  st.label,
                  style: TextStyle(
                    color: isSel ? const Color(0xFF2EC4B6) : Colors.white70,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSel ? const Icon(Icons.check, color: Color(0xFF2EC4B6)) : null,
                onTap: () async {
                  await AuraAgentFirebaseService.updateLeadStatus(lead.id, st.name);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated "${lead.companyName}" to ${st.label}'),
                        backgroundColor: _getStatusColor(st),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _showLeadDetailsDialog(BuildContext context, AxonLeadModel lead) {
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
                    radius: 24,
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    child: const Icon(Icons.business_rounded, color: Color(0xFF6C63FF), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.companyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Lead ID: ${lead.id}',
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
              const SizedBox(height: 12),
              _detailRow(Icons.person_outline, 'Contact Person', lead.clientName),
              const SizedBox(height: 8),
              _detailRow(Icons.phone_outlined, 'Phone Number', lead.phone),
              if (lead.email.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow(Icons.email_outlined, 'Email', lead.email),
              ],
              const SizedBox(height: 8),
              _detailRow(Icons.location_on_outlined, 'Territory / Region', lead.territory),
              if (lead.hasCoordinates) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF2EC4B6)),
                      const SizedBox(width: 8),
                      const Text(
                        'Verified GPS: ',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          lead.coordinatesDisplay,
                          style: const TextStyle(color: Color(0xFF2EC4B6), fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse(lead.mapsUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2EC4B6)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_outlined, size: 13, color: Color(0xFF2EC4B6)),
                              SizedBox(width: 4),
                              Text('View on Google Maps', style: TextStyle(color: Color(0xFF2EC4B6), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _detailRow(Icons.inventory_2_outlined, 'Software Package', lead.softwarePackage),
              const SizedBox(height: 8),
              _detailRow(Icons.payments_outlined, 'Quoted Price', _formatLkr(lead.quotedPriceLkr),
                  valColor: const Color(0xFF2EC4B6)),
              const SizedBox(height: 8),
              _detailRow(Icons.badge_outlined, 'Registered Agent',
                  lead.agentName.isNotEmpty ? lead.agentName : 'Unassigned Field Agent'),
              if (lead.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Field Notes:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(lead.notes, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _launchCall(lead.phone),
                    icon: const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF00B4D8)),
                    label: const Text('Call Client', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00B4D8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(lead.phone, lead.clientName, lead.companyName),
                    icon: const Icon(Icons.chat_outlined, size: 15, color: Colors.white),
                    label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showStatusDialog(context, lead);
                    },
                    icon: const Icon(Icons.edit_note, size: 16, color: Color(0xFF6C63FF)),
                    label: const Text('Update Status', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteLead(context, lead);
                    },
                    icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF476F)),
                    label: const Text('Delete Lead', style: TextStyle(color: Color(0xFFEF476F), fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF476F)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteLead(BuildContext context, AxonLeadModel lead) {
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
                'Delete Lead',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the sales opportunity for "${lead.companyName}" (${lead.softwarePackage})?',
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
              await AuraAgentFirebaseService.deleteLead(lead.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lead "${lead.companyName}" deleted successfully.'),
                    backgroundColor: const Color(0xFFEF476F),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete Lead'),
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

  Widget _detailRow(IconData icon, String label, String value, {Color? valColor}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white38),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return buildMetricCardShared(
      context,
      title: title,
      value: value,
      icon: icon,
      color: color,
      radius: 14,
      borderColor: Colors.white.withValues(alpha: 0.05),
      iconSize: 22,
      valueSize: 18,
      titleGap: 4,
    );
  }

  Widget _buildMobileLeadCard(BuildContext context, AxonLeadModel lead, Color statusCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusCol.withValues(alpha: 0.15),
                child: Icon(Icons.business_rounded, color: statusCol, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lead.clientName}  \u2022  ${lead.phone}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusCol.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusCol.withValues(alpha: 0.3)),
                ),
                child: Text(
                  lead.status.label,
                  style: TextStyle(color: statusCol, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.softwarePackage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        lead.territory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatLkr(lead.quotedPriceLkr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF2EC4B6), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Agent: ${lead.agentName.isNotEmpty ? lead.agentName : "Field Agent"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF00B4D8)),
                tooltip: 'Call Client',
                onPressed: () => _launchCall(lead.phone),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chat_outlined, size: 20, color: Color(0xFF25D366)),
                tooltip: 'WhatsApp Client',
                onPressed: () => _launchWhatsApp(lead.phone, lead.clientName, lead.companyName),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.info_outline, size: 20, color: Colors.white70),
                tooltip: 'View Details',
                onPressed: () => _showLeadDetailsDialog(context, lead),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF476F)),
                tooltip: 'Delete Lead',
                onPressed: () => _confirmDeleteLead(context, lead),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(axonLeadsStreamProvider);

    return leadsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      ),
      error: (err, stack) => Center(
        child: Text('Error loading leads: $err', style: const TextStyle(color: Colors.redAccent)),
      ),
      data: (leads) {
        final total = leads.length;
        final pipelineVal = leads
            .where((l) =>
                l.status == AxonLeadStatus.newLead ||
                l.status == AxonLeadStatus.demoScheduled ||
                l.status == AxonLeadStatus.quotationSent)
            .fold(0.0, (double sum, AxonLeadModel l) => sum + l.quotedPriceLkr);

        final wonCount = leads.where((l) => l.status == AxonLeadStatus.closedWon).length;
        final wonVal = leads
            .where((l) => l.status == AxonLeadStatus.closedWon)
            .fold(0.0, (double sum, AxonLeadModel l) => sum + l.quotedPriceLkr);

        var filtered = leads;
        if (_selectedStatusFilter != 'All') {
          filtered = filtered.where((l) => l.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase()).toList();
        }

        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase().trim();
          filtered = filtered.where((l) =>
              l.companyName.toLowerCase().contains(q) ||
              l.clientName.toLowerCase().contains(q) ||
              l.phone.contains(q) ||
              l.agentName.toLowerCase().contains(q) ||
              l.territory.toLowerCase().contains(q) ||
              l.softwarePackage.toLowerCase().contains(q)).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Row
            ResponsiveMetricRow(
          children: [
            _buildMetricCard('Total Opportunities', total.toString(), Icons.assignment_outlined, const Color(0xFF6C63FF)),
                const SizedBox(width: 14),
                _buildMetricCard('Active Pipeline Value', _formatLkr(pipelineVal), Icons.trending_up, const Color(0xFFFFB703)),
                const SizedBox(width: 14),
                _buildMetricCard('Won Deals', wonCount.toString(), Icons.check_circle_outline, const Color(0xFF2EC4B6)),
                const SizedBox(width: 14),
                _buildMetricCard('Closed Revenue', _formatLkr(wonVal), Icons.monetization_on_outlined, const Color(0xFF00B4D8)),
              ],
            ),
            const SizedBox(height: 18),

            // Search and Status Filters
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF252538),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ResponsiveFilterBar(
          children: [
            Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by company, client, agent, package or territory...',
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
                        isExpanded: isMobileLayout(context),
                        value: _selectedStatusFilter,
                        dropdownColor: const Color(0xFF1E1E2C),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                          ...AxonLeadStatus.values.map((s) => DropdownMenuItem(value: s.name, child: Text(s.label))),
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

            // Leads Table / Grid
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 54, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'No leads matching filter.' : 'No opportunities recorded yet from field agents.',
                            style: const TextStyle(color: Colors.white38, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final lead = filtered[index];
                        final statusCol = _getStatusColor(lead.status);

                        if (isMobileLayout(context)) return _buildMobileLeadCard(context, lead, statusCol);
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
                                child: Icon(Icons.business_rounded, color: statusCol, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lead.companyName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${lead.clientName}  \u2022  ${lead.phone}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lead.softwarePackage,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      lead.territory,
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatLkr(lead.quotedPriceLkr),
                                      style: const TextStyle(
                                        color: Color(0xFF2EC4B6),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Agent: ${lead.agentName.isNotEmpty ? lead.agentName : "Field Agent"}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusCol.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusCol.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  lead.status.label,
                                  style: TextStyle(
                                    color: statusCol,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF00B4D8)),
                                    tooltip: 'Call Client',
                                    onPressed: () => _launchCall(lead.phone),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat_outlined, size: 18, color: Color(0xFF25D366)),
                                    tooltip: 'WhatsApp Client',
                                    onPressed: () => _launchWhatsApp(lead.phone, lead.clientName, lead.companyName),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, size: 18, color: Colors.white70),
                                    tooltip: 'View Details',
                                    onPressed: () => _showLeadDetailsDialog(context, lead),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF476F)),
                                    tooltip: 'Delete Lead',
                                    onPressed: () => _confirmDeleteLead(context, lead),
                                  ),
                                ],
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