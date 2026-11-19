import 'package:flutter/material.dart';
import 'responsive_helpers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'agent_id_request_model.dart';
import 'agent_provider.dart';
import 'aura_agent_firebase_service.dart';

class IdRequestsManagementView extends ConsumerStatefulWidget {
  const IdRequestsManagementView({super.key});

  @override
  ConsumerState<IdRequestsManagementView> createState() => _IdRequestsManagementViewState();
}

class _IdRequestsManagementViewState extends ConsumerState<IdRequestsManagementView> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All' | 'pending' | 'approved' | 'rejected'

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'approved':
        color = const Color(0xFF2EC4B6);
        bg = const Color(0xFF2EC4B6).withValues(alpha: 0.15);
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        color = const Color(0xFFEF476F);
        bg = const Color(0xFFEF476F).withValues(alpha: 0.15);
        icon = Icons.cancel_outlined;
        break;
      case 'pending':
      default:
        color = const Color(0xFFFFB703);
        bg = const Color(0xFFFFB703).withValues(alpha: 0.15);
        icon = Icons.hourglass_top_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, AgentIdRequestModel request) {
    final noteController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252538),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EC4B6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_outlined, color: Color(0xFF2EC4B6), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Approve Agent ID Request',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: Colors.white54),
                              const SizedBox(width: 8),
                              const Text('Agent:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              const SizedBox(width: 6),
                              Text(
                                request.agentName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  request.currentAgentId.isNotEmpty ? request.currentAgentId : 'Current ID',
                                  style: const TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(Icons.arrow_forward, color: Color(0xFF2EC4B6), size: 18),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2EC4B6).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2EC4B6)),
                                ),
                                child: Text(
                                  request.requestedAgentId,
                                  style: const TextStyle(
                                    color: Color(0xFF2EC4B6),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (request.reason.isNotEmpty) ...[
                      Text(
                        'Reason provided by Agent:',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '"${request.reason}"',
                          style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const Text(
                      'Admin Note (Optional):',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Verified by Management. Approved.',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF1E1E2C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          await AuraAgentFirebaseService.approveAgentIdRequest(
                            requestId: request.requestId,
                            agentUid: request.agentUid,
                            requestedAgentId: request.requestedAgentId,
                            adminNotes: noteController.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Agent ID "${request.requestedAgentId}" approved for ${request.agentName}!'),
                                backgroundColor: const Color(0xFF2EC4B6),
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Approve & Assign ID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EC4B6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, AgentIdRequestModel request) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                    child: const Icon(Icons.cancel_outlined, color: Color(0xFFEF476F), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Reject ID Change Request',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to reject the ID change request for ${request.agentName} (Requested: ${request.requestedAgentId})?',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Rejection Reason:',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Name prefix mismatch, requested format does not follow policy.',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF1E1E2C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          await AuraAgentFirebaseService.rejectAgentIdRequest(
                            requestId: request.requestId,
                            agentUid: request.agentUid,
                            reason: reasonController.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ID request for ${request.agentName} rejected.'),
                                backgroundColor: const Color(0xFFEF476F),
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.close, size: 16),
                  label: const Text('Confirm Rejection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF476F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteIdRequest(BuildContext context, AgentIdRequestModel request) {
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
                'Delete ID Request',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the ID request from "${request.agentName}" (Requested: ${request.requestedAgentId})? This will also clear any pending request status on their agent profile.',
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
              await AuraAgentFirebaseService.deleteAgentIdRequest(
                requestId: request.requestId,
                agentUid: request.agentUid,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ID request for "${request.agentName}" deleted successfully.'),
                    backgroundColor: const Color(0xFFEF476F),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete Request'),
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

  Widget _buildMobileIdRequestCard(BuildContext context, AgentIdRequestModel req, String createdStr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: req.isPending
              ? const Color(0xFFFFB703).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: Color(0xFF6C63FF), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.agentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      req.agentEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(req.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(createdStr, style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Agent ID', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        req.currentAgentId.isNotEmpty ? req.currentAgentId : 'None',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Color(0xFF6C63FF), size: 18),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Requested Agent ID',
                        style: TextStyle(color: Color(0xFF2EC4B6), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              req.requestedAgentId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF2EC4B6),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: req.requestedAgentId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied requested ID to clipboard!')),
                              );
                            },
                            child: const Icon(Icons.copy, size: 14, color: Colors.white38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (req.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, size: 16, color: Colors.white38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    req.reason,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
          if (req.adminNotes != null && req.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF2EC4B6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Admin Note: ${req.adminNotes}',
                    style: const TextStyle(color: Color(0xFF2EC4B6), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFFEF476F)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Rejection Reason: ${req.rejectionReason}',
                    style: const TextStyle(color: Color(0xFFEF476F), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (req.isPending) ...[
                ElevatedButton.icon(
                  onPressed: () => _showApproveDialog(context, req),
                  icon: const Icon(Icons.check, size: 15),
                  label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EC4B6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, req),
                  icon: const Icon(Icons.close, size: 15, color: Color(0xFFEF476F)),
                  label: const Text('Reject', style: TextStyle(color: Color(0xFFEF476F), fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF476F)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF476F)),
                tooltip: 'Delete Request',
                onPressed: () => _confirmDeleteIdRequest(context, req),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(agentIdRequestsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrics Summary Cards
        requestsAsync.maybeWhen(
          data: (requests) {
            final total = requests.length;
            final pending = requests.where((r) => r.isPending).length;
            final approved = requests.where((r) => r.isApproved).length;
            final rejected = requests.where((r) => r.isRejected).length;

            return ResponsiveMetricRow(
          children: [
            _buildMetricCard(
                  'Total Requests',
                  total.toString(),
                  Icons.badge_outlined,
                  const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  'Pending Review',
                  pending.toString(),
                  Icons.pending_actions,
                  const Color(0xFFFFB703),
                  isAlert: pending > 0,
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  'Approved',
                  approved.toString(),
                  Icons.check_circle_outline,
                  const Color(0xFF2EC4B6),
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  'Rejected',
                  rejected.toString(),
                  Icons.cancel_outlined,
                  const Color(0xFFEF476F),
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
                  hintText: 'Search by agent name, requested ID, current ID, email or reason...',
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
                  value: _statusFilter,
                  dropdownColor: const Color(0xFF252538),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending Approval')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _statusFilter = val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'Refresh Requests',
              onPressed: () => ref.invalidate(agentIdRequestsStreamProvider),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Requests List
        Expanded(
          child: requestsAsync.when(
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
                child: Text('Error loading ID requests: $err', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
            data: (requests) {
              final filtered = requests.where((req) {
                final matchesQuery = _searchQuery.isEmpty ||
                    req.agentName.toLowerCase().contains(_searchQuery) ||
                    req.requestedAgentId.toLowerCase().contains(_searchQuery) ||
                    req.currentAgentId.toLowerCase().contains(_searchQuery) ||
                    req.agentEmail.toLowerCase().contains(_searchQuery) ||
                    req.reason.toLowerCase().contains(_searchQuery);

                final matchesStatus = _statusFilter == 'All' ||
                    req.status.toLowerCase() == _statusFilter.toLowerCase();

                return matchesQuery && matchesStatus;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No agent ID change requests found',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'When an agent submits an ID change request from the AuraAgent app, it will appear here for review.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = filtered[index];
                  final createdStr =
                      '${req.createdAt.year}-${req.createdAt.month.toString().padLeft(2, '0')}-${req.createdAt.day.toString().padLeft(2, '0')} ${req.createdAt.hour.toString().padLeft(2, '0')}:${req.createdAt.minute.toString().padLeft(2, '0')}';

                  if (isMobileLayout(context)) return _buildMobileIdRequestCard(context, req, createdStr);
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252538),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: req.isPending
                            ? const Color(0xFFFFB703).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Header + Status Badge
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              child: const Icon(Icons.person, color: Color(0xFF6C63FF), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        req.agentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _buildStatusBadge(req.status),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${req.agentEmail} | UID: ${req.agentUid}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              createdStr,
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2: ID Transfer Comparison
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2C),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Current Agent ID', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    req.currentAgentId.isNotEmpty ? req.currentAgentId : 'None',
                                    style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(Icons.arrow_forward, color: Color(0xFF6C63FF), size: 20),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Requested Agent ID', style: TextStyle(color: Color(0xFF2EC4B6), fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        req.requestedAgentId,
                                        style: const TextStyle(
                                          color: Color(0xFF2EC4B6),
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: req.requestedAgentId));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Copied requested ID to clipboard!')),
                                          );
                                        },
                                        child: const Icon(Icons.copy, size: 14, color: Colors.white38),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (req.isPending) ...[
                                ElevatedButton.icon(
                                  onPressed: () => _showApproveDialog(context, req),
                                  icon: const Icon(Icons.check, size: 15),
                                  label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2EC4B6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _showRejectDialog(context, req),
                                  icon: const Icon(Icons.close, size: 15, color: Color(0xFFEF476F)),
                                  label: const Text('Reject', style: TextStyle(color: Color(0xFFEF476F), fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFEF476F)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF476F)),
                                tooltip: 'Delete Request',
                                onPressed: () => _confirmDeleteIdRequest(context, req),
                              ),
                            ],
                          ),
                        ),

                        // Row 3: Reason & Review notes
                        if (req.reason.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote, size: 16, color: Colors.white38),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  req.reason,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (req.adminNotes != null && req.adminNotes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF2EC4B6)),
                              const SizedBox(width: 6),
                              Text(
                                'Admin Note: ${req.adminNotes}',
                                style: const TextStyle(color: Color(0xFF2EC4B6), fontSize: 12),
                              ),
                            ],
                          ),
                        ],

                        if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Color(0xFFEF476F)),
                              const SizedBox(width: 6),
                              Text(
                                'Rejection Reason: ${req.rejectionReason}',
                                style: const TextStyle(color: Color(0xFFEF476F), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color, {bool isAlert = false}) {
    return buildMetricCardShared(
      context,
      title: title,
      value: count,
      icon: icon,
      color: color,
      isAlert: isAlert,
    );
  }
}
