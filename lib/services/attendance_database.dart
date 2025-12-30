import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_record.dart';

class AttendanceDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get collection reference for attendance records
  CollectionReference<AttendanceRecord> _getAttendanceCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .withConverter<AttendanceRecord>(
          fromFirestore: (snapshot, _) =>
              AttendanceRecord.fromSnapshot(snapshot),
          toFirestore: (record, _) => record.toMap(),
        );
  }

  /// Insert or update attendance record
  Future<String> insertAttendance(AttendanceRecord record) async {
    try {
      final collection = _getAttendanceCollection();

      // Check if record for the same day already exists using a range
      final startOfDay = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await collection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      String docId;
      if (querySnapshot.docs.isNotEmpty) {
        // Update existing record (update only mutable fields and preserve original createdAt)
        docId = querySnapshot.docs.first.id;
        final Map<String, dynamic> updateMap = {};
        // Always update checkInTime and checkOutTime explicitly (can be null)
        updateMap['checkInTime'] = record.checkInTime;
        updateMap['checkOutTime'] = record.checkOutTime;
        if (record.status.isNotEmpty) {
          updateMap['status'] = record.status;
        }
        if (record.faceImagePath != null) {
          updateMap['faceImagePath'] = record.faceImagePath;
        }
        if (record.locationCoords != null) {
          updateMap['locationCoords'] = record.locationCoords;
        }
        if (record.locationAddress != null) {
          updateMap['locationAddress'] = record.locationAddress;
        }
        updateMap['updatedAt'] = FieldValue.serverTimestamp();

        await collection.doc(docId).update(updateMap);
      } else {
        // Create new record
        final docRef = await collection.add(record);
        docId = docRef.id;
        // Ensure createdAt/updatedAt are set server-side
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('attendance')
            .doc(docId)
            .update({
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      return docId;
    } catch (e) {
      rethrow;
    }
  }

  /// Get attendance record for today
  Future<AttendanceRecord?> getTodayAttendance() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final collection = _getAttendanceCollection();
      final querySnapshot = await collection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get attendance records for a date range
  Future<List<AttendanceRecord>> getAttendanceByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final collection = _getAttendanceCollection();
      final querySnapshot = await collection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all attendance records for current user
  Future<List<AttendanceRecord>> getAllAttendance() async {
    try {
      final collection = _getAttendanceCollection();
      final querySnapshot = await collection
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get last N attendance records
  Future<List<AttendanceRecord>> getLastNAttendance(int n) async {
    try {
      final collection = _getAttendanceCollection();
      final querySnapshot = await collection
          .orderBy('date', descending: true)
          .limit(n)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get attendance by status
  Future<List<AttendanceRecord>> getAttendanceByStatus(String status) async {
    try {
      final collection = _getAttendanceCollection();
      final querySnapshot = await collection
          .where('status', isEqualTo: status)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String recordId) async {
    try {
      await _getAttendanceCollection().doc(recordId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get attendance statistics for user
  Future<AttendanceStats> getAttendanceStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final records = await getAttendanceByDateRange(startDate, endDate);

      int presentCount = 0;
      int absentCount = 0;
      int lateCount = 0;
      int totalDays = 0;

      for (final record in records) {
        totalDays++;
        switch (record.status.toLowerCase()) {
          case 'present':
            presentCount++;
            break;
          case 'absent':
            absentCount++;
            break;
          case 'late':
            lateCount++;
            break;
        }
      }

      return AttendanceStats(
        totalDays: totalDays,
        presentCount: presentCount,
        absentCount: absentCount,
        lateCount: lateCount,
      );
    } catch (e) {
      return AttendanceStats.zero();
    }
  }

  /// Stream attendance records
  Stream<List<AttendanceRecord>> streamAttendance() {
    try {
      return _getAttendanceCollection()
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Stream today's attendance
  Stream<AttendanceRecord?> streamTodayAttendance() {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return _getAttendanceCollection()
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return snapshot.docs.first.data();
            }
            return null;
          });
    } catch (e) {
      return Stream.value(null);
    }
  }

  /// Clear all attendance records for current user
  Future<void> clearAttendanceHistory() async {
    final collection = _getAttendanceCollection();
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

/// Model for attendance statistics
class AttendanceStats {
  final int totalDays;
  final int presentCount;
  final int absentCount;
  final int lateCount;

  AttendanceStats({
    required this.totalDays,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
  });

  factory AttendanceStats.zero() {
    return AttendanceStats(
      totalDays: 0,
      presentCount: 0,
      absentCount: 0,
      lateCount: 0,
    );
  }

  /// Attendance percentage
  double get attendancePercentage {
    if (totalDays == 0) return 0;
    return (presentCount / totalDays) * 100;
  }

  /// Average status
  String get averageStatus {
    if (totalDays == 0) return 'N/A';
    if (presentCount >= totalDays * 0.8) return 'Good';
    if (presentCount >= totalDays * 0.6) return 'Fair';
    return 'Poor';
  }

  @override
  String toString() {
    return 'AttendanceStats(total: $totalDays, present: $presentCount, '
        'absent: $absentCount, late: $lateCount, percentage: ${attendancePercentage.toStringAsFixed(1)}%)';
  }
}
