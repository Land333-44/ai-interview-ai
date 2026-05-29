class AppwriteConstants {
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = '6a10c9d5003b379b2981';
  static const String databaseId = '6a10d139002c0b99c416';

  static const String profilesCollection = 'profiles';
  static const String analysesCollection = 'analyses';
  static const String chatMessagesCollection = 'chatmessages';
  static const String notificationsCollection = 'notifications';

  static const String uploadsBucket = '6a11a23f0037ec3d8078';
  static const String storageBucketId = uploadsBucket;

  // ─── ai-interview-ai (GitHub: Land333-44/ai-interview-ai) ───────────────
  /// Function display name in Appwrite Console
  static const String aiInterviewFunctionName = 'ai-interview-ai';

  /// Function ID — Appwrite Console → Functions → ai-interview-ai → Settings → ID
  /// (NOT the deployment ID)
  static const String aiInterviewFunctionId = '6a142acd003e45e8cb2b';

  /// Active deployment ID (reference only — do not use in createExecution)
  static const String aiInterviewDeploymentId = '6a149393780662168918';

  /// Active deployment URL (HTTP fallback)
  static const String aiInterviewDeploymentUrl =
      'https://6a142ace00114bc266e3.fra.appwrite.run/';

  /// Alias used by FunctionService
  static const String analyzeTextFunctionId = aiInterviewFunctionId;
  static const String analyzeTextFunctionUrl = aiInterviewDeploymentUrl;
}
