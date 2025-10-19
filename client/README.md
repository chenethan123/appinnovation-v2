# FormulaQuizzer Client

Flutter mobile app that connects to FormulaQuizzer Server with offline-first architecture.

## Features

✅ **Server Integration**
- Connects to FormulaQuizzer Server API (port 3000)
- Real-time subject management
- AI-powered question generation via server
- Quiz sessions with instant feedback

✅ **Offline-First Architecture**
- SQLite local database
- Works offline with cached data
- Auto-syncs when server available
- Server status indicator

✅ **User Interface**
- Material 3 design
- Dark/Light mode support
- Responsive layout
- Beautiful animations

✅ **Quiz Features**
- Multiple choice questions
- Difficulty levels (easy/medium/hard)
- Real-time scoring
- Detailed explanations
- Progress tracking

## Architecture

```
lib/
├── config/
│   └── api_config.dart           # API endpoints and config
├── models/
│   ├── subject.dart              # Subject model
│   ├── question.dart             # Question model
│   └── quiz_session.dart         # Quiz session model
├── database/
│   └── database_helper.dart      # SQLite database
├── services/
│   └── api_service.dart          # HTTP API client
├── providers/
│   ├── subject_provider.dart     # Subject state management
│   └── quiz_provider.dart        # Quiz state management
├── screens/
│   ├── home_screen.dart          # Main screen with subjects
│   ├── add_subject_screen.dart   # Create new subject
│   └── quiz_screen.dart          # Take quiz
├── widgets/
│   └── subject_card.dart         # Subject display card
└── main.dart                     # App entry point
```

## Setup

### Prerequisites
- Flutter 3.5.0+
- Dart 3.5.0+
- FormulaQuizzer Server running (see ../server/)

### Installation

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Configure server URL:**
Edit `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:3000';
```

For physical device, use your computer's IP:
```dart
static const String baseUrl = 'http://192.168.1.XXX:3000';
```

3. **Run the app:**
```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# macOS Desktop
flutter run -d macos
```

## Usage

### 1. Start the Server

First, make sure the FormulaQuizzer Server is running:

```bash
cd ../server
npm run dev
```

You should see:
```
🚀 FormulaQuizzer Server Started
📍 Server running at: http://localhost:3000
```

### 2. Launch the App

```bash
flutter run
```

The app will:
- ✅ Check server health
- ✅ Load subjects from server
- ✅ Cache data locally for offline use
- ✅ Show "Online" indicator when connected

### 3. Create a Subject

1. Tap the **+** button
2. Enter subject name (e.g., "AP Physics 1")
3. Enter description
4. Choose a color
5. Tap "Create Subject"

The subject is:
- ✅ Created on server via API
- ✅ Saved to local SQLite database
- ✅ Available immediately

### 4. Take a Quiz

1. Tap on a subject card
2. Tap "Start Quiz (5 Questions)"
3. The server will:
   - Use existing questions if available
   - Generate new ones with AI if needed
4. Answer each question
5. See immediate feedback with explanations
6. Complete quiz to see final score

## Offline Mode

The app works offline with cached data:

**Offline Capabilities:**
- ✅ View cached subjects
- ✅ Access previously loaded questions
- ✅ Continue incomplete quizzes
- ✅ View past quiz results

**Online Required:**
- ❌ Create new subjects
- ❌ Generate new AI questions
- ❌ Start new quiz sessions
- ❌ Sync progress to server

**Auto-Sync:**
- App automatically syncs when connection restored
- Pull to refresh to force sync
- Server status shown in top right

## Server API Integration

The app uses these endpoints:

```
Health Check
  GET  /api/v1/health

Subjects
  GET    /api/v1/subjects
  POST   /api/v1/subjects
  DELETE /api/v1/subjects/:id

AI Generation
  POST   /api/v1/ai/generate-question
  POST   /api/v1/ai/generate-questions-batch

Quiz
  POST   /api/v1/quiz/start
  POST   /api/v1/quiz/answer
  POST   /api/v1/quiz/complete
```

## Data Flow

### Creating a Subject
```
User Input → API Service → Server POST /subjects
         ← Subject returned ←
Database Helper → SQLite INSERT
Provider Update → UI Refresh
```

