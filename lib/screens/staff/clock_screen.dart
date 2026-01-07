import 'package:flutter/material.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class ClockScreen extends StatefulWidget {
  @override
  _ClockScreenState createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late String _currentTime;
  late String _currentDate;
  Timer? _timer;
  bool checkedIn = false;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _updateDateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateDateTime());
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
    setState(() {
      checkedIn = true;
    });
  }

  void _checkOut() {
    setState(() {
      checkedIn = false;
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
            ],
          ),
        ),
      ),
    );
  }
}
