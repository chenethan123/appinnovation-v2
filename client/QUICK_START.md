# Quick Start Guide

Get FormulaQuizzer Client running in 5 minutes!

---

## Step 1: Start the Server

The Flutter app needs the server running to work properly.

```bash
# Open a new terminal
cd /Users/ethanchen/Desktop/App\ Innovation/formula_quizzer_unified/server

# Install dependencies (first time only)
npm install

# Start the server
npm run dev
```

**You should see:**
```
┌─────────────────────────────────────────────────────────┐
│  🚀 FormulaQuizzer Server Started                      │
└─────────────────────────────────────────────────────────┘

📍 Server running at: http://localhost:3000
🗄️  Database: In-Memory (Mock)
🤖 OpenAI Model: gpt-4-turbo-preview
```

✅ **Leave this terminal running!**

---

## Step 2: Launch the Flutter App

Open a **new terminal**:

```bash
cd /Users/ethanchen/Desktop/App\ Innovation/formula_quizzer_unified/client

# Install dependencies (first time only)
flutter pub get

# Run the app
flutter run
```

### Choose Your Device:

The terminal will show available devices:
```
Connected devices:
[1]: iPhone 16 Pro (simulator)
[2]: macOS (desktop)
[3]: Chrome (web)
```

Type the number to select a device, or:

```bash
# Run on iOS Simulator
flutter run -d ios

# Run on macOS Desktop
flutter run -d macos

# Run on Android Emulator
flutter run -d android
```

---

## Step 3: Verify Connection

When the app launches, check the **top right corner**:

✅ **"Online"** with green cloud icon = Connected to server  
❌ **"Offline"** with gray cloud icon = Server not reachable

### If Offline:

1. **Check server is running** in first terminal
2. **Check server URL** in `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:3000';
   ```
3. **For physical device**, use your computer's IP:
   ```dart
   static const String baseUrl = 'http://192.168.1.XXX:3000';
   ```
4. **Restart the app** with `r` in the terminal

---

## Step 4: Test the App

### Create Your First Subject

1. Tap the **+** button (bottom right)
2. Enter:
   - **Name**: "AP Physics 1"
   - **Description**: "Algebra-based introductory physics"
   - **Color**: Choose blue
3. Tap **"Create Subject"**

**Expected result:**
- ✅ Subject appears in list
- ✅ Server logs show: `[INFO] Subject created { subjectId: 1, name: 'AP Physics 1' }`
- ✅ Saved to local database

### Take Your First Quiz

1. Tap on the **"AP Physics 1"** card
2. Tap **"Start Quiz (5 Questions)"**
3. Wait 5-10 seconds (server may generate AI questions)
4. Answer the questions
5. See immediate feedback
6. Complete quiz to see your score

**What happens behind the scenes:**
```
App → Server: POST /api/v1/quiz/start
Server: Checking for questions...
Server: Not enough questions, generating with AI...
Server → OpenAI: Generate 5 questions about AP Physics 1
OpenAI → Server: Returns questions (~2-3 seconds each)
Server → App: Quiz session with 5 questions
App: Saves to local database
App: Shows first question
```

---

## Step 5: Test Offline Mode

### Go Offline:

1. **Stop the server** (Ctrl+C in server terminal)
2. **Pull down to refresh** in the app
3. **Check status**: Should show "Offline"

### What Still Works:

✅ View cached subjects  
✅ See previously loaded questions  
✅ Review past quiz results

### What Doesn't Work:

❌ Create new subjects  
❌ Generate new questions  
❌ Start new quizzes  
❌ Sync progress

### Go Back Online:

1. **Restart server**: `npm run dev`
2. **Pull down to refresh** in app
3. **Check status**: Should show "Online"
4. ✅ Everything works again!

---

## Common Issues

### "Connection refused" Error

**Problem**: App can't reach server

**Solutions**:
1. Make sure server is running
2. Check URL in `lib/config/api_config.dart`
3. For physical device, use computer's IP address
4. Restart both server and app

### "No subjects yet"

**Problem**: Empty list on first launch

**Solutions**:
1. This is normal! Server starts with 3 pre-seeded subjects
2. Pull down to refresh
3. Tap + to create your first subject
4. Check server is online

### Questions Take Forever

**Problem**: Quiz won't start

**Reasons**:
- First AI generation takes 2-3 seconds per question
- 5 questions = ~10-15 seconds total
- This is normal!

**Speed it up**:
- Questions are cached on server
- Second quiz for same subject is instant
- Or add manual questions via server API

### App Crashes on Launch

**Solutions**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## Development Workflow

### Making Changes

1. **Edit code** in your IDE
2. **Hot reload**: Press `r` in terminal (instant)
3. **Hot restart**: Press `R` in terminal (fast)
4. **Full restart**: Press `ctrl+c` then `flutter run`

### Common Commands

```bash
# Hot reload (keeps state)
r

# Hot restart (resets state)
R

# Quit
q

# Clear terminal
c

# Show widget inspector
w
```

### Checking Logs

**Server logs** (first terminal):
```
[INFO] Subject created { subjectId: 1, name: 'AP Physics 1' }
[INFO] Quiz session created { sessionId: '...', totalQuestions: 5 }
[INFO] OpenAI.generateQuestion (2340ms)
```

