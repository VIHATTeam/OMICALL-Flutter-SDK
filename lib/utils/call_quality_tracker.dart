import '../models/call_quality_info.dart';

/// Tracks call quality and LCN (Loss Connect Number) to determine network health
class CallQualityTracker {
  int _lastLcnValue = 0;
  int _consecutiveSameLcnCount = 0;

  /// Threshold for showing loading indicator
  static const int loadingThreshold = 3;

  /// Parse call quality data from native event
  ///
  /// Example usage:
  /// ```dart
  /// final tracker = CallQualityTracker();
  ///
  /// OmicallClient.instance.setCallQualityListener((data) {
  ///   final info = tracker.parseCallQuality(data);
  ///
  ///   // Handle loading indicator
  ///   if (info.shouldShowLoading) {
  ///     EasyLoading.show();
  ///   } else {
  ///     EasyLoading.dismiss();
  ///   }
  ///
  ///   // Display MOS score
  ///   setState(() {
  ///     callQuality = info.mosDisplay;
  ///   });
  /// });
  /// ```
  CallQualityInfo parseCallQuality(Map<dynamic, dynamic> data) {
    final quality = data["quality"] as int? ?? 0;
    final stat = data["stat"] as Map<dynamic, dynamic>? ?? {};

    final currentLcnValue = stat["lcn"] as int? ?? 0;
    final mos = (stat["mos"] as num?)?.toDouble() ?? 0.0;
    final jitter = (stat["jitter"] as num?)?.toDouble() ?? 0.0;
    final latency = (stat["latency"] as num?)?.toDouble() ?? 0.0;
    final packetLoss = (stat["ppl"] as num?)?.toDouble() ?? 0.0;
    final requestCount = stat["req"] as int? ?? 0;

    bool shouldShowLoading = false;
    bool isNetworkRecovered = false;

    // Track consecutive same LCN values
    if (currentLcnValue == _lastLcnValue && currentLcnValue != 0) {
      _consecutiveSameLcnCount++;

      // Show loading overlay after threshold consecutive same values (indicating poor network)
      if (_consecutiveSameLcnCount >= loadingThreshold) {
        shouldShowLoading = true;
      }
    } else {
      // LCN value changed or is 0 - network is working
      if (_consecutiveSameLcnCount > 0) {
        isNetworkRecovered = true;
      }
      _consecutiveSameLcnCount = 0;
      shouldShowLoading = false;
    }

    _lastLcnValue = currentLcnValue;

    return CallQualityInfo(
      mos: mos,
      lcn: currentLcnValue,
      quality: quality,
      jitter: jitter,
      latency: latency,
      packetLoss: packetLoss,
      requestCount: requestCount,
      shouldShowLoading: shouldShowLoading,
      isNetworkRecovered: isNetworkRecovered,
      consecutiveSameLcnCount: _consecutiveSameLcnCount,
    );
  }

  /// Reset tracker state (e.g., when call ends)
  void reset() {
    _lastLcnValue = 0;
    _consecutiveSameLcnCount = 0;
  }

  /// Get current tracking state
  Map<String, int> get state => {
    'lastLcnValue': _lastLcnValue,
    'consecutiveSameLcnCount': _consecutiveSameLcnCount,
  };
}
