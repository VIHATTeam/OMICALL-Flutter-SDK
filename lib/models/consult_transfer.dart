/// Consult (attended) transfer models — same values on Android SDK 2.9.1 and iOS OmiKit 1.12.0.

/// Result of [OmicallClient.startConsultCall].
enum OmiConsultStartStatus {
  success, // 200
  emptyExtension, // 402
  canNotCallYourself, // 403
  switchboardNotConnected, // 404
  missingAudioPermission, // 405
  noActiveCall, // 409
  consultInProgress, // 410
  videoCallNotSupported, // 411
  sameAsCustomer, // 412
  unknown, // native returned a code this plugin version does not know
}

const _consultStartStatusCodes = <OmiConsultStartStatus, int>{
  OmiConsultStartStatus.success: 200,
  OmiConsultStartStatus.emptyExtension: 402,
  OmiConsultStartStatus.canNotCallYourself: 403,
  OmiConsultStartStatus.switchboardNotConnected: 404,
  OmiConsultStartStatus.missingAudioPermission: 405,
  OmiConsultStartStatus.noActiveCall: 409,
  OmiConsultStartStatus.consultInProgress: 410,
  OmiConsultStartStatus.videoCallNotSupported: 411,
  OmiConsultStartStatus.sameAsCustomer: 412,
  OmiConsultStartStatus.unknown: -1,
};

extension ExtensionOmiConsultStartStatus on OmiConsultStartStatus {
  int get rawValue => _consultStartStatusCodes[this]!;

  static OmiConsultStartStatus fromRaw(dynamic value) {
    final code = (value as num?)?.toInt();
    return _consultStartStatusCodes.entries
        .firstWhere(
          (e) => e.value == code,
          orElse: () => const MapEntry(OmiConsultStartStatus.unknown, -1),
        )
        .key;
  }
}

/// State of the consult leg.
enum OmiConsultState {
  dialing, // 0
  ringing, // 1
  answered, // 2
  ended, // 3
}

OmiConsultState _consultStateFromRaw(dynamic value) {
  final index = (value as num?)?.toInt() ?? OmiConsultState.ended.index;
  if (index < 0 || index >= OmiConsultState.values.length) {
    return OmiConsultState.ended;
  }
  return OmiConsultState.values[index];
}

/// Event `CONSULT_STATE_CHANGED`.
class OmiConsultStateEvent {
  /// OMISIP id of the consult call; -1 for the first DIALING, before the id is known.
  final int callId;

  /// Call UUID (iOS only; null on Android).
  final String? uuid;
  final OmiConsultState state;

  /// 180/183 ringing, 200 answered, final SIP code when ended, 0 without a SIP response.
  final int statusCode;

  const OmiConsultStateEvent({
    required this.callId,
    this.uuid,
    required this.state,
    required this.statusCode,
  });

  factory OmiConsultStateEvent.fromMap(Map data) {
    return OmiConsultStateEvent(
      callId: (data['callId'] as num?)?.toInt() ?? -1,
      uuid: data['uuid'] as String?,
      state: _consultStateFromRaw(data['state']),
      statusCode: (data['statusCode'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() =>
      'OmiConsultStateEvent(callId: $callId, state: $state, statusCode: $statusCode)';
}

/// Event `TRANSFER_STATUS` — REFER progress of [transferCall] and [completeConsultTransfer].
class OmiTransferStatusEvent {
  final int callId;
  final String? uuid;
  final int statusCode;

  /// Last notification of this transfer.
  final bool isFinal;

  const OmiTransferStatusEvent({
    required this.callId,
    this.uuid,
    required this.statusCode,
    required this.isFinal,
  });

  /// Transfer accepted by the PBX (final 2xx).
  bool get isSuccess => isFinal && statusCode >= 200 && statusCode < 300;

  factory OmiTransferStatusEvent.fromMap(Map data) {
    return OmiTransferStatusEvent(
      callId: (data['callId'] as num?)?.toInt() ?? -1,
      uuid: data['uuid'] as String?,
      statusCode: (data['statusCode'] as num?)?.toInt() ?? 0,
      isFinal: data['isFinal'] == true,
    );
  }

  @override
  String toString() =>
      'OmiTransferStatusEvent(callId: $callId, statusCode: $statusCode, isFinal: $isFinal)';
}

/// Event `CALL_HOLD_CHANGED` — hold state of any call (customer or consult).
class OmiCallHoldEvent {
  final int callId;
  final String? uuid;
  final bool isHold;

  const OmiCallHoldEvent({required this.callId, this.uuid, required this.isHold});

  factory OmiCallHoldEvent.fromMap(Map data) {
    return OmiCallHoldEvent(
      callId: (data['callId'] as num?)?.toInt() ?? -1,
      uuid: data['uuid'] as String?,
      isHold: data['isHold'] == true,
    );
  }

  @override
  String toString() => 'OmiCallHoldEvent(callId: $callId, isHold: $isHold)';
}

/// One live call, from [OmicallClient.getActiveCalls].
class OmiCallSummary {
  final int callId;
  final String uuid;

  /// Extension for the consult call, customer number for the customer call.
  final String number;

  /// OMICallState value (see `OmiCallState`).
  final int state;
  final bool isHold;
  final bool isConsult;

  const OmiCallSummary({
    required this.callId,
    required this.uuid,
    required this.number,
    required this.state,
    required this.isHold,
    required this.isConsult,
  });

  factory OmiCallSummary.fromMap(Map data) {
    return OmiCallSummary(
      callId: (data['callId'] as num?)?.toInt() ?? -1,
      uuid: data['uuid']?.toString() ?? '',
      number: data['number']?.toString() ?? '',
      state: (data['state'] as num?)?.toInt() ?? 0,
      isHold: data['isHold'] == true,
      isConsult: data['isConsult'] == true,
    );
  }

  @override
  String toString() =>
      'OmiCallSummary(callId: $callId, number: $number, state: $state, isHold: $isHold, isConsult: $isConsult)';
}