**App logs** (second terminal):
```
[API] Health check: healthy
[API] Fetched 1 subjects
[API] Started quiz session: 550e8400-e29b-41d4-a716-446655440000
```

---

## Testing Checklist

Run through these to verify everything works:

### Basic Functionality
- [ ] ✅ App launches without errors
- [ ] ✅ Shows "Online" status
- [ ] ✅ Can pull to refresh
- [ ] ✅ Can create subject
- [ ] ✅ Subject appears in list
- [ ] ✅ Can tap subject card

### Quiz Flow
- [ ] ✅ Can start quiz
- [ ] ✅ Questions load (may take 10-15s first time)
- [ ] ✅ Can select answer
- [ ] ✅ Can submit answer
- [ ] ✅ See correct/incorrect feedback
- [ ] ✅ See explanation
- [ ] ✅ Can go to next question
- [ ] ✅ Complete quiz and see score

### Offline Mode
- [ ] ✅ Can stop server
- [ ] ✅ Status changes to "Offline"
- [ ] ✅ Can still view subjects
- [ ] ✅ Creating subject shows error
- [ ] ✅ Can restart server
- [ ] ✅ Status changes back to "Online"

### Data Persistence
- [ ] ✅ Quit and restart app
- [ ] ✅ Subjects still there
- [ ] ✅ Quiz history preserved
- [ ] ✅ Progress tracked correctly

---

## Next Steps

### Try These Features:

1. **Create Multiple Subjects**
   - AP Calculus BC
   - AP Chemistry
   - AP Biology

2. **Take Multiple Quizzes**
   - See how accuracy is tracked
   - Watch progress improve
   - Notice second quiz is faster (cached)

3. **Test Different Difficulties**
   - Modify quiz_screen.dart to allow selection
   - Try easy/medium/hard

4. **Customize Colors**
   - Each subject can have unique color
   - Makes it easy to identify

### Explore the Code:

```
lib/
├── config/api_config.dart      ← Change server URL here
├── models/                     ← Data structures
├── services/api_service.dart   ← All HTTP requests
├── providers/                  ← State management
└── screens/                    ← UI screens
```

### Make Changes:

**Change Server URL:**
```dart
// lib/config/api_config.dart
static const String baseUrl = 'http://YOUR_IP:3000';
```

**Add More Questions Per Quiz:**
```dart
// lib/screens/home_screen.dart (line ~50)
numQuestions: 10,  // Change from 5 to 10
```

**Change Difficulty:**
```dart
// lib/screens/quiz_screen.dart
difficulty: 'hard',  // Change from 'medium'
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│          Flutter App (Mobile/Desktop)       │
│                                             │
│  ┌──────────┐    ┌──────────┐             │
│  │ Home     │───▶│ Quiz     │             │
│  │ Screen   │    │ Screen   │             │
│  └────┬─────┘    └────┬─────┘             │
│       │               │                    │
│  ┌────▼─────────────▼────┐                │
│  │   Subject/Quiz        │                │
│  │   Providers           │                │
│  │   (State Management)  │                │
│  └────┬──────────────────┘                │
│       │                                    │
│  ┌────▼──────────┐   ┌──────────────┐    │
│  │ API Service   │   │ SQLite       │    │
│  │ (HTTP Client) │   │ (Local DB)   │    │
│  └────┬──────────┘   └──────────────┘    │
└───────┼─────────────────────────────────┘
        │ HTTP/JSON
        │
┌───────▼─────────────────────────────────────┐
│     FormulaQuizzer Server (Node.js)         │
│                                             │
│  ┌──────────────┐   ┌──────────────┐      │
│  │ REST API     │   │ OpenAI       │      │
│  │ (Express)    │   │ Service      │      │
│  └──────────────┘   └──────────────┘      │
│                                             │
│  ┌──────────────┐   ┌──────────────┐      │
│  │ Mock         │   │ LRU Cache    │      │
│  │ Database     │   │              │      │
│  └──────────────┘   └──────────────┘      │
└─────────────────────────────────────────────┘
```

**Data Flow:**
1. User interacts with Flutter UI
2. Provider manages state
3. API Service makes HTTP request to server
4. Server processes (may call OpenAI)
5. Response returned to app
6. Data saved to local SQLite
7. Provider updates state
8. UI refreshes automatically

---

## Production Deployment

### For App Store (iOS)

```bash
flutter build ios --release
# Open Xcode and submit
```

### For Google Play (Android)

```bash
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### Update Server URL

Before deploying, point to production server:

```dart
// lib/config/api_config.dart
static const String baseUrl = 'https://your-production-server.com';
```

---

## Summary

✅ **Server**: Running at http://localhost:3000  
✅ **App**: Connected and showing "Online"  
✅ **Features**: Create subjects, take quizzes, see progress  
✅ **Offline**: Works with cached data  
✅ **AI**: Generates questions via OpenAI  

**You're ready to go! 🚀**

---

## Support

**Server Issues**: Check `../server/QUICK_START.md`  
**API Reference**: Check `../server/API_SPECIFICATION.md`  
**Architecture**: Check `../server/ARCHITECTURE.md`

**Happy Quizzing! 📚**
