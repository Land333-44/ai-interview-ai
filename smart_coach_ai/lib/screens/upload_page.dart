import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/analysis_session_args.dart';
import '../models/session_type.dart';
import '../services/media_capture_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/sky_button.dart';
import '../widgets/sky_card.dart';
import '../widgets/sky_insight_card.dart';
import '../widgets/tab_bar_vat.dart';
import '../widgets/wave_visualizer.dart';
import '../widgets/web_camera_recorder.dart';
import 'analysis_page.dart';
import 'dashboard_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key, this.scenarioTitle, this.initialTab = 1});

  static const String routeName = '/upload';

  final String? scenarioTitle;

  /// 0=audio, 1=text, 2=video, 3=image
  final int initialTab;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with SingleTickerProviderStateMixin {
  late int _selectedTab;
  bool _isRecording = false;
  bool _isPaused = false;
  int _seconds = 0;
  Timer? _timer;
  String _textContent = '';
  final TextEditingController _textController = TextEditingController();
  final _media = MediaCaptureService();
  String? _audioPath;
  String? _videoPath;
  String? _imagePath;
  String? _videoName;
  String? _imageName;
  List<int>? _videoBytes;
  List<int>? _imageBytes;
  List<int>? _audioBytes;
  String? _audioName;

  // Pulse animation for mic circle
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 3);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final path = await _media.startRecording();
    if (path == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _seconds = 0;
      _audioPath = path;
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) setState(() => _seconds++);
    });
  }

  void _pauseRecording() {
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    final path = await _media.stopRecording();

    List<int>? newBytes;
    if (kIsWeb && path != null && path.startsWith('blob:')) {
      newBytes = await _media.getFileBytes(path);
    }

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _audioPath = path ?? _audioPath;
      if (newBytes != null) _audioBytes = newBytes;
    });
    _showStopDialog();
  }

  void _goToAnalysis(AnalysisSessionArgs args) {
    context.push(AnalysisPage.routeName, extra: args);
  }

  void _launchMediaAnalysis({
    required SessionType type,
    String? path,
    String? name,
    List<int>? bytes,
  }) {
    if (path == null && bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un fichier d\'abord')),
      );
      return;
    }
    _goToAnalysis(
      AnalysisSessionArgs(
        type: type,
        filePath: path,
        fileName: name,
        fileBytes: bytes,
        scenarioTitle: widget.scenarioTitle,
      ),
    );
  }

  void _showStopDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Enregistrement Sauvegardé !',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Durée: ${_formatTime(_seconds)} · Prêt pour l\'analyse.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            SkyButton(
              label: 'Continuer vers l\'analyse →',
              onTap: () {
                Navigator.pop(context);
                _launchMediaAnalysis(
                  type: SessionType.audio,
                  path: _audioPath,
                  name: _audioName ?? 'recording.m4a',
                  bytes: _audioBytes,
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _seconds = 0);
              },
              child: Text(
                'Recommencer',
                style: AppTextStyles.body.copyWith(color: AppColors.skyDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navIcon),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.scenarioTitle ?? 'Nouvelle Session',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              DashboardPage.routeName,
            ),
            child: Text(
              'Annuler',
              style: AppTextStyles.body.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SmartBottomNavBar(currentIndex: 1),
      body: Column(
        children: [
          // Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TabBarVat(
              selectedIndex: _selectedTab,
              onTabChanged: (i) {
                if (_isRecording) _stopRecording();
                setState(() => _selectedTab = i);
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildAudioTab(),
                _buildTextTab(),
                _buildVideoTab(),
                _buildImageTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- VIDEO TAB ----
  Widget _buildVideoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Camera preview placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 280,
              width: double.infinity,
              color: const Color(0xFF1A2332),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white54,
                        size: 52,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aperçu Caméra',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  if (_isRecording)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _RecBadge(seconds: _seconds),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SkyButton(
            label: _videoName ?? 'Choisir depuis la galerie',
            icon: Icons.video_library_rounded,
            onTap: () async {
              final file = await _media.pickVideoFromGallery();
              if (file != null && mounted) {
                final bytes = await file.readAsBytes();
                setState(() {
                  _videoPath = file.path;
                  _videoName = file.name;
                  _videoBytes = bytes;
                });
              }
            },
            height: 44,
          ),
          const SizedBox(height: 16),
          SkyButton(
            label: 'Analyser',
            icon: Icons.arrow_forward_rounded,
            onTap: (_videoPath != null || _videoBytes != null)
                ? () => _launchMediaAnalysis(
                    type: SessionType.video,
                    path: _videoPath,
                    name: _videoName ?? 'video.mp4',
                    bytes: _videoBytes,
                  )
                : null,
            height: 44,
          ),
          SkyButton(
            label: 'Enregistrer une vidéo',
            icon: Icons.videocam_rounded,
            onTap: () async {
              if (kIsWeb) {
                final result = await WebCameraRecorder.show(context);
                if (result != null && mounted) {
                  setState(() {
                    _videoPath = null;
                    _videoName = result.name;
                    _videoBytes = result.bytes.isEmpty ? null : result.bytes;
                  });
                }
              } else {
                final file = await _media.pickVideoFromCamera();
                if (file != null && mounted) {
                  final bytes = await file.readAsBytes();
                  setState(() {
                    _videoPath = file.path;
                    _videoName = file.name;
                    _videoBytes = bytes.isEmpty ? null : bytes;
                  });
                }
              }
            },
            height: 44,
          ),
          const SizedBox(height: 20),
          const SkyInsightCard(
            icon: Icons.tips_and_updates_rounded,
            title: 'Astuce Vidéo',
            insight:
                'Gardez le contact visuel avec la caméra. Un bon éclairage améliore l\'analyse IA.',
          ),
        ],
      ),
    );
  }

  // ---- AUDIO TAB ----
  Widget _buildAudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SkyCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Mic circle with pulse animation
                ScaleTransition(
                  scale: _isRecording
                      ? _pulseAnim
                      : const AlwaysStoppedAnimation(1.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isRecording)
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? AppColors.primary
                              : AppColors.primaryLight,
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          color: _isRecording
                              ? Colors.white
                              : AppColors.skyDark,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Timer
                Text(
                  _formatTime(_seconds),
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 42,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRecording
                      ? (_isPaused ? 'En pause' : 'Enregistrement...')
                      : 'Appuyez pour enregistrer au micro',
                  style: AppTextStyles.body.copyWith(
                    color: _isRecording && !_isPaused
                        ? AppColors.danger
                        : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                // Wave visualizer
                WaveVisualizer(
                  isAnimating: _isRecording && !_isPaused,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 28),
                _buildRecordingControls(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SkyButton(
            label: _audioName ?? 'Uploader un fichier audio',
            icon: Icons.upload_file_rounded,
            onTap: () async {
              final picked = await _media.pickAudioFile();
              if (picked != null && mounted) {
                setState(() {
                  _audioPath = picked.path;
                  _audioBytes = picked.bytes;
                  _audioName = picked.name;
                });
              }
            },
            height: 44,
          ),
          const SizedBox(height: 12),
          SkyButton(
            label: 'Analyser',
            icon: Icons.arrow_forward_rounded,
            onTap: (_audioPath != null || _audioBytes != null)
                ? () => _launchMediaAnalysis(
                    type: SessionType.audio,
                    path: _audioPath,
                    name: _audioName ?? 'audio.m4a',
                    bytes: _audioBytes,
                  )
                : null,
            height: 44,
          ),
          const SizedBox(height: 20),
          const SkyInsightCard(
            icon: Icons.record_voice_over_rounded,
            title: 'Astuce Audio',
            insight:
                'Enregistrez avec le micro ou uploadez un fichier audio. Fonctionne sur téléphone et navigateur.',
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isRecording)
          SkyButton(
            label: 'Démarrer l\'enregistrement',
            icon: Icons.fiber_manual_record_rounded,
            onTap: _startRecording,
          )
        else ...[
          // Pause
          IconButton(
            onPressed: _pauseRecording,
            icon: Icon(
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: AppColors.skyDark,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          // Stop
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---- IMAGE TAB ----
  Widget _buildImageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 220,
              width: double.infinity,
              color: AppColors.primaryLight,
              child: _imageBytes != null
                  ? Image.memory(
                      Uint8List.fromList(_imageBytes!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_rounded,
                          color: AppColors.skyDark,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _imageName ?? 'Aucune photo sélectionnée',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SkyButton(
                  label: 'Galerie',
                  icon: Icons.photo_library_rounded,
                  onTap: () async {
                    final file = await _media.pickImageFromGallery();
                    if (file != null && mounted) {
                      final bytes = await file.readAsBytes();
                      setState(() {
                        _imagePath = file.path;
                        _imageName = file.name;
                        _imageBytes = bytes;
                      });
                    }
                  },
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkyButton(
                  label: 'Appareil photo',
                  icon: Icons.camera_alt_rounded,
                  onTap: () async {
                    final file = await _media.pickImageFromCamera();
                    if (file != null && mounted) {
                      final bytes = await file.readAsBytes();
                      setState(() {
                        _imagePath = file.path;
                        _imageName = file.name;
                        _imageBytes = bytes;
                      });
                    }
                  },
                  height: 44,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SkyButton(
            label: 'Analyser',
            icon: Icons.arrow_forward_rounded,
            onTap: (_imagePath != null || _imageBytes != null)
                ? () => _launchMediaAnalysis(
                    type: SessionType.image,
                    path: _imagePath,
                    name: _imageName ?? 'image.jpg',
                    bytes: _imageBytes,
                  )
                : null,
          ),
          const SizedBox(height: 20),
          const SkyInsightCard(
            icon: Icons.face_retouching_natural_rounded,
            title: 'Astuce Photo',
            insight:
                'Utilisez une photo claire et bien éclairée montrant votre posture et expression.',
          ),
        ],
      ),
    );
  }

  // ---- TEXT TAB ----
  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COLLER OU TAPER VOTRE TEXTE', style: AppTextStyles.label),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: 10,
                  maxLength: 5000,
                  onChanged: (v) => setState(() => _textContent = v),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Tapez votre discours, réponse d\'entretien, ou collez un texte...',
                    hintStyle: AppTextStyles.caption,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.skyDark,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_textContent.length}/5000 caractères',
                  style: AppTextStyles.caption.copyWith(
                    color: _textContent.length > 4500
                        ? AppColors.danger
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Upload from file
          GestureDetector(
            onTap: () async {
              final content = await _media.pickTextFile();
              if (content != null && mounted) {
                _textController.text = content;
                setState(() => _textContent = content);
              }
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.skyDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Parcourir les documents (.txt)',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.skyDark,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SkyInsightCard(
            icon: Icons.description_rounded,
            title: 'Astuce Texte',
            insight:
                'Collez un texte. Un minimum de 100 mots donne une meilleure analyse.',
          ),
          const SizedBox(height: 20),
          SkyButton(
            label: 'Analyser',
            icon: Icons.arrow_forward_rounded,
            onTap: _textContent.trim().isEmpty
                ? null
                : () => _goToAnalysis(
                    AnalysisSessionArgs(
                      type: SessionType.text,
                      text: _textContent.trim(),
                      scenarioTitle: widget.scenarioTitle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecBadge extends StatefulWidget {
  const _RecBadge({required this.seconds});
  final int seconds;

  @override
  State<_RecBadge> createState() => _RecBadgeState();
}

class _RecBadgeState extends State<_RecBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.3).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _anim,
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'REC  ${_fmt(widget.seconds)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}