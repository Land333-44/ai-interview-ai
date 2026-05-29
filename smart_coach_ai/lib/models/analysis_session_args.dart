import 'session_type.dart';

/// Arguments passed from UploadPage → AnalysisPage.
class AnalysisSessionArgs {
  const AnalysisSessionArgs({
    required this.type,
    this.text,
    this.filePath,
    this.fileName,
    this.fileBytes,
    this.scenarioTitle,
  });

  final SessionType type;
  final String? text;
  final String? filePath;
  final String? fileName;
  final List<int>? fileBytes;
  final String? scenarioTitle;
}
