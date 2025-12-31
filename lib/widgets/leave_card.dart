import 'package:flutter/material.dart';
import '../models/leave_request.dart';

class LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isAdminView;

  const LeaveCard({
    super.key,
    required this.leave,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.isAdminView = false,
  });

  /// Get status color based on leave status
  Color _getStatusColor() {
    switch (leave.status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A); // Green
      case 'rejected':
        return const Color(0xFFDC2626); // Red
      case 'pending':
        return const Color(0xFFFACC15); // Yellow
      default:
        return Colors.grey;
    }
  }

  /// Get status icon
  IconData _getStatusIcon() {
    switch (leave.status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  /// Get leave type badge color
  Color _getLeaveTypeColor() {
    switch (leave.leaveType.toLowerCase()) {
      case 'annual':
        return Colors.blue.withValues(alpha: 0.1);
      case 'compassionate':
        return Colors.purple.withValues(alpha: 0.1);
      case 'sick':
        return Colors.red.withValues(alpha: 0.1);
      case 'personal':
        return Colors.orange.withValues(alpha: 0.1);
      case 'emergency':
        return Colors.red.withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Staff name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.staffName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (isAdminView)
                        Text(
                          'ID: ${leave.staffId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 16,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        leave.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Leave type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getLeaveTypeColor(),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                leave.leaveType,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Date range and days
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Number of days
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${leave.numberOfDays} day${leave.numberOfDays > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reason
            if (leave.reason.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leave.reason,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Admin comment (if present)
            if (leave.adminComment != null && leave.adminComment!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Comment',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      leave.adminComment!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Dates row (applied & approved)
            Row(
              children: [
                Text(
                  'Applied: ${_formatDate(leave.appliedDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (leave.approvedDate != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Approved: ${_formatDate(leave.approvedDate!)}',
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                ],
              ],
            ),

            // Action buttons for admin view
            if (isAdminView && leave.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
