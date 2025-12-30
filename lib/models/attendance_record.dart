import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String? id;
  final DateTime date;
  final String? checkInTime;
  final String? checkOutTime;
  final String status; // 'Present', 'Absent', 'Late'
  final String? faceImagePath;
  final String? location;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.faceImagePath,
    this.location,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert AttendanceRecord to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'status': status,
      'faceImagePath': faceImagePath,
      'location': location,
      // createdAt/updatedAt will be managed by server timestamps in the DB
    };
  }

  /// Create AttendanceRecord from Firestore document
  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String docId) {
    // date and timestamps may be stored as Firestore `Timestamp` or ISO strings
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return AttendanceRecord(
      id: docId,
      date: parseDate(map['date']),
      checkInTime: map['checkInTime'] as String?,
      checkOutTime: map['checkOutTime'] as String?,
      status: map['status'] as String? ?? 'Present',
      faceImagePath: map['faceImagePath'] as String?,
      location: map['location'] as String?,
      createdAt: map['createdAt'] != null
          ? parseDate(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory AttendanceRecord.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return AttendanceRecord.fromMap(data, snapshot.id);
  }

  /// Copy with - create a modified copy
  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    String? checkInTime,
    String? checkOutTime,
    String? status,
    String? faceImagePath,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      faceImagePath: faceImagePath ?? this.faceImagePath,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, date: $date, checkInTime: $checkInTime, '
        'checkOutTime: $checkOutTime, status: $status, location: $location)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ status.hashCode;
}
