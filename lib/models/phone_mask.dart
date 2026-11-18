/// How the SDK masks phone numbers on its native call UI (Android notification / call screen,
/// iOS CallKit). Values follow the `hide_phone_type` field of the OMI role API; the index is the
/// value sent to the native SDKs (Android `Utils.MaskMode`, iOS `OMIPhoneMaskPolicy`).
enum OmiPhoneMaskMode {
  /// `hide_last_keep_first_3`: 0987654321 → 098******* (default)
  hideLastKeepFirst3,

  /// `hide_last_3`: 0987654321 → 0987654***
  hideLast3,

  /// `hide_last_keep_first_4`: 0987654321 → 0987******
  hideLastKeepFirst4,

  /// `hide_middle_keep_last`: 0987654321 → 0987***321 (web, Android).
  /// iOS OmiKit 1.12.3 keeps 3 leading digits: 098****321.
  hideMiddleKeepLast,
}

const _apiValues = [
  'hide_last_keep_first_3',
  'hide_last_3',
  'hide_last_keep_first_4',
  'hide_middle_keep_last',
];

extension ExtensionOmiPhoneMaskMode on OmiPhoneMaskMode {
  /// Value of `hide_phone_type` in the OMI role API.
  String get apiValue => _apiValues[index];

  /// Mode for a `hide_phone_type` value; unknown or null → [OmiPhoneMaskMode.hideLastKeepFirst3].
  static OmiPhoneMaskMode fromApiValue(String? value) {
    final index = _apiValues.indexOf(value ?? '');
    return index < 0 ? OmiPhoneMaskMode.hideLastKeepFirst3 : OmiPhoneMaskMode.values[index];
  }
}

/// Current masking configuration, from [OmicallClient.getPhoneNumberMask].
class OmiPhoneMaskConfig {
  /// true = numbers are masked on the SDK's native call UI.
  final bool enabled;
  final OmiPhoneMaskMode mode;

  const OmiPhoneMaskConfig({required this.enabled, required this.mode});

  factory OmiPhoneMaskConfig.fromMap(Map data) {
    final index = (data['mode'] as num?)?.toInt() ?? 0;
    final valid = index >= 0 && index < OmiPhoneMaskMode.values.length;
    return OmiPhoneMaskConfig(
      enabled: data['enabled'] == true,
      mode: valid ? OmiPhoneMaskMode.values[index] : OmiPhoneMaskMode.hideLastKeepFirst3,
    );
  }

  @override
  String toString() => 'OmiPhoneMaskConfig(enabled: $enabled, mode: $mode)';
}
