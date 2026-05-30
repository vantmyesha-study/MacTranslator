// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacTranslator",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacTranslator",
            path: "Sources/MacTranslator",
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate",
                              "-Xlinker", "__TEXT",
                              "-Xlinker", "__info_plist",
                              "-Xlinker", "Info.plist"])
            ]
        )
    ]
)