### Starting a Quiz
```
User Tap → API Service → Server POST /quiz/start
        ← Questions returned ← (may trigger AI generation)
Database Helper → Cache questions locally
Provider Update → Show quiz UI
```

### Answering Questions
```
User Answer → API Service → Server POST /quiz/answer
           ← Result + Explanation ←
Database Helper → Save answer locally
Provider Update → Show feedback UI
```

## Development

### Add New Feature

1. **Add Model** (if needed)
```dart
// lib/models/your_model.dart
class YourModel {
  // Add fromJson, toJson, toMap, fromMap
}
```

2. **Update API Service**
```dart
// lib/services/api_service.dart
Future<YourModel> yourEndpoint() async {
  // HTTP request
}
```

3. **Update Database**
```dart
// lib/database/database_helper.dart
// Add table, CRUD operations
```

4. **Create Provider**
```dart
// lib/providers/your_provider.dart
class YourNotifier extends StateNotifier<YourState> {
  // State management
}
```

5. **Build UI**
```dart
// lib/screens/your_screen.dart
// Use ref.watch(yourProvider)
```

### Code Standards

**Following Flutter Best Practices:**
- ✅ Always add `if (!mounted) return;` before `setState()`
- ✅ Use try-catch for all async operations
- ✅ Implement loading states
- ✅ Show user-friendly error messages
- ✅ Use `const` constructors where possible
- ✅ Dispose controllers in `dispose()`

**State Management:**
- Use Riverpod `StateNotifier` for complex state
- Use `Consumer` for reactive UI
- Use `ref.read()` for one-time actions

**API Calls:**
- Always handle network errors
- Implement timeouts
- Fall back to local data when offline
- Log API calls for debugging

## Troubleshooting

### "Server unavailable" Error

**Check:**
1. Is the server running? `cd ../formula_quizzer_server && npm run dev`
2. Correct URL in `api_config.dart`?
3. Using device IP (not localhost) for physical devices?

**Fix:**
```dart
// For physical device, use your computer's IP
static const String baseUrl = 'http://192.168.1.100:3000';
```

### "Failed to load subjects"

**Solutions:**
1. Check server health: `curl http://localhost:3000/api/v1/health`
2. Pull to refresh in app
3. Check server logs for errors
4. Restart both server and app

### Database Issues

**Reset database:**
```bash
flutter clean
flutter pub get
flutter run
```

Or clear app data on device.

### Build Errors

```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Testing

### Manual Testing Checklist

- [ ] ✅ App starts without errors
- [ ] ✅ Server status indicator works
- [ ] ✅ Can create subject
- [ ] ✅ Can delete subject
- [ ] ✅ Can start quiz
- [ ] ✅ Can answer questions
- [ ] ✅ See correct/incorrect feedback
- [ ] ✅ Complete quiz and see score
- [ ] ✅ Pull to refresh works
- [ ] ✅ Offline mode works
- [ ] ✅ Data persists after app restart

### Test Scenarios

**1. Online Mode:**
```bash
# Server running, app connected
- Create subject → Should sync to server
- Start quiz → Should get questions from server
- Complete quiz → Should save to server
```

**2. Offline Mode:**
```bash
# Stop server, app offline
- View subjects → Should show cached subjects
- Try to create subject → Should show error
- Pull to refresh → Should show "offline" message
```

**3. Sync on Reconnect:**
```bash
# Start server again
- Pull to refresh → Should sync with server
- All cached data should merge with server data
```

## Production Deployment

### For iOS

```bash
flutter build ios --release
# Open in Xcode and submit to App Store
```

### For Android

```bash
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### Update Server URL

Before deploying, update to production URL:

```dart
// lib/config/api_config.dart
static const String baseUrl = 'https://your-server.com';
```

## Project Stats

```
Models:       3 (Subject, Question, QuizSession)
Screens:      3 (Home, AddSubject, Quiz)
Providers:    2 (Subject, Quiz)
Services:     1 (API)
Database:     SQLite with 4 tables
Dependencies: 12 packages
```

## License

MIT License - See LICENSE file

## Support

For issues and questions:
1. Check documentation in `../server/`
2. Review QUICK_START.md in server directory
3. Check server is healthy: http://localhost:3000/api/v1/health

---

**Built with ❤️ using Flutter and FormulaQuizzer Server**
