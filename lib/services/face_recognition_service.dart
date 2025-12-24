import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  static final FaceRecognitionService _instance =
      FaceRecognitionService._internal();
  late FaceDetector _faceDetector;
  // reference face image (reserved for future enrollment)

  factory FaceRecognitionService() {
    return _instance;
  }

  FaceRecognitionService._internal() {
    _initializeFaceDetector();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableTracking: true,
      enableClassification: true,
    );
    _faceDetector = FaceDetector(options: options);
  }

  // Process image and detect faces
  Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  // Check if face is detected in image
  Future<bool> isFaceDetected(String imagePath) async {
    try {
      final faces = await detectFaces(imagePath);
      return faces.isNotEmpty;
    } catch (e) {
      print('Error detecting face: $e');
      return false;
    }
  }

  // Get face confidence (0.0 - 1.0)
  Future<double> getFaceConfidence(String imagePath) async {
    try {
      final faces = await detectFaces(imagePath);
      if (faces.isEmpty) return 0.0;

      // For now, we'll return 1.0 if face is detected
      // In production, you'd compare face embeddings
      return 1.0;
    } catch (e) {
      print('Error getting face confidence: $e');
      return 0.0;
    }
  }

  // Verify if captured face matches reference face
  Future<bool> verifyFace(
    String capturedImagePath,
    String referenceImagePath,
  ) async {
    try {
      final capturedFaces = await detectFaces(capturedImagePath);
      final referenceFaces = await detectFaces(referenceImagePath);

      if (capturedFaces.isEmpty || referenceFaces.isEmpty) {
        return false;
      }

      // Basic verification: check if faces exist in both images
      // In production, use ML Kit Face Contour or Google Cloud Vision for advanced matching
      return true;
    } catch (e) {
      print('Error verifying face: $e');
      return false;
    }
  }

  // Extract face region from image
  Future<img.Image?> extractFaceRegion(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return null;

      final imageData = file.readAsBytesSync();
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      final faces = await detectFaces(imagePath);
      if (faces.isEmpty) return null;

      final face = faces.first;
      final bbox = face.boundingBox;

      // Extract face region with some padding
      final padding = 20;
      final x = (bbox.left - padding).toInt().clamp(0, image.width - 1);
      final y = (bbox.top - padding).toInt().clamp(0, image.height - 1);
      final width = (bbox.width + padding * 2).toInt().clamp(
        1,
        image.width - x,
      );
      final height = (bbox.height + padding * 2).toInt().clamp(
        1,
        image.height - y,
      );

      return img.copyCrop(image, x: x, y: y, width: width, height: height);
    } catch (e) {
      print('Error extracting face region: $e');
      return null;
    }
  }

  // Get face contours (for advanced matching)
  Future<List<Face>> getFaceContours(String imagePath) async {
    try {
      final faces = await detectFaces(imagePath);
      return faces;
    } catch (e) {
      print('Error getting face contours: $e');
      return [];
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    await _faceDetector.close();
  }

  // Check face quality (lighting, angle, etc.)
  Future<bool> isFaceQualityGood(String imagePath) async {
    try {
      final faces = await detectFaces(imagePath);
      if (faces.isEmpty) return false;

      final face = faces.first;

      // Check if face is not too small
      if (face.boundingBox.width < 100 || face.boundingBox.height < 100) {
        return false;
      }

      // Check head position (not too tilted)
      if ((face.headEulerAngleX?.abs() ?? 0) > 30 ||
          (face.headEulerAngleY?.abs() ?? 0) > 30 ||
          (face.headEulerAngleZ?.abs() ?? 0) > 30) {
        return false;
      }

      // All checks passed
      return true;
    } catch (e) {
      print('Error checking face quality: $e');
      return false;
    }
  }
}
