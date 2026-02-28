import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/service_locator.dart';

/// Camera screen for medication photo verification.
/// Uses image_picker for simplicity (hackathon mode).
/// After capture, sends to AI service for mock verification.
class MedicationCameraScreen extends StatefulWidget {
  final String? medicationId;

  const MedicationCameraScreen({
    super.key,
    this.medicationId,
  });

  @override
  State<MedicationCameraScreen> createState() =>
      _MedicationCameraScreenState();
}

enum CameraState { ready, captured, verifying, verified, failed }

class _MedicationCameraScreenState extends State<MedicationCameraScreen> {
  CameraState _state = CameraState.ready;
  XFile? _capturedImage;
  Map<String, dynamic>? _verificationResult;
  Timer? _autoReturnTimer;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _autoReturnTimer?.cancel();
    // Delete captured image from temp storage to prevent health data leakage
    if (_capturedImage != null) {
      try {
        File(_capturedImage!.path).deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    HapticFeedback.mediumImpact();

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        // User cancelled camera
        return;
      }

      setState(() {
        _capturedImage = image;
        _state = CameraState.captured;
      });

      // Auto-verify after brief pause
      await Future.delayed(const Duration(milliseconds: 500));
      _verifyPhoto();
    } catch (e) {
      print('[MedCamera] Error capturing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Kamera tidak dapat dibuka',
            style: TextStyle(fontSize: 20),
          ),
          backgroundColor: KampungCareTheme.urgentRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _verifyPhoto() async {
    setState(() => _state = CameraState.verifying);

    try {
      // Read image bytes for AI verification
      final bytes = _capturedImage != null
          ? await _capturedImage!.readAsBytes()
          : null;

      final result = await ServiceLocator.ai.verifyMedication(
        bytes,
        [], // In real impl, pass expected medications
      );

      final isCorrect = result['correct'] == true;

      setState(() {
        _verificationResult = result;
        _state = isCorrect ? CameraState.verified : CameraState.failed;
      });

      HapticFeedback.mediumImpact();

      // Auto-return after 3 seconds on success
      if (isCorrect) {
        _autoReturnTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            context.go(AppRoutes.medication);
          }
        });
      }
    } catch (e) {
      print('[MedCamera] Verification error: $e');
      setState(() {
        _state = CameraState.failed;
        _verificationResult = {
          'correct': false,
          'notes': 'Pengesahan gagal. Sila cuba lagi.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(
        backgroundColor: KampungCareTheme.calmBlue,
        foregroundColor: KampungCareTheme.textOnDark,
        leading: Semantics(
          button: true,
          label: 'Kembali ke senarai ubat',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.medication);
            },
          ),
        ),
        title: const Text(
          'Sahkan Ubat',
          style: TextStyle(
            fontSize: AppConstants.headerTextSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Main content area
              Expanded(
                child: _buildContent(),
              ),

              // Bottom actions
              _buildBottomActions(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case CameraState.ready:
        return _buildReadyState();
      case CameraState.captured:
      case CameraState.verifying:
        return _buildVerifyingState();
      case CameraState.verified:
        return _buildVerifiedState();
      case CameraState.failed:
        return _buildFailedState();
    }
  }

  Widget _buildReadyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: KampungCareTheme.calmBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: KampungCareTheme.calmBlue,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            size: 72,
            color: KampungCareTheme.calmBlue,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ambil gambar ubat anda',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: KampungCareTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Letakkan semua ubat di atas meja\ndan ambil gambar yang jelas',
          style: TextStyle(
            fontSize: AppConstants.minTextSize,
            color: KampungCareTheme.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerifyingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Show captured photo
        if (_capturedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(_capturedImage!.path),
              width: 240,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 24),
        if (_state == CameraState.verifying) ...[
          const CircularProgressIndicator(
            color: KampungCareTheme.calmBlue,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Memeriksa ubat...',
            style: TextStyle(
              fontSize: AppConstants.minTextSize,
              color: KampungCareTheme.calmBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerifiedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Checkmark
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: KampungCareTheme.primaryGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 80,
            color: KampungCareTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Betul!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: KampungCareTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _verificationResult?['notes'] as String? ??
              'Semua ubat dikenal pasti dengan betul.',
          style: const TextStyle(
            fontSize: AppConstants.minTextSize,
            color: KampungCareTheme.textPrimary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Kembali dalam 3 saat...',
          style: TextStyle(
            fontSize: 18,
            color: KampungCareTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: KampungCareTheme.warningAmber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_rounded,
            size: 80,
            color: KampungCareTheme.warningAmber,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tidak pasti',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: KampungCareTheme.warningAmber,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _verificationResult?['notes'] as String? ??
              'Gambar tak jelas. Boleh ambil lagi?',
          style: const TextStyle(
            fontSize: AppConstants.minTextSize,
            color: KampungCareTheme.textPrimary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    switch (_state) {
      case CameraState.ready:
        return Semantics(
          button: true,
          label: 'Ambil gambar ubat',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _capturePhoto,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  color: KampungCareTheme.calmBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: KampungCareTheme.calmBlue.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt_rounded,
                        size: 32, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      BmStrings.ambilGambar,
                      style: TextStyle(
                        fontSize: AppConstants.buttonTextSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case CameraState.captured:
      case CameraState.verifying:
        return const SizedBox.shrink();

      case CameraState.verified:
        return Semantics(
          button: true,
          label: 'Kembali ke senarai ubat',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.mediumImpact();
                context.go(AppRoutes.medication);
              },
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  color: KampungCareTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Kembali',
                    style: TextStyle(
                      fontSize: AppConstants.buttonTextSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      case CameraState.failed:
        return Column(
          children: [
            Semantics(
              button: true,
              label: 'Cuba lagi ambil gambar',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _state = CameraState.ready);
                    _capturePhoto();
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 64),
                    decoration: BoxDecoration(
                      color: KampungCareTheme.calmBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        BmStrings.cubaLagi,
                        style: TextStyle(
                          fontSize: AppConstants.buttonTextSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: 'Kembali ke senarai ubat',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.medication);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontSize: AppConstants.minTextSize,
                        color: KampungCareTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
