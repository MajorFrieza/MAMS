import 'package:flutter/material.dart';
import 'dart:async';
import 'face_recognition_screen.dart';
import '../../services/attendance_database.dart';
import '../../models/attendance_record.dart';
import '../../services/location_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late String _currentTime;
  late String _currentDate;
  Timer? _timer;
  bool checkedIn = false;
  AttendanceRecord? _todayAttendance;
  final AttendanceDatabase _attendanceDb = AttendanceDatabase();
  bool _showSummary = false;
  String _currentLocation = "Loading location...";
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _updateDateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateDateTime());
    _loadTodayAttendance();
    _loadCurrentLocation();
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final record = await _attendanceDb.getTodayAttendance();
      if (record != null) {
        final now = DateTime.now();
        final created = record.createdAt;
        final isCreatedToday =
            created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
        if (!mounted) return;
        setState(() {
          _todayAttendance = record;
          checkedIn =
              isCreatedToday &&
              record.checkInTime != null &&
              record.checkOutTime == null &&
              (record.faceImagePath != null &&
                  record.faceImagePath!.isNotEmpty);
        });
      }
    } catch (e) {
      // ignore
    }
  }

  String _getWorkingHours() {
    if (_todayAttendance == null ||
        _todayAttendance!.checkInTime == null ||
        _todayAttendance!.checkOutTime == null) {
      return '--:--';
    }

    try {
      final checkInStr = _todayAttendance!.checkInTime!;
      final checkOutStr = _todayAttendance!.checkOutTime!;
      final checkInTime = _parseTimeString(checkInStr);
      final checkOutTime = _parseTimeString(checkOutStr);
      if (checkInTime == null || checkOutTime == null) return '--:--';
      final difference = checkOutTime.difference(checkInTime);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } catch (e) {
      return '--:--';
    }
  }

  DateTime? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = parts[1].toUpperCase();
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  void _updateDateTime() {
    final myt = tz.getLocation('Asia/Kuala_Lumpur');
    final now = tz.TZDateTime.now(myt);
    if (!mounted) return;
    setState(() {
      final suffix = now.hour >= 12 ? 'PM' : 'AM';
      final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
      _currentTime =
          "${hour12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} $suffix";
      _currentDate =
          "${_getWeekday(now.weekday)}, ${_getMonth(now.month)} ${now.day}, ${now.year}";
    });
  }

  String _getWeekday(int weekday) {
    const days = [
      '',
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
      '',
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

  Future<void> _loadCurrentLocation() async {
    try {
      // Try to get a human-readable address first, fallback to coords
      final location =
          await LocationService.instance.getCurrentAddressString() ??
          await LocationService.instance.getCurrentLocationString();
      if (!mounted) return;
      setState(() {
        _currentLocation = location ?? "Location unavailable";
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentLocation = "Tap Check In to enable location";
        _loadingLocation = false;
      });
    }
  }

  Future<void> _openLocationSettings() async {
    final opened = await LocationService.instance.openLocationSettings();
    if (opened) {
      // give system a moment and then try to reload
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _loadingLocation = true;
      });
      await _loadCurrentLocation();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open location settings')),
      );
    }
  }

  Future<void> _checkIn() async {
    // Request location permission before checking in
    await LocationService.instance.requestLocationPermission();

    // Get current location
    final location =
        await LocationService.instance.getCurrentAddressString() ??
        await LocationService.instance.getCurrentLocationString();

    if (!mounted) return;

    setState(() {
      _currentLocation = location ?? "Location unavailable";
    });

    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceRecognitionScreen(
          attendanceType: 'checkIn',
          location: _currentLocation,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadTodayAttendance();
      setState(() {
        checkedIn = true;
        _showSummary = true;
      });
    }
  }

  Future<void> _checkOut() async {
    // Request location permission before checking out
    await LocationService.instance.requestLocationPermission();

    // Get current location
    final location =
        await LocationService.instance.getCurrentAddressString() ??
        await LocationService.instance.getCurrentLocationString();

    if (!mounted) return;

    setState(() {
      _currentLocation = location ?? "Location unavailable";
    });

    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceRecognitionScreen(
          attendanceType: 'checkOut',
          location: _currentLocation,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadTodayAttendance();
      setState(() {
        checkedIn = false;
        _showSummary = true;
      });
    }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            Icon(
                              Icons.access_time,
                              size: 40,
                              color: Colors.black,
                            ),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Current Location",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _currentLocation,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6),
                                  if (_currentLocation.toLowerCase().contains(
                                        'disabled',
                                      ) ||
                                      _currentLocation.toLowerCase().contains(
                                        'not granted',
                                      ))
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: _openLocationSettings,
                                        icon: Icon(Icons.settings, size: 18),
                                        label: Text('Enable Location'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_loadingLocation)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                                    ? Colors.red[600]
                                    : Colors.grey[300],
                                padding: EdgeInsets.symmetric(vertical: 16),
                                textStyle: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Today's Summary (only show after a successful scan)
                      if (_showSummary)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Summary",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Check In Time',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    _todayAttendance?.checkInTime ?? '--:--',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              // Show Check Out Time and Working Hours only after checkout
                              if (_todayAttendance?.checkOutTime != null) ...[
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Check Out Time',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      _todayAttendance!.checkOutTime!,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Working Hours',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      _getWorkingHours(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              SizedBox(height: 12),
                              if (_todayAttendance != null &&
                                  _todayAttendance!.checkInTime != null)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Attendance marked successfully!',
                                          style: TextStyle(
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox.shrink(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
