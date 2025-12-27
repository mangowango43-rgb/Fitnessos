# FitnessOS Quick Start Guide

## Running the App

```bash
# Navigate to project
cd /home/felix/fitnessos

# Run on your device
flutter run

# Or specify device
flutter run --device-id=linux
flutter run --device-id=android
```

## App Navigation Flow

### 1. HOME Tab (Default Landing)
- **Mission Card**: Start workout with "⚡ IGNITE ⚡" button
- **Bio Rings**: View form score (94%) and streak (12 days)
- **Quick Stats**: See workouts, perfect form %, total reps
- **Battle Logs**: Review past workout sessions

### 2. TRAIN Tab
**Before Starting**:
- Tap "START WORKOUT" to begin

**During Workout**:
- Auto rep counting displays in bottom-left
- AI skeleton overlay tracks form
- Real-time feedback ("PERFECT FORM", "ELBOWS IN")
- Tap circular record button to toggle recording
- Tap "FINISH SET" when done

**Rest Period**:
- Large countdown timer
- Options to "SKIP REST" or "END WORKOUT"

### 3. WORKOUTS Tab
**Navigation Path**:
1. Choose category (Muscle Splits, Circuits, Training Splits, At Home, Cardio)
2. For Muscle Splits: Choose muscle group (Chest, Back, Shoulders, Legs, Arms, Core)
3. Browse and tap exercises to add to workout
4. For Circuits: See pre-built workouts with timed exercises
5. For Training Splits: View complete split programs

### 4. YOU Tab
- This week calendar with workout days highlighted
- Overall stats (total workouts, reps, streaks)
- Personal records for major lifts

## Key Features

### Cyber Theme
- **Primary Color**: Cyber Lime (#CCFF00)
- **Animated Background**: Cyber grid with floating particles
- **Glassmorphism**: Frosted glass cards throughout
- **Glow Effects**: Buttons and active elements have cyber lime glow

### Workout Database
- **100+ Exercises** across all categories
- **7 Circuit Workouts** with detailed timing
- **3 Training Split Programs** (PPL, Upper/Lower, Full Body)
- All exercises tagged with difficulty (beginner/intermediate/advanced)

### AI Training Features
- Real-time rep counting
- Form analysis with skeleton overlay
- Perfect form detection with screen flash
- Angle measurements on joints
- Recording capability for review

## Customization

### Change Mission Workout
In `lib/screens/tabs/train_tab.dart`, modify `_currentWorkout` list:
```dart
final List<Map<String, dynamic>> _currentWorkout = [
  {'name': 'Exercise Name', 'sets': 3, 'reps': 10, 'rest': 90},
  // Add more exercises
];
```

### Adjust Colors
In `lib/utils/app_colors.dart`:
```dart
static const cyberLime = Color(0xFFCCFF00);
static const electricCyan = Color(0xFF00F0FF);
static const neonCrimson = Color(0xFFFF003C);
```

### Add New Exercises
In `lib/models/workout_data.dart`, add to appropriate category:
```dart
Exercise(
  id: 'new_exercise',
  name: 'New Exercise',
  difficulty: 'intermediate',
  equipment: 'weights'
),
```

## Tips for Best Experience

1. **Train Tab**: Best viewed in full screen for maximum camera visibility
2. **Bio Rings**: Tap and hold for detailed breakdown (coming soon)
3. **Workouts**: Use search to quickly find exercises (coming soon)
4. **Recording**: Records video for form analysis (requires camera permission)

## What's Next?

Potential enhancements:
- Camera integration for real pose detection
- Save custom workouts
- Progress tracking over time
- Social sharing of achievements
- Voice coaching during workouts
- Music integration
- Apple Watch / Wear OS support

## Troubleshooting

**App won't build?**
```bash
flutter clean
flutter pub get
flutter run
```

**Colors look different?**
- Ensure device is in dark mode
- Check display settings for color calibration

**Animations choppy?**
- Close background apps
- Enable "Developer Mode" and "Disable animations" then re-enable
- Ensure running in Release mode: `flutter run --release`

---

Enjoy your beast mode fitness tracking! 💪⚡🔥

