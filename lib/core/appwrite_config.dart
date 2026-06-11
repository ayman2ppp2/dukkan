class AppwriteConfig {
  AppwriteConfig._();

  static const String endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://cloud.appwrite.io/v1',
  );

  static const String projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '65e616d10bd9110e806f',
  );

  static const String bucketId = String.fromEnvironment(
    'APPWRITE_BUCKET_ID',
    defaultValue: '6762672a0033f48ae769',
  );

  static bool get isCloud => endpoint.contains('cloud.appwrite.io');
}
