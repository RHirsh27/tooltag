// swift-tools-version: 5.9
import PackageDescription

#if os(macOS)
let supportedPlatforms: [SupportedPlatform]? = [
    .iOS(.v16)
]
let processlyProducts: [Product] = [
    .iOSApplication(
        name: "Processly",
        targets: ["Processly"],
        bundleIdentifier: "com.example.processly",
        teamIdentifier: "TEAMID",
        displayVersion: "0.1.0",
        bundleVersion: "1",
        appIcon: .assetCatalog(name: "ProcesslyIcon"),
        accentColor: .assetCatalog(name: "AccentColor"),
        supportedDeviceFamilies: [
            .pad,
            .phone
        ],
        supportedInterfaceOrientations: [
            .iphone: [.portrait],
            .ipad: [.portrait]
        ]
    )
]
#else
let supportedPlatforms: [SupportedPlatform]? = nil
let processlyProducts: [Product] = [
    .executable(
        name: "Processly",
        targets: ["Processly"]
    )
]
#endif

let package = Package(
    name: "Processly",
    defaultLocalization: "en",
    platforms: supportedPlatforms,
    products: processlyProducts,
    targets: [
        .executableTarget(
            name: "Processly",
            path: "Sources",
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Resources/Base.lproj"),
                .process("Resources/Localization")
            ]
        ),
        .testTarget(
            name: "ProcesslyTests",
            dependencies: ["Processly"],
            path: "Tests/Unit"
        ),
        .testTarget(
            name: "ProcesslyUITests",
            dependencies: ["Processly"],
            path: "Tests/UITests"
        )
    ]
)
