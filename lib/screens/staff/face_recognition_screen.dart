import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/face_recognition_service.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_database.dart';
import '../../services/location_service.dart';

class FaceRecognitionScreen extends StatefulWidget {
  final String attendanceType; // 'checkIn' or 'checkOut'
  final String location;

  const FaceRecognitionScreen({
    super.key,
    required this.attendanceType,
    required this.location,
  });

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  late CameraController _cameraController;
  Future<void> _initializeControllerFuture = Future.value();
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  final AttendanceDatabase _database = AttendanceDatabase();

  bool _isProcessing = false;
  String _statusMessage = 'Position your face in the frame';
  bool _faceDetected = false;
  bool _processingComplete = false;
  bool _isSuccess = false;
  bool _isDisposed = false;
  bool _isCapturing = false; // Prevent concurrent camera captures

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission at runtime
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _cameraController.initialize();

      if (mounted) {
        setState(() {});
        // Start monitoring for faces
        _monitorFaceDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not access camera')),
        );
      }
    }
  }

  void _monitorFaceDetection() {
    if (_isDisposed) return;
    Future.delayed(Duration(milliseconds: 500), () async {
      if (_isDisposed) return;

      if (!_cameraController.value.isInitialized) {
        _monitorFaceDetection();
        return;
      }

      // Skip if a capture is already in progress
      if (_isCapturing) {
        if (!_processingComplete) {
          _monitorFaceDetection();
        }
        return;
      }

      try {
        _isCapturing = true;
        final image = await _cameraController.takePicture();
        _isCapturing = false;

        final faceDetected = await _faceRecognitionService.isFaceDetected(
          image.path,
        );
        final faceQuality = await _faceRecognitionService.isFaceQualityGood(
          image.path,
        );

        if (mounted) {
          setState(() {
            _faceDetected = faceDetected;
            if (faceDetected && !faceQuality) {
              _statusMessage = 'Adjust your position and lighting';
            } else if (faceDetected) {
              _statusMessage = 'Face detected! Tap to confirm';
            } else {
              _statusMessage = 'Position your face in the frame';
            }
          });
        }

        // Continue monitoring
        if (!_processingComplete) {
          _monitorFaceDetection();
        }
      } catch (e) {
        _isCapturing = false;
        if (!_processingComplete && !_isDisposed) {
          _monitorFaceDetection();
        }
      }
    });
  }

  Future<void> _processFaceRecognition() async {
    if (_isProcessing || !_faceDetected) return;

    setState(() {
      _isProcessing = true;
      _processingComplete = true; // stop monitoring further captures
      _statusMessage = 'Processing face recognition...';
    });

    try {
      // Wait for any in-flight capture to finish
      while (_isCapturing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _isCapturing = true;

      final image = await _cameraController.takePicture();
      _isCapturing = false;
      final faceQuality = await _faceRecognitionService.isFaceQualityGood(
        image.path,
      );

      if (!faceQuality) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Face quality too low. Please try again.';
        });
        return;
      }

      // Get current time
      final now = DateTime.now();
      final timeString =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

      // Normalize date to midnight (00:00:00) for consistent storage and querying
      final dateAtMidnight = DateTime(now.year, now.month, now.day);

      // Create or update attendance record
      // Fetch position and address when possible to store both coords and readable address
      final pos = await LocationService.instance.getCurrentPosition();
      String? coords;
      String? addr;
      if (pos != null) {
        coords =
            '${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}';
        addr = await LocationService.instance.getAddressFromPosition(pos);
      }

      var todayAttendance = await _database.getTodayAttendance();

      if (todayAttendance == null) {
        // New record
        todayAttendance = AttendanceRecord(
          date: dateAtMidnight,
          checkInTime: widget.attendanceType == 'checkIn' ? timeString : null,
          checkOutTime: widget.attendanceType == 'checkOut' ? timeString : null,
          status: 'Present',
          faceImagePath: image.path,
          locationCoords: coords,
          locationAddress: addr ?? widget.location,
        );
      } else {
        // Update existing record
        if (widget.attendanceType == 'checkIn') {
          todayAttendance = AttendanceRecord(
            id: todayAttendance.id,
            date: todayAttendance.date,
            checkInTime: timeString,
            checkOutTime: null,
            status: todayAttendance.status,
            faceImagePath: image.path,
            locationCoords: coords ?? todayAttendance.locationCoords,
            locationAddress: addr ?? widget.location,
          );
        } else {
          todayAttendance = AttendanceRecord(
            id: todayAttendance.id,
            date: todayAttendance.date,
            checkInTime: todayAttendance.checkInTime,
            checkOutTime: timeString,
            status: todayAttendance.status,
            faceImagePath: image.path,
            locationCoords: coords ?? todayAttendance.locationCoords,
            locationAddress: addr ?? widget.location,
          );
        }
      }

      // Save to database
      await _database.insertAttendance(todayAttendance);

      setState(() {
        _isProcessing = false;
        _processingComplete = true;
        _isSuccess = true;
        _statusMessage =
            '${widget.attendanceType == 'checkIn' ? 'Check In' : 'Check Out'} Successful!';
      });

      // Auto close after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.attendanceType == 'checkIn'
              ? 'Face Recognition Check In'
              : 'Face Recognition Check Out',
        ),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Camera preview
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _faceDetected ? Colors.green : Colors.blue,
                        width: 3,
                      ),
                    ),
                    margin: EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _cameraController.value.aspectRatio,
                        child: CameraPreview(_cameraController),
                      ),
                    ),
                  ),

                  // Face detection indicator
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _faceDetected
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _faceDetected
                              ? Colors.green[300]!
                              : Colors.orange[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _faceDetected ? Icons.check_circle : Icons.face,
                            size: 48,
                            color: _faceDetected ? Colors.green : Colors.orange,
                          ),
                          SizedBox(height: 12),
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                      SizedBox(height: 24),

                      // Buttons
                      if (!_processingComplete)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[400],
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _faceDetected && !_isProcessing
                                      ? _processFaceRecognition
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _faceDetected
                                        ? Colors.green
                                        : Colors.grey[400],
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: _isProcessing
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Confirm',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                  // Success message
                  if (_processingComplete && _isSuccess)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green[300]!,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Identity verified successfully',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.attendanceType == 'checkIn'
                                  ? 'You have checked in successfully'
                                  : 'You have checked out successfully',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 24),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
