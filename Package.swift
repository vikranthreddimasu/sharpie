// swift-tools-version: 6.0
// Sharpie is a SwiftPM executable rather than an .xcodeproj. This keeps the
// repo readable in git diffs and makes the prompt the central artifact —
// no project file noise to wade through.

import PackageDescription

let package = Package(
    name: "Sharpie",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Sharpie", targets: ["Sharpie"])
    ],
    targets: [
        .executableTarget(
            name: "Sharpie",
            path: "Sources/Sharpie",
            resources: [
                // Symlinked to ../../../prompts/sharpen.md so the
                // canonical file lives at the repo root where
                // contributors expect it.
                .copy("Resources/sharpen.md")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
