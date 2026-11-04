// swift-tools-version: 5.9
// Swift Package Manager manifest of the plugin, alongside `ios/omicall_flutter_plugin.podspec`.
//
// Keep the OmiKit version here and in the podspec in sync. Apps on CocoaPods are unchanged;
// apps with Swift Package Manager enabled get this package from Flutter.
//
// Sources are not duplicated: `Sources/omicall_flutter_plugin/*` are symlinks to `../Classes`,
// except `OmikitPluginShim.swift` (SPM only).
//
// No `FlutterFramework` path dependency (unlike the current Flutter template): a relative path
// dependency makes SwiftPM resolve this package by its real directory, whose name differs from the
// `.packages/<plugin>-<version>` symlink Flutter uses → "unable to override package ... identity"
// at resolve time. The Flutter tool links Flutter into the generated package itself.
import PackageDescription

let package = Package(
    name: "omicall_flutter_plugin",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "omicall-flutter-plugin", targets: ["omicall_flutter_plugin"])
    ],
    dependencies: [
        // upToNextMinor: take 1.12.x fixes, never 1.13 automatically
        .package(url: "https://github.com/VIHATTeam/OmiKit.git", .upToNextMinor(from: "1.12.3"))
    ],
    targets: [
        // Swift only. `Classes/OmikitPlugin.m` (CocoaPods) is replaced by OmikitPluginShim.swift:
        // the .m imports the Swift header of this very target, which would be a dependency cycle.
        .target(
            name: "omicall_flutter_plugin",
            dependencies: [
                .product(name: "OmiKit", package: "OmiKit")
            ]
        )
    ]
)
