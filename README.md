# FitnessOS

A stunning Flutter fitness and nutrition tracking app with AI-driven insights, beautiful UI, and comprehensive onboarding.

## Features

- 🎯 **Beautiful Onboarding Flow**: 5-screen comprehensive onboarding collecting user goals, equipment, preferences
- 🏠 **Home Tab**: OS mode with pattern drift detection, weekly compliance charts, reality checks
- 💪 **Train Tab**: Dynamic workout generation based on goals and equipment, exercise tracking
- 🍎 **Fuel Tab**: Nutrition tracking with AI fuel analysis, meal logging, pattern insights
- 👤 **You Tab**: 6-week projections, persona council system, weekend pattern analysis
- ⚙️ **Settings**: Full settings page with account, preferences, appearance, legal info
- 🎨 **Pixel-Perfect Design**: Exact recreation of React version with dark gradients and glassmorphism

## Tech Stack

- **Flutter**: Cross-platform mobile framework
- **Riverpod**: Modern state management
- **SharedPreferences**: Settings persistence
- **SQLite**: Local database for workout/nutrition history
- **Smooth Page Indicator**: Beautiful onboarding indicators

## Architecture

- **Models**: Data structures for User, Exercise, Meal, Workout Session, Goal/Equipment configs
- **Providers**: Riverpod providers for state management
- **Services**: Storage service (SharedPreferences), Database service (SQLite), Exercise generator
- **Screens**: Onboarding flow, 4 main tabs (Home, Train, Fuel, You), Settings
- **Utils**: Theme, colors, text styles

## Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart 3.9.2 or higher
- Android Studio / VS Code with Flutter plugins

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/fitnessos.git
cd fitnessos
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Release

Build APK:
```bash
flutter build apk --release
```

Build App Bundle (for Play Store):
```bash
flutter build appbundle --release
```

## CI/CD

The project includes a GitHub Actions workflow that automatically:
- Builds APK and AAB on push to main
- Uploads artifacts
- Creates releases with version tags

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── user_model.dart
│   ├── exercise_model.dart
│   ├── meal_model.dart
│   ├── workout_session_model.dart
│   └── goal_config.dart
├── providers/                   # Riverpod providers
│   ├── user_provider.dart
│   ├── workout_provider.dart
│   ├── nutrition_provider.dart
│   └── settings_provider.dart
├── screens/                     # UI screens
│   ├── onboarding/
│   │   ├── onboarding_main.dart
│   │   ├── welcome_screen.dart
│   │   ├── personal_info_screen.dart
│   │   ├── goal_screen.dart
│   │   ├── equipment_screen.dart
│   │   └── preferences_screen.dart
│   ├── tabs/
│   │   ├── home_tab.dart
│   │   ├── train_tab.dart
│   │   ├── fuel_tab.dart
│   │   └── you_tab.dart
│   ├── home_screen.dart
│   └── settings_screen.dart
├── services/                    # Business logic
│   ├── storage_service.dart
│   ├── database_service.dart
│   └── exercise_generator.dart
└── utils/                       # Theme & constants
    ├── app_colors.dart
    ├── text_styles.dart
    └── app_theme.dart
```

## Design Philosophy

FitnessOS follows a dark, gradient-heavy design with glassmorphism effects. The UI is designed to be:
- **Immersive**: Full-screen gradients and dramatic shadows
- **Tactile**: Glassmorphism and blur effects
- **Informative**: AI-driven insights and pattern detection
- **Adaptive**: Workouts change based on goal and equipment

## License

This project is open source and available under the MIT License.

## Acknowledgments

- Original React design inspiration
- Flutter community for amazing packages
- Riverpod for excellent state management
