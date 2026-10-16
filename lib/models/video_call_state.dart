/// Health of the other party's media during a call (iOS `OMIRemoteConnectionState`).
/// Indexes match the native raw values.
enum OmiRemoteConnectionState {
  /// Audio (and video, if any) arriving normally.
  connected, // 0
  /// Audio arriving, video stopped (remote camera off / app in background).
  videoPaused, // 1
  /// Remote media arriving at a clearly reduced rate.
  weak, // 2
  /// No media from the other party while our network is up — they dropped.
  reconnecting, // 3
  /// Our own device has no network.
  localReconnecting, // 4
  /// Our device just switched network (Wi-Fi ↔ cellular).
  networkSwitching, // 5
  /// The other party reports heavy loss of our media.
  uplinkPoor, // 6
}

extension ExtensionOmiRemoteConnectionState on OmiRemoteConnectionState {
  /// Key the native layer uses for this state (overlay texts).
  String get nativeName => const [
        'connected',
        'videoPaused',
        'weak',
        'reconnecting',
        'localReconnecting',
        'networkSwitching',
        'uplinkPoor',
      ][index];
}

/// Event `REMOTE_CONNECTION_CHANGED` (iOS).
class OmiRemoteConnectionEvent {
  final OmiRemoteConnectionState state;

  /// Seconds the previous problem state lasted (0 when entering one).
  final double duration;

  const OmiRemoteConnectionEvent({required this.state, required this.duration});

  factory OmiRemoteConnectionEvent.fromMap(Map data) {
    final index = (data['state'] as num?)?.toInt() ?? 0;
    final valid = index >= 0 && index < OmiRemoteConnectionState.values.length;
    return OmiRemoteConnectionEvent(
      state: valid
          ? OmiRemoteConnectionState.values[index]
          : OmiRemoteConnectionState.connected,
      duration: (data['duration'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() => 'OmiRemoteConnectionEvent($state, ${duration}s)';
}
