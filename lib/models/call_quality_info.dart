/// Call quality information parsed from network health data
class CallQualityInfo {
  /// MOS (Mean Opinion Score) - call quality score from 1.0 to 5.0
  /// - >= 4.0: Excellent
  /// - 3.5-4.0: Good
  /// - 3.0-3.5: Fair
  /// - 2.0-3.0: Poor
  /// - < 2.0: Bad
  final double mos;

  /// Loss Connect Number - number of connection losses
  final int lcn;

  /// Quality level (0=good, 1=normal, 2=bad)
  final int quality;

  /// Jitter in milliseconds
  final double jitter;

  /// Latency in milliseconds
  final double latency;

  /// Packet loss percentage
  final double packetLoss;

  /// Request count
  final int requestCount;

  /// Whether to show loading indicator based on LCN tracking
  final bool shouldShowLoading;

  /// Whether network has recovered
  final bool isNetworkRecovered;

  /// Consecutive same LCN count
  final int consecutiveSameLcnCount;

  const CallQualityInfo({
    required this.mos,
    required this.lcn,
    required this.quality,
    required this.jitter,
    required this.latency,
    required this.packetLoss,
    required this.requestCount,
    required this.shouldShowLoading,
    required this.isNetworkRecovered,
    required this.consecutiveSameLcnCount,
  });

  /// Get formatted MOS score for display
  String get mosDisplay => mos > 0 ? mos.toStringAsFixed(1) : "";

  /// Get quality level text
  String get qualityText {
    if (mos >= 4.0) return "Excellent";
    if (mos >= 3.5) return "Good";
    if (mos >= 3.0) return "Fair";
    if (mos >= 2.0) return "Poor";
    return "Bad";
  }

  @override
  String toString() {
    return 'CallQualityInfo(mos: $mos, lcn: $lcn, quality: $quality, '
        'shouldShowLoading: $shouldShowLoading, consecutiveSameLcnCount: $consecutiveSameLcnCount)';
  }
}
