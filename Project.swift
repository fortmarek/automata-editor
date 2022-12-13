import ProjectDescription

func frameworks() -> [String] {
    [
        "alib2abstraction",
        "alib2algo",
        "alib2common",
        "alib2data",
        "alib2measure",
        "alib2std",
        "alib2str",
        "alib2xml",
    ]
}

let project = Project(
    name: "AutomataEditor",
    packages: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "0.19.0")),
        .package(url: "https://github.com/Bersaelor/SwiftSplines", .upToNextMajor(from: "0.3.0")),
    ],
    targets: [
        Target(
            name: "AutomataEditor",
            platform: .iOS,
            product: .app,
            bundleId: "marekfort.AutomataEditor",
            deploymentTarget: .iOS(targetVersion: "14.0", devices: .ipad),
            infoPlist: .file(path: "AutomataEditor/Info.plist"),
            sources: [
                "AutomataEditor/**",
                "automata-editor-model/AutomataClassifier.mlmodel"
            ],
            dependencies: [
                .package(product: "ComposableArchitecture"),
                .package(product: "SwiftSplines"),
                .target(name: "SwiftAutomataLibrary"),
            ]
        ),
        Target(
            name: "AutomataEditorTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "marekfort.AutomataEditorTests",
            infoPlist: .default,
            sources: "AutomataEditorTests/**",
            dependencies: [
                .target(name: "AutomataEditor"),
                .xctest,
            ]
        ),
        Target(
            name: "SwiftAutomataLibrary",
            platform: .iOS,
            product: .framework,
            bundleId: "marekfort.SwiftAutomataLibrary",
            deploymentTarget: .iOS(targetVersion: "14.0", devices: .ipad),
            infoPlist: .default,
            sources: "SwiftAutomataLibrary/**",
            headers: .headers(
                public: nil,
                private: "SwiftAutomataLibrary/**",
                project: nil
            ),
            dependencies: frameworks()
                .map { .xcframework(path: Path($0 + ".xcframework")) },
            settings: .settings(
                base: [
                    "HEADER_SEARCH_PATHS": .array(
                        frameworks().map {
                            "$(SRCROOT)/automata-library/\($0)/src"
                        }
                    ),
                    "SWIFT_OBJC_BRIDGING_HEADER": "$(SRCROOT)/SwiftAutomataLibrary/SwiftAutomataLibrary-BridgingHeader.h",
                    "OTHER_CPLUSPLUSFLAGS": [
                        "$(OTHER_CFLAGS)",
                        "'-std=gnu++17'",
                    ]
                ],
                configurations: [],
                defaultSettings: .recommended
            )
        )
    ]
)
