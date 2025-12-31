import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequest {
  final String? id;
  final String staffId;
  final String staffName;
  final String
  leaveType; // 'Annual', 'Compassionate', 'Sick', 'Personal', 'Emergency'
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? attachmentUrl;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String? adminComment;
  final DateTime appliedDate;
  final DateTime? approvedDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LeaveRequest({
    this.id,
    required this.staffId,
    required this.staffName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.attachmentUrl,
    required this.status,
    this.adminComment,
    DateTime? appliedDate,
    this.approvedDate,
    DateTime? createdAt,
    this.updatedAt,
  }) : appliedDate = appliedDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  /// Get number of leave days
  int get numberOfDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Convert LeaveRequest to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'attachmentUrl': attachmentUrl,
      'status': status,
      'adminComment': adminComment,
      'appliedDate': appliedDate.toIso8601String(),
      'approvedDate': approvedDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create LeaveRequest from Firestore document
  factory LeaveRequest.fromMap(Map<String, dynamic> map, String docId) {
    return LeaveRequest(
      id: docId,
      staffId: map['staffId'] as String,
      staffName: map['staffName'] as String,
      leaveType: map['leaveType'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      reason: map['reason'] as String,
      attachmentUrl: map['attachmentUrl'] as String?,
      status: map['status'] as String? ?? 'Pending',
      adminComment: map['adminComment'] as String?,
      appliedDate: map['appliedDate'] != null
          ? DateTime.parse(map['appliedDate'] as String)
          : DateTime.now(),
      approvedDate: map['approvedDate'] != null
          ? DateTime.parse(map['approvedDate'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory LeaveRequest.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return LeaveRequest.fromMap(data, snapshot.id);
  }

  /// Copy with - create a modified copy
  LeaveRequest copyWith({
    String? id,
    String? staffId,
    String? staffName,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? attachmentUrl,
    String? status,
    String? adminComment,
    DateTime? appliedDate,
    DateTime? approvedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      status: status ?? this.status,
      adminComment: adminComment ?? this.adminComment,
      appliedDate: appliedDate ?? this.appliedDate,
      approvedDate: approvedDate ?? this.approvedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LeaveRequest(id: $id, staffId: $staffId, staffName: $staffName, '
        'leaveType: $leaveType, startDate: $startDate, endDate: $endDate, '
        'status: $status, numberOfDays: $numberOfDays)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          staffId == other.staffId &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ staffId.hashCode ^ status.hashCode;
}
