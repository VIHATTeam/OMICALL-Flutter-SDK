import Flutter

/// Registration class called by `GeneratedPluginRegistrant`.
///
/// `pubspec.yaml` declares `pluginClass: OmikitPlugin` for iOS for both integrations. CocoaPods
/// gets it from `Classes/OmikitPlugin.m`; SPM cannot compile that file (it imports the Swift
/// header of its own target), so the same class is written here in Swift.
///
/// This file exists only in the SPM target (it is not a symlink into `Classes/`), so the
/// CocoaPods build never sees two `OmikitPlugin` classes.
@objc(OmikitPlugin)
public class OmikitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftOmikitPlugin.register(with: registrar)
    }
}
