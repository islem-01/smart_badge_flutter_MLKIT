// lib/services/scanner_service.dart
// ════════════════════════════════════════════════════════════════
//  ML Kit – 4 services
//  Service 1 : Barcode Scanning  → Scanner QR Code du badge
//  Service 2 : Text Recognition  → OCR : lire texte du badge
//  Service 3 : Face Detection    → Vérifier identité par visage
//  Service 4 : Translation       → Traduire département FR/EN/AR
// ════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:camera/camera.dart';

class ScannerService {
  static final ScannerService instance = ScannerService._();
  ScannerService._();

  // ── Service 1 : QR Code ──────────────────────────────
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode],
  );

  // ── Service 2 : OCR ───────────────────────────────────
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // ── Service 3 : Face Detection ────────────────────────
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // ── Service 4 : Translation ───────────────────────────
  OnDeviceTranslator? _translator;
  String _lastTargetLang = '';

  // ══════════════════════════════════════════════════════
  //  SERVICE 1 – Scan QR Code depuis CameraImage (stream)
  // ══════════════════════════════════════════════════════
  Future<String?> scanQRFromStream(
      CameraImage img, InputImageRotation rotation) async {
    try {
      final inputImage = _buildInputImage(img, rotation);
      if (inputImage == null) return null;
      final barcodes = await _barcodeScanner.processImage(inputImage);
      for (final b in barcodes) {
        if (b.rawValue != null) return b.rawValue;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  //  SERVICE 1 – Scan QR Code depuis un fichier image (photo)
  Future<String?> scanQRFromFile(String imagePath) async {
    try {
      final image    = InputImage.fromFilePath(imagePath);
      final barcodes = await _barcodeScanner.processImage(image);
      return barcodes.isNotEmpty ? barcodes.first.rawValue : null;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════
  //  SERVICE 2 – OCR : Lire texte d'une image fichier
  // ══════════════════════════════════════════════════════
  Future<OcrResult> readTextFromFile(String imagePath) async {
    try {
      final image  = InputImage.fromFilePath(imagePath);
      final result = await _textRecognizer.processImage(image);
      final text   = result.text;

      // Extraire ID employé (pattern EMPxxx ou BADGE_xxx)
      String? empId;
      final qrMatch = RegExp(r'BADGE_(\w+)', caseSensitive: false)
          .firstMatch(text.toUpperCase());
      if (qrMatch != null) {
        empId = 'BADGE_${qrMatch.group(1)}';
      } else {
        final idMatch = RegExp(r'emp[_-]?\d{3}', caseSensitive: false)
            .firstMatch(text.toLowerCase());
        if (idMatch != null) empId = idMatch.group(0);
      }

      // Extraire nom et département
      String? name, dept;
      for (final line in text.split('\n')) {
        final l = line.trim().toLowerCase();
        if (l.startsWith('nom') || l.startsWith('name')) {
          name = line.split(':').last.trim();
        }
        if (l.startsWith('dept') || l.startsWith('département')) {
          dept = line.split(':').last.trim();
        }
      }

      return OcrResult(
        fullText:     text,
        extractedId:  empId,
        extractedName: name,
        extractedDept: dept,
      );
    } catch (e) {
      return OcrResult(fullText: '', extractedId: null);
    }
  }

  // ══════════════════════════════════════════════════════
  //  SERVICE 3 – Détection de visage depuis fichier image
  // ══════════════════════════════════════════════════════
  Future<FaceResult> detectFaceFromFile(String imagePath) async {
    try {
      final image = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(image);

      if (faces.isEmpty) {
        return FaceResult(detected: false, message: 'Aucun visage détecté');
      }
      final face      = faces.first;
      final leftEye   = face.leftEyeOpenProbability  ?? 0;
      final rightEye  = face.rightEyeOpenProbability ?? 0;
      final eyesOpen  = leftEye > 0.5 && rightEye > 0.5;

      return FaceResult(
        detected:  true,
        eyesOpen:  eyesOpen,
        faceCount: faces.length,
        smile:     face.smilingProbability ?? 0,
        message:   eyesOpen ? 'Identité vérifiée ✓' : 'Ouvrez les yeux',
      );
    } catch (_) {
      return FaceResult(detected: false, message: 'Erreur de détection');
    }
  }

  //  SERVICE 3 – Détection depuis CameraImage stream
  Future<FaceResult> detectFaceFromStream(
      CameraImage img, InputImageRotation rotation) async {
    try {
      final inputImage = _buildInputImage(img, rotation);
      if (inputImage == null) {
        return FaceResult(detected: false, message: 'Image invalide');
      }
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        return FaceResult(detected: false, message: 'Aucun visage');
      }
      final face     = faces.first;
      final eyesOpen = (face.leftEyeOpenProbability  ?? 0) > 0.5 &&
                       (face.rightEyeOpenProbability ?? 0) > 0.5;
      return FaceResult(
        detected:  true,
        eyesOpen:  eyesOpen,
        faceCount: faces.length,
        message:   eyesOpen ? 'Visage détecté ✓' : 'Ouvrez les yeux',
      );
    } catch (_) {
      return FaceResult(detected: false, message: 'Erreur');
    }
  }

  // ══════════════════════════════════════════════════════
  //  SERVICE 4 – Traduction du département (FR → EN / AR)
  // ══════════════════════════════════════════════════════
  Future<String> translateDepartment(String text, String targetLang) async {
    if (targetLang == 'fr') return text;
    try {
      if (_lastTargetLang != targetLang || _translator == null) {
        _translator?.close();
        _translator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.french,
          targetLanguage: targetLang == 'ar'
              ? TranslateLanguage.arabic
              : TranslateLanguage.english,
        );
        _lastTargetLang = targetLang;
      }
      return await _translator!.translateText(text);
    } catch (_) {
      return text;
    }
  }

  // ── Convertir CameraImage → InputImage ML Kit ────────
  InputImage? _buildInputImage(CameraImage img, InputImageRotation rotation) {
    try {
      final bytes = _concatenatePlanes(img.planes);
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size:        Size(img.width.toDouble(), img.height.toDouble()),
          rotation:    rotation,
          format:      InputImageFormat.nv21,
          bytesPerRow: img.planes[0].bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final buffer = WriteBuffer();
    for (final p in planes) buffer.putUint8List(p.bytes);
    return buffer.done().buffer.asUint8List();
  }

  void dispose() {
    _barcodeScanner.close();
    _textRecognizer.close();
    _faceDetector.close();
    _translator?.close();
  }
}

// ── Résultats ─────────────────────────────────────────────────
class OcrResult {
  final String fullText;
  final String? extractedId;
  final String? extractedName;
  final String? extractedDept;

  OcrResult({
    required this.fullText,
    required this.extractedId,
    this.extractedName,
    this.extractedDept,
  });
}

class FaceResult {
  final bool detected;
  final bool eyesOpen;
  final int faceCount;
  final double smile;
  final String message;

  FaceResult({
    required this.detected,
    this.eyesOpen  = false,
    this.faceCount = 0,
    this.smile     = 0,
    required this.message,
  });
}
