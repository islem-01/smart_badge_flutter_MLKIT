// lib/screens/employee/scan_screen.dart
// ── Utilise les 4 services ML Kit ────────────────────────────
//   Service 1 : Barcode Scanning  (QR Code live stream)
//   Service 2 : Text Recognition  (OCR photo)
//   Service 3 : Face Detection    (vérification identité)
//   Service 4 : Translation       (département traduit)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../../services/scanner_service.dart';
import '../../services/database_service.dart';
import '../../services/attendance_service.dart';
import '../../services/notif_service.dart';
import '../../providers/settings_provider.dart';
import '../../models/employee_model.dart';

enum _ScanMode { qr, ocr }

class ScanScreen extends StatefulWidget {
  final bool isAdminMode;
  const ScanScreen({super.key, this.isAdminMode = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cam;
  bool _camReady      = false;
  bool _isScanning    = false;
  bool _isProcessing  = false;
  _ScanMode _mode     = _ScanMode.qr;

  // Résultat
  String?  _resultMsg;
  bool     _resultOk  = false;
  Employee? _lastEmp;

  // Animation bouton
  late AnimationController _pulse;
  late Animation<double>   _pulseAnim;
  final _audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this,
        duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _cam = CameraController(cameras.first, ResolutionPreset.high,
          enableAudio: false);
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
    } catch (_) {}
  }

  // ── ML Kit Service 1 : QR Code via stream ────────────
  Future<void> _startQrStream() async {
    if (!_camReady || _isScanning) return;
    setState(() { _isScanning = true; _resultMsg = null; });

    _cam!.startImageStream((img) async {
      if (_isProcessing) return;
      _isProcessing = true;
      try {
        final qr = await ScannerService.instance.scanQRFromStream(
            img, InputImageRotation.rotation0deg);
        if (qr != null) {
          await _stopQrStream();
          await _processQR(qr);
        }
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _stopQrStream() async {
    if (_cam?.value.isStreamingImages == true) {
      await _cam!.stopImageStream();
    }
    if (mounted) setState(() => _isScanning = false);
  }

  // ── ML Kit Service 2 : OCR via photo ─────────────────
  Future<void> _captureOCR() async {
    if (!_camReady || _isScanning) return;
    setState(() => _isScanning = true);
    try {
      final photo  = await _cam!.takePicture();
      final result = await ScannerService.instance.readTextFromFile(photo.path);

      Employee? emp;
      if (result.extractedId != null) {
        emp = await DatabaseService().getEmployeeByQR(result.extractedId!);
      }
      await _processEmployee(emp, 'ocr',
          extraInfo: 'Texte: ${result.fullText.substring(0,
              result.fullText.length.clamp(0, 80))}…');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _processQR(String raw) async {
    final emp = await DatabaseService().getEmployeeByQR(raw);
    await _processEmployee(emp, 'qr');
  }

  Future<void> _processEmployee(Employee? emp, String method,
      {String? extraInfo}) async {
    final settings    = context.read<SettingsProvider>();
    final attendance  = context.read<AttendanceService>();
    final lang        = settings.language;

    if (emp == null) {
      _showResult(false, 'Badge non reconnu${extraInfo != null ? '\n$extraInfo' : ''}');
      return;
    }

    // ── ML Kit Service 4 : Traduction du département ──
    final deptTranslated =
        await ScannerService.instance.translateDepartment(emp.department, lang);

    // Enregistrer présence
    final result = await attendance.processScan(emp);

    // Feedback
    if (settings.vibrationEnabled) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    if (settings.soundEnabled) {
      try {
        await _audio.play(AssetSource('sounds/beep.mp3'));
      } catch (_) {}
    }
    if (settings.notificationsEnabled) {
      await NotifService.instance.showScanSuccess(
          emp.name, deptTranslated, result.type.name);
    }

    _showResult(true,
        '${result.message}\n$deptTranslated',
        employee: emp);
  }

  void _showResult(bool ok, String msg, {Employee? employee}) {
    setState(() {
      _resultOk  = ok;
      _resultMsg = msg;
      _lastEmp   = employee;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _resultMsg = null);
    });
  }

  // ── ML Kit Service 3 : Vérification visage ───────────
  Future<void> _verifyFace() async {
    if (!_camReady) return;
    setState(() => _isScanning = true);
    try {
      final photo  = await _cam!.takePicture();
      final result = await ScannerService.instance
          .detectFaceFromFile(photo.path);
      _showResult(result.detected && result.eyesOpen, result.message);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // Scan démo sans caméra réelle
  Future<void> _demoScan(String qrCode) async {
    final emp = await DatabaseService().getEmployeeByQR(qrCode);
    await _processEmployee(emp, 'qr');
  }

  @override
  void dispose() {
    _cam?.dispose();
    _pulse.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(settings.t('scan_badge')),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.isAdminMode,
        actions: [
          // Basculer QR ↔ OCR
          IconButton(
            icon: Icon(
              _mode == _ScanMode.qr ? Icons.text_fields : Icons.qr_code,
              color: Colors.white,
            ),
            tooltip: _mode == _ScanMode.qr
                ? settings.t('ocr_scan') : 'QR Code',
            onPressed: () => setState(() {
              _mode = _mode == _ScanMode.qr ? _ScanMode.ocr : _ScanMode.qr;
              _resultMsg = null;
            }),
          ),
          // Vérification visage (ML Kit 3)
          IconButton(
            icon: const Icon(Icons.face, color: Colors.white),
            tooltip: settings.t('verify_face'),
            onPressed: _verifyFace,
          ),
        ],
      ),
      body: Stack(children: [
        // Caméra
        if (_camReady)
          Positioned.fill(child: CameraPreview(_cam!))
        else
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0D1B2A),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('Mode démo',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ),
          ),

        // Overlay sombre
        Positioned.fill(
          child: CustomPaint(painter: _OverlayPainter()),
        ),

        // Cadre scan animé
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, _x) => Transform.scale(
              scale: _isScanning ? _pulseAnim.value : 1.0,
              child: Container(
                width: _mode == _ScanMode.qr ? 240 : 300,
                height: _mode == _ScanMode.qr ? 240 : 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScanning ? Colors.green : Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(children: _buildCorners()),
              ),
            ),
          ),
        ),

        // Label mode en haut
        Positioned(
          top: 8, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _mode == _ScanMode.qr ? Icons.qr_code : Icons.text_fields,
                  color: Colors.white, size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _mode == _ScanMode.qr ? 'QR Code' : settings.t('ocr_scan'),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
            ),
          ),
        ),

