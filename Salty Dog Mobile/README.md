# SaltyDog iOS

A beautiful nautical navigation app for iPhone that displays real-time speed, heading, and track visualization for sailors, boaters, and paddlers.

## Features

- **Real-time Speed Display** - GPS-based speed over ground with support for knots, MPH, and KPH
- **Heading Indicator** - Beautiful wind vane compass with smooth animations
- **Session Tracking** - Top speed, distance traveled, and session duration
- **Track Map** - Interactive map showing your sailing route with MapKit integration
- **Export Functionality** - Export sessions as GPX or CSV for analysis
- **Background Tracking** - Continue recording when the app is in background
- **Landscape Support** - Optimized layouts for both portrait and landscape orientations
- **Dark Mode** - Stunning dark nautical theme with animated waves

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Device with GPS capability

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode and select **File > New > Project**
2. Choose **App** under iOS
3. Set the following options:
   - Product Name: `SaltyDog iOS`
   - Organization Identifier: `com.yourcompany`
   - Interface: SwiftUI
   - Language: Swift
   - Uncheck "Include Tests" (add later if needed)

### 2. Replace Generated Files

Replace the generated files with the ones from this repository:

```
SaltyDog iOS/
├── SaltyDogApp.swift
├── ContentView.swift
├── Info.plist
├── PrivacyInfo.xcprivacy
├── Models/
│   ├── LocationManager.swift
│   └── Units.swift
├── Views/
│   ├── MainDashboardView.swift
│   ├── StatsView.swift
│   ├── SettingsView.swift
│   ├── TrackMapView.swift
│   ├── WaveAnimationView.swift
│   └── DirectionIndicatorView.swift
├── Theme/
│   └── Theme.swift
└── Assets.xcassets/
    ├── Contents.json
    ├── AccentColor.colorset/
    ├── AppIcon.appiconset/
    ├── LaunchBackground.colorset/
    └── LaunchLogo.imageset/
```

### 3. Configure Capabilities

In Xcode, select your target and go to **Signing & Capabilities**:

1. Click **+ Capability**
2. Add **Background Modes**
3. Check **Location updates**

### 4. Add App Icon

Create a 1024x1024 app icon and add it to `Assets.xcassets/AppIcon.appiconset/`

Recommended design:

- Nautical blue gradient background
- Sailboat or compass icon
- Clean, simple design that's recognizable at small sizes

### 5. Build & Run

1. Select your target device or simulator
2. Press **Cmd + R** to build and run
3. Grant location permissions when prompted

## Project Structure

```
SaltyDog iOS/
├── SaltyDogApp.swift          # App entry point with @main
├── ContentView.swift          # TabView navigation container
├── Models/
│   ├── LocationManager.swift  # Core GPS tracking logic
│   └── Units.swift            # Speed/distance conversions
├── Views/
│   ├── MainDashboardView.swift    # Primary navigation display
│   ├── StatsView.swift            # Session statistics
│   ├── SettingsView.swift         # User preferences
│   ├── TrackMapView.swift         # MapKit integration
│   ├── WaveAnimationView.swift    # Animated ocean waves
│   └── DirectionIndicatorView.swift # Compass/wind vane
├── Theme/
│   └── Theme.swift            # Colors, fonts, constants
├── Assets.xcassets/           # Images and colors
├── Info.plist                 # App configuration
└── PrivacyInfo.xcprivacy      # Privacy manifest (required)
```

## Key Design Decisions

### Animations

- **Wave Animation**: Uses sine wave mathematics with three overlapping layers for depth
- **Direction Indicator**: Spring animation for smooth compass rotation
- **Numeric Transitions**: `.contentTransition(.numericText())` for fluid number changes

### Performance

- GPS updates filtered to 5-meter distance for battery efficiency
- Speed threshold (0.3 m/s) to filter GPS noise when stationary
- Minimum accuracy threshold (20m) to reject poor readings

### App Store Compliance

- Privacy Manifest included (required since Spring 2024)
- No third-party SDKs to declare
- Location usage descriptions provided
- No tracking or data collection

## Customization

### Colors

Edit `Theme/Theme.swift` to customize the color palette:

```swift
static let saltyBlue = Color(hex: "47A8FF")     // Primary accent
static let saltyOrange = Color(hex: "FF5722")   // Warnings/current position
static let saltyGreen = Color(hex: "4CAF50")    // Success/start marker
```

### Speed Units

Add new units in `Models/Units.swift`:

```swift
enum SpeedUnit: String, CaseIterable {
    case knots = "kts"
    case mph = "mph"
    case kph = "kph"
    // Add new unit here
}
```

## Testing

### Simulator

Use Xcode's location simulation:

1. Run the app in Simulator
2. Select **Debug > Location > City Run** (or custom GPX)

### Device

For accurate GPS testing, you need a physical device:

1. Connect your iPhone
2. Select it as the run destination
3. Test outdoors for best GPS accuracy

## License

This project is for educational purposes. Customize as needed for your own use.

## Support

For issues or questions, please open a GitHub issue.
