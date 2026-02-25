# Salty Dog Mobile

A sleek iOS navigation app designed for sailors and boaters, providing real-time speed, heading, and track recording with a beautiful marine-inspired dark theme.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange?logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Real-Time Navigation Dashboard

- **Live Speed Display** - Large, easy-to-read speed indicator with support for knots, mph, and kph
- **Compass Heading** - Real-time bearing with cardinal direction indicator
- **Direction Indicator** - Visual compass rose showing current heading
- **Clock Display** - 12/24 hour time format options

### Session Tracking

- **Track Recording** - GPS track points captured during navigation
- **Top Speed** - Maximum speed achieved during session
- **Average Speed** - Running average for the session
- **Distance Traveled** - Total distance in nautical miles, miles, or kilometers
- **Session Duration** - Time elapsed since tracking started

### Interactive Track Map

- **Live Track Visualization** - See your route on an interactive map
- **Start/Current Position Markers** - Clear indicators for route endpoints
- **Full-Screen Map View** - Expand map for detailed route inspection
- **MapKit Integration** - Native Apple Maps with satellite/standard views

### Data Export

- **GPX Export** - Standard GPS exchange format for use with other navigation apps
- **CSV Export** - Spreadsheet-compatible format for data analysis

### Settings & Customization

- **Speed Units** - Choose between knots, mph, or kph
- **Time Format** - 12-hour or 24-hour clock
- **Keep Screen On** - Prevent screen dimming during navigation
- **Background Tracking** - Continue recording with the app in background

## Screenshots

|             Navigation              |            Stats             |          Map          |
| :---------------------------------: | :--------------------------: | :-------------------: |
| Main dashboard with speed & heading | Session statistics breakdown | Interactive track map |

## Requirements

- iOS 17.0+
- iPhone or iPad
- Location Services enabled

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/che-effe/salty-dog-ios.git
   ```

2. Open the project in Xcode:

   ```bash
   cd salty-dog-ios
   open "Salty Dog Mobile.xcodeproj"
   ```

3. Select your target device or simulator

4. Build and run (⌘R)

## Project Structure

```
Salty Dog Mobile/
├── SaltyDogApp.swift          # App entry point
├── ContentView.swift          # Main tab view controller
├── Models/
│   ├── LocationManager.swift  # Core location & tracking logic
│   └── Units.swift            # Speed/distance unit conversions
├── Views/
│   ├── MainDashboardView.swift    # Primary navigation display
│   ├── StatsView.swift            # Session statistics
│   ├── SettingsView.swift         # App preferences
│   ├── TrackMapView.swift         # Interactive map component
│   ├── DirectionIndicatorView.swift # Compass heading indicator
│   └── WaveAnimationView.swift    # Animated wave decoration
├── Theme/
│   └── Theme.swift            # Colors, typography, design constants
└── Assets.xcassets/           # App icons and colors
```

## Architecture

The app follows a straightforward SwiftUI architecture:

- **LocationManager** - `@MainActor` class handling all CoreLocation operations, published properties for reactive UI updates
- **SwiftUI Views** - Declarative UI with `@ObservedObject` bindings to LocationManager
- **AppStorage** - Persistent user preferences using UserDefaults
- **Theme** - Centralized design system with custom colors and typography

## Privacy

Salty Dog Mobile prioritizes user privacy:

- **No Data Collection** - All tracking data stays on your device
- **No Analytics** - No third-party tracking or analytics
- **Local Export** - Export your own data whenever you want
- **No Network Requests** - App functions entirely offline

Location data is only used for displaying real-time navigation information and recording your track.

## Permissions

| Permission             | Usage                                         |
| ---------------------- | --------------------------------------------- |
| Location (When In Use) | Real-time speed, heading, and track recording |
| Location (Always)      | Background tracking when enabled (optional)   |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and MapKit
- Marine-inspired design optimized for outdoor visibility
- Designed for sailors, boaters, and water sports enthusiasts

---

**Fair winds and following seas!** ⛵
