import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';

/// ML Kit-based face detection (presence/quality only).
/// This is not true identity verification; it checks that a face is present and of acceptable quality.
class FaceRecognitionService {
  late final FaceDetector _faceDetector;

  FaceRecognitionService() {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: true,
      enableContours: false,
      enableLandmarks: false,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<List<Face>> _detectFaces(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) return [];
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _faceDetector.processImage(inputImage);
  }

  Future<bool> isFaceDetected(String imagePath) async {
    try {
      final faces = await _detectFaces(imagePath);
      return faces.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFaceQualityGood(String imagePath) async {
    try {
      final faces = await _detectFaces(imagePath);
      if (faces.isEmpty) return false;
      final face = faces.first;
      final bbox = face.boundingBox;
      // Basic quality heuristics: reasonable size and frontal-ish pose
      final sizeOk = bbox.width > 80 && bbox.height > 80;
      final poseOk = (face.headEulerAngleX?.abs() ?? 0) < 25 &&
          (face.headEulerAngleY?.abs() ?? 0) < 25 &&
          (face.headEulerAngleZ?.abs() ?? 0) < 25;
      return sizeOk && poseOk;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    await _faceDetector.close();
  }
}
