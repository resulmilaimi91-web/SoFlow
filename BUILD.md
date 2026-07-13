# SoFlow iOS Native — Build Guide

## Requirements
- macOS 14+ with Xcode 15+
- iOS 17+ target device
- Apple Developer account (free or paid)

## Quick Start (Xcode)

1. Open Xcode → File → New → Project → iOS → App
   - Product Name: `SoFlow`
   - Bundle Identifier: `com.soflow.app`
   - Interface: SwiftUI
   - Language: Swift

2. Copy Sources/ folder into the Xcode project

3. In SoFlowApp.swift, replace with:
```swift
import SwiftUI
import SOFLOWCore

@main
struct SoFlowApp: App {
    var body: some Scene {
        WindowGroup { SplashView() }
    }
}
```

4. Add Info.plist from Assets/ to your project

5. Signing → Team = your Apple ID

6. Build & Run on device

## Sideload (AltStore)

1. Build the .ipa using Xcode (Product → Archive → Distribute)
2. Open AltStore on iPhone → My Apps → + → select .ipa
3. Wait for install

## Troubleshooting

- **No scooters found**: Power on scooter, hold scooter near iPhone
- **Connection drops**: App auto-reconnects up to 10 times
- **"Not connected" error**: Open ScannerView and reconnect
