class AttendanceRecord {
  final int? id;
  final DateTime date;
  final String? checkInTime;
  final String? checkOutTime;
  final String status; // 'Present', 'Absent', 'Late'
  final String? faceImagePath;
  final String location;

  AttendanceRecord({
    this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.status = 'Present',
    this.faceImagePath,
    required this.location,
  });

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': dateOnly,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'status': status,
      'faceImagePath': faceImagePath,
      'location': location,
    };
  }

  // Create from map from database
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      checkInTime: map['checkInTime'],
      checkOutTime: map['checkOutTime'],
      status: map['status'] ?? 'Present',
      faceImagePath: map['faceImagePath'],
      location: map['location'],
    );
  }

  // Get today's date only
  String get dateOnly {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Calculate hours worked
  String? getHoursWorked() {
    if (checkInTime == null || checkOutTime == null) return null;

    try {
      final checkInParts = checkInTime!.split(':');
      final checkOutParts = checkOutTime!.split(':');

      final checkInMinutes =
          int.parse(checkInParts[0]) * 60 + int.parse(checkInParts[1]);
      final checkOutMinutes =
          int.parse(checkOutParts[0]) * 60 + int.parse(checkOutParts[1]);

      final diffMinutes = checkOutMinutes - checkInMinutes;
      final hours = diffMinutes ~/ 60;
      final minutes = diffMinutes % 60;

      return "${hours}h ${minutes}m";
    } catch (e) {
      return null;
    }
  }
}