        // Résultat
        if (_resultMsg != null)
          Positioned(
            bottom: 200, left: 16, right: 16,
            child: _ResultCard(
              ok: _resultOk, message: _resultMsg!,
              employee: _lastEmp, lang: settings.language,
            ),
          ),

        // Boutons en bas
        Positioned(
          bottom: 32, left: 24, right: 24,
          child: Column(children: [
            // Bouton principal
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _isScanning
                    ? (_mode == _ScanMode.qr ? _stopQrStream : null)
                    : (_mode == _ScanMode.qr ? _startQrStream : _captureOCR),
                icon: Icon(_isScanning
                    ? Icons.stop
                    : (_mode == _ScanMode.qr
                        ? Icons.qr_code_scanner : Icons.camera_alt)),
                label: Text(
                  _isScanning
                      ? 'Arrêter'
                      : settings.t('scan_badge'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Boutons démo
            const Text('Test rapide (démo)',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['emp_001','emp_002','emp_003','emp_004','emp_005']
                    .map((id) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton(
                            onPressed: () => _demoScan('BADGE_$id'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                            child: Text(id,
                                style: const TextStyle(fontSize: 11)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _buildCorners() {
    const s = 22.0, t = 3.0;
    const c = Colors.green;
    return [
      Positioned(top: 0,    left: 0,  child: Container(width: s, height: t, color: c)),
      Positioned(top: 0,    left: 0,  child: Container(width: t, height: s, color: c)),
      Positioned(top: 0,    right: 0, child: Container(width: s, height: t, color: c)),
      Positioned(top: 0,    right: 0, child: Container(width: t, height: s, color: c)),
      Positioned(bottom: 0, left: 0,  child: Container(width: s, height: t, color: c)),
      Positioned(bottom: 0, left: 0,  child: Container(width: t, height: s, color: c)),
      Positioned(bottom: 0, right: 0, child: Container(width: s, height: t, color: c)),
      Positioned(bottom: 0, right: 0, child: Container(width: t, height: s, color: c)),
    ];
  }
}

// ── Overlay sombre ─────────────────────────────────────────────
class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color  = Colors.black.withValues(alpha: 0.5)
      ..style  = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final rect   = Rect.fromCenter(center: center, width: 250, height: 250);
    canvas.drawPath(
      Path.combine(PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          Path()..addRRect(RRect.fromRectAndRadius(
              rect, const Radius.circular(10)))),
      paint,
    );
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Carte résultat ─────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final bool ok;
  final String message;
  final Employee? employee;
  final String lang;

  const _ResultCard({
    required this.ok, required this.message,
    required this.employee, required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:         ok ? Colors.green.shade800 : Colors.red.shade800,
        borderRadius:  BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: (ok ? Colors.green : Colors.red).withValues(alpha: 0.4),
            blurRadius: 12)],
      ),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.error,
            color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w600)),
              if (employee != null) ...[
                const SizedBox(height: 4),
                Text('ID: ${employee!.id}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}
