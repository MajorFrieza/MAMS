import 'package:flutter/material.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'face_recognition_screen.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_database.dart';

class ClockScreen extends StatefulWidget {
  @override
  _ClockScreenState createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late String _currentTime;
  late String _currentDate;
  Timer? _timer;
  bool checkedIn = false;
  final AttendanceDatabase _database = AttendanceDatabase();
  AttendanceRecord? _todayAttendance;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _updateDateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateDateTime());
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    final attendance = await _database.getTodayAttendance();
    setState(() {
      _todayAttendance = attendance;
      if (attendance != null && attendance.checkInTime != null) {
        checkedIn = true;
      }
    });
  }

  void _updateDateTime() {
    final myt = tz.getLocation('Asia/Kuala_Lumpur');
    final now = tz.TZDateTime.now(myt);
    setState(() {
      _currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
      _currentDate =
          "${_getWeekday(now.weekday)}, ${_getMonth(now.month)} ${now.day}, ${now.year}";
    });
  }

  String _getWeekday(int weekday) {
    const days = [
      '', // placeholder
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday];
  }

  String _getMonth(int month) {
    const months = [
      '', // placeholder
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  void _checkIn() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceRecognitionScreen(
          attendanceType: 'checkIn',
          location: 'Office - Main Building',
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadTodayAttendance();
      }
    });
  }

  void _checkOut() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceRecognitionScreen(
          attendanceType: 'checkOut',
          location: 'Office - Main Building',
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadTodayAttendance();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Attendance Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 30),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 40, color: Colors.black),
                      SizedBox(height: 10),
                      Text(
                        _currentTime,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(_currentDate, style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Current Location Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[700]),
                      SizedBox(width: 10),
                      Text(
                        "Current Location\nOffice - Main Building",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Check In / Check Out Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: checkedIn ? null : _checkIn,
                        icon: Icon(Icons.camera_alt),
                        label: Text("Check In"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: checkedIn
                              ? Colors.grey[400]
                              : Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: checkedIn ? _checkOut : null,
                        icon: Icon(Icons.camera_alt),
                        label: Text("Check Out"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: checkedIn
                              ? Colors.grey[700]
                              : Colors.grey[300],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Info Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[700]),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Face recognition ensures secure and contactless attendance marking. Make sure you're in a well-lit area.",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Today's Summary
                if (_todayAttendance != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!, width: 2),
                    ),
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Check In Time',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              _todayAttendance?.checkInTime ?? 'Not checked in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (_todayAttendance?.checkOutTime != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Check Out Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _todayAttendance?.checkOutTime ??
                                    'Not checked out',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 8),
                        if (_todayAttendance?.getHoursWorked() != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hours Worked',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _todayAttendance?.getHoursWorked() ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '✓ You are currently checked in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
