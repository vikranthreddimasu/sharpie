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
                // Symlinked to ../../../prompts/*.md so the canonical
                // files live at the repo root where contributors expect
                // them. Frontier models use sharpen.md; the on-device
                // Apple Intelligence path uses sharpen-on-device.md
                // (smaller context, simpler instructions).
                .copy("Resources/sharpen.md"),
                .copy("Resources/sharpen-on-device.md")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
