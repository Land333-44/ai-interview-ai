import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/analysis_session_args.dart';
import '../models/session_type.dart';
import '../services/api_service.dart';
import 'results_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key, this.args});

  static const String routeName = '/analysis';

  final AnalysisSessionArgs? args;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late AnimationController _spinController;
  final List<bool> _stepDone = [false, false, false, false];
  String? _error;

  List<String> get _steps {
    final type = widget.args?.type ?? SessionType.text;
    switch (type) {
      case SessionType.text:
        return [
          'Envoi du texte à l\'IA...',
          'Groq : analyse du feedback...',
          'Hume : analyse émotionnelle...',
          'Préparation de vos résultats...',
        ];
      case SessionType.audio:
        return [
          'Chargement de l\'audio...',
          'Whisper : transcription vocale...',
          'Groq + Hume : analyse...',
          'Préparation de vos résultats...',
        ];
      case SessionType.image:
        return [
          'Chargement de l\'image...',
          'Vision IA : analyse de la présence...',
          'Groq : feedback coaching...',
          'Préparation de vos résultats...',
        ];
      case SessionType.video:
        return [
          'Chargement de la vidéo...',
          'IA : analyse de la prestation...',
          'Calcul du score de session...',
          'Préparation de vos résultats...',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final args = widget.args;
    if (args == null) {
      setState(() => _error = 'Aucune donnée de session');
      return;
    }

    _markStep(0);

    final result = await _api.analyzeSession(
      type: args.type,
      text: args.text,
      filePath: args.filePath,
      fileName: args.fileName,
      fileBytes: args.fileBytes,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() => _error = result.error ?? 'Analyse échouée');
      return;
    }

    _markStep(1);
    await Future.delayed(const Duration(milliseconds: 400));
    _markStep(2);
    await Future.delayed(const Duration(milliseconds: 400));

    await _api.saveAnalysisToDatabase(
      result: result,
      title: args.scenarioTitle ?? '${args.type.name} Session',
      analysisType: args.type.name,
    );

    _markStep(3);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    context.go(ResultsPage.routeName, extra: result,
    );
  }

  void _markStep(int index) {
    if (!mounted) return;
    setState(() {
      if (index < _stepDone.length) _stepDone[index] = true;
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _spinController,
                  child: Container(
                    height: 72,
                    width: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _error != null
                              ? Icons.error_outline_rounded
                              : Icons.psychology_rounded,
                          color: _error != null
                              ? AppColors.danger
                              : AppColors.skyDark,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _error != null ? 'Analyse Échouée' : 'Analyse en cours...',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ??
                      'Groq + Hume traitent votre contenu.\nCela prend quelques secondes.',
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Retour',
                      style: AppTextStyles.button
                          .copyWith(color: AppColors.skyDark),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 48),
                  ...List.generate(_steps.length, (i) {
                    final done = i < _stepDone.length && _stepDone[i];
                    final active = !done &&
                        (i == 0 || (i > 0 && _stepDone[i - 1]));

                    return AnimatedOpacity(
                      opacity: done || active ? 1.0 : 0.35,
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.primaryLight
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: done
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (done)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 22)
                            else if (active)
                              const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              )
                            else
                              const Icon(Icons.circle_outlined,
                                  color: AppColors.muted, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _steps[i],
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  fontWeight:
                                      done ? FontWeight.bold : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}