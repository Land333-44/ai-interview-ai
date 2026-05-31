// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Web-only implementation of WebCameraRecorder using standard HTML5 APIs.
class WebCameraRecorder {
  static Future<({List<int> bytes, String name})?> show(
      BuildContext context) async {
    return showDialog<({List<int> bytes, String name})?>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => const _CameraRecorderDialog(),
    );
  }
}

class _CameraRecorderDialog extends StatefulWidget {
  const _CameraRecorderDialog();

  @override
  State<_CameraRecorderDialog> createState() => _CameraRecorderDialogState();
}

class _CameraRecorderDialogState extends State<_CameraRecorderDialog> {
  html.MediaStream? _stream;
  html.MediaRecorder? _recorder;
  final List<html.Blob> _chunks = [];

  bool _isReady = false;
  bool _isRecording = false;
  bool _isStopped = false;
  bool _hasError = false;
  String _errorMsg = '';

  int _seconds = 0;
  Timer? _timer;

  // HtmlElementView id
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'camera_preview_${DateTime.now().millisecondsSinceEpoch}';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'facingMode': 'user'
        },
        'audio': true,
      });
      _stream = stream;

      // Create a <video> element for live camera feed preview
      final video = html.VideoElement()
        ..autoplay = true
        // Mute video so user doesn't hear echo of themselves while recording
        ..muted = true
        ..srcObject = stream;
      
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';
      video.style.borderRadius = '16px';

      // Register the video element factory via dart:ui_web
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => video,
      );

      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = e.toString().contains('Permission') ||
                  e.toString().contains('NotAllowed')
              ? 'Accès refusé à la caméra.\nVeuillez autoriser l\'accès dans les paramètres du navigateur.'
              : 'Impossible d\'accéder à la caméra.\nVeuillez vérifier vos périphériques.';
        });
      }
    }
  }

  void _startRecording() {
    if (_stream == null) return;
    _chunks.clear();

    // Determine standard MIME type support
    final mimeType = _getSupportedMimeType();
    final options = mimeType != null ? {'mimeType': mimeType} : null;

    final recorder = html.MediaRecorder(_stream!, options);

    recorder.addEventListener('dataavailable', (html.Event event) {
      final e = event as html.BlobEvent;
      if (e.data != null && e.data!.size > 0) {
        _chunks.add(e.data!);
      }
    });

    recorder.addEventListener('stop', (html.Event _) => _onRecordingStopped());

    recorder.start(1000); // chunk every 1 second
    _recorder = recorder;

    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });

    setState(() => _isRecording = true);
  }

  void _stopRecording() {
    _timer?.cancel();
    try {
      _recorder?.stop();
    } catch (_) {}
    setState(() {
      _isRecording = false;
      _isStopped = true;
    });
  }

  Future<void> _onRecordingStopped() async {
    if (_chunks.isEmpty) {
      if (mounted) Navigator.of(context).pop(null);
      return;
    }

    final mimeType =
        _chunks.first.type.isNotEmpty ? _chunks.first.type : 'video/webm';
    final blob = html.Blob(_chunks, mimeType);

    // Read the recorded blob into standard bytes
    final reader = html.FileReader();
    final completer = Completer<List<int>>();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is List<int>) {
        completer.complete(result);
      } else {
        // Fallback or conversion
        completer.complete([]);
      }
    });

    reader.onError.listen((_) {
      completer.complete([]);
    });

    reader.readAsArrayBuffer(blob);
    final bytes = await completer.future;

    final ext = mimeType.contains('mp4') ? 'mp4' : 'webm';
    final name = 'interview_${DateTime.now().millisecondsSinceEpoch}.$ext';

    _releaseCamera();
    if (mounted) Navigator.of(context).pop((bytes: bytes, name: name));
  }

  void _cancel() {
    _timer?.cancel();
    try {
      _recorder?.stop();
    } catch (_) {}
    _releaseCamera();
    Navigator.of(context).pop(null);
  }

  void _releaseCamera() {
    try {
      _stream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
  }

  String? _getSupportedMimeType() {
    // Standard web browser video mime types
    const types = [
      'video/webm;codecs=vp9,opus',
      'video/webm;codecs=vp8,opus',
      'video/webm',
      'video/mp4',
    ];
    for (final t in types) {
      try {
        if (html.MediaRecorder.isTypeSupported(t)) return t;
      } catch (_) {}
    }
    return null;
  }

  String get _formattedTime {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _releaseCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Enregistrer une vidéo', style: AppTextStyles.title),
                  const Spacer(),
                  IconButton(
                    onPressed: _cancel,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSoft,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Body ─────────────────────────────────────────────────────────
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _hasError
                    ? _buildError()
                    : !_isReady
                        ? _buildLoading()
                        : _buildPreview(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Controls ─────────────────────────────────────────────────────
            if (!_hasError)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _buildControls(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Connexion à la caméra...'),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.videocam_off_rounded,
                  size: 48, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMsg,
              style: AppTextStyles.body.copyWith(color: AppColors.textSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Fermer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera live feed
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: HtmlElementView(viewType: _viewId),
          ),
        ),

        // REC indicator overlay
        if (_isRecording)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REC  $_formattedTime',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls() {
    if (_isStopped) {
      return const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 12),
            Text('Traitement de la vidéo...'),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('Annuler'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSoft,
            side: const BorderSide(color: AppColors.outline),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 16),
        if (!_isRecording)
          ElevatedButton.icon(
            onPressed: _isReady ? _startRecording : null,
            icon: const Icon(Icons.fiber_manual_record_rounded, size: 20),
            label: const Text('Démarrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop_rounded, size: 20),
            label: Text('Arrêter  $_formattedTime'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }
}
