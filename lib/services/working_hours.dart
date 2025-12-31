/// Working hours configuration for the organization
class WorkingHours {
  /// Define working hours for each day of the week
  /// Key: weekday number (1=Monday, 7=Sunday)
  /// Value: {startHour, startMinute, endHour, endMinute} or null if closed
  static final Map<int, Map<String, int>?> _hours = {
    1: {
      'startHour': 8,
      'startMinute': 30,
      'endHour': 17,
      'endMinute': 30,
    }, // Monday
    2: {
      'startHour': 8,
      'startMinute': 30,
      'endHour': 17,
      'endMinute': 30,
    }, // Tuesday
    3: {
      'startHour': 8,
      'startMinute': 30,
      'endHour': 17,
      'endMinute': 30,
    }, // Wednesday
    4: {
      'startHour': 8,
      'startMinute': 30,
      'endHour': 17,
      'endMinute': 30,
    }, // Thursday (New Year's Day)
    5: {
      'startHour': 8,
      'startMinute': 30,
      'endHour': 17,
      'endMinute': 30,
    }, // Friday
    6: {
      'startHour': 8,
      'startMinute': 30,
      'endHour': 12,
      'endMinute': 30,
    }, // Saturday
    7: null, // Sunday (Closed)
  };

  /// Get working hours for a specific day
  /// Returns null if the day is closed, otherwise returns {startHour, startMinute, endHour, endMinute}
  static Map<String, int>? getHoursForDay(int weekday) {
    return _hours[weekday];
  }

  /// Get start time in minutes since midnight for a given weekday
  /// Returns null if the day is closed
  static int? getStartTimeMinutes(int weekday) {
    final hours = getHoursForDay(weekday);
    if (hours == null) return null;
    return hours['startHour']! * 60 + hours['startMinute']!;
  }

  /// Get end time in minutes since midnight for a given weekday
  /// Returns null if the day is closed
  static int? getEndTimeMinutes(int weekday) {
    final hours = getHoursForDay(weekday);
    if (hours == null) return null;
    return hours['endHour']! * 60 + hours['endMinute']!;
  }

  /// Determine attendance status based on check-in time and weekday
  /// Returns 'Late', 'Present', or 'Absent'
  static String determineStatus({
    required DateTime checkInTime,
    required int weekday,
  }) {
    final startMinutes = getStartTimeMinutes(weekday);

    // If closed on this day
    if (startMinutes == null) {
      return 'Present'; // No check-in expected
    }

    // Get check-in time in minutes since midnight
    final checkInMinutes = checkInTime.hour * 60 + checkInTime.minute;

    // If check-in is after start time, mark as Late
    if (checkInMinutes > startMinutes) {
      return 'Late';
    }

    return 'Present';
  }

  /// Get formatted working hours for a day
  static String getFormattedHours(int weekday) {
    final hours = getHoursForDay(weekday);
    if (hours == null) {
      return 'Closed';
    }
    final start =
        '${hours['startHour']!.toString().padLeft(2, '0')}:${hours['startMinute']!.toString().padLeft(2, '0')}';
    final end =
        '${hours['endHour']!.toString().padLeft(2, '0')}:${hours['endMinute']!.toString().padLeft(2, '0')}';
    return '$start – $end';
  }
}
