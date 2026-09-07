class AppwriteConfig {
  AppwriteConfig._();

  static const String endpoint = String.fromEnvironment('APPWRITE_ENDPOINT');

  static const String projectId =
      String.fromEnvironment('APPWRITE_PROJECT_ID');

  static const String bucketId = String.fromEnvironment('APPWRITE_BUCKET_ID');

  static bool get isCloud => endpoint.contains('cloud.appwrite.io');

  static bool get isConfigured =>
      endpoint.isNotEmpty && projectId.isNotEmpty && bucketId.isNotEmpty;
}
