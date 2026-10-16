import 'dart:convert';

/// Result of [OmicallClient.register] / [OmicallClient.registerWithApiKey].
///
/// Same shape on Android and iOS:
/// - 200 `INIT_SUCCESS`
/// - 400 `MISSING_PARAMS`
/// - 500 `INIT_FAILED`
/// - 600 `NETWORK_UNAVAILABLE`
class OmiRegisterResult {
  static const int success = 200;
  static const int missingParams = 400;
  static const int failed = 500;
  static const int networkUnavailable = 600;

  final int statusCode;
  final String message;

  const OmiRegisterResult({required this.statusCode, required this.message});

  bool get isSuccess => statusCode == success;

  /// Native layers answer with a JSON string `{"status": int, "message": String}`.
  factory OmiRegisterResult.fromNative(dynamic raw) {
    try {
      final json = raw is String ? jsonDecode(raw) : raw;
      if (json is Map) {
        return OmiRegisterResult(
          statusCode: (json['status'] as num?)?.toInt() ?? failed,
          message: json['message']?.toString() ?? 'INIT_FAILED',
        );
      }
    } catch (_) {}
    return const OmiRegisterResult(statusCode: failed, message: 'INIT_FAILED');
  }

  @override
  String toString() => 'OmiRegisterResult($statusCode, $message)';
}
