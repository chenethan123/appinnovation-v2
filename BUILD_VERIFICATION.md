# Build Verification Guide

This document ensures **100% certainty** that the FormulaQuizzer app can be built and run from the GitHub repository.

## ✅ Prerequisites Checklist

Before building, verify you have:

- [ ] **Flutter SDK** installed (3.0.0 or higher)
  ```bash
  flutter --version
  ```
- [ ] **Xcode** (for macOS/iOS builds)
- [ ] **Android Studio** (for Android builds)
- [ ] **Node.js** v20+ (for backend server)
  ```bash
  node --version
  npm --version
  ```

## 🚀 Quick Build Test (Automated)

Run this single command to verify everything works:

```bash
./verify_build.sh
```

This script will:
1. Check all prerequisites
2. Clean previous builds
3. Install dependencies
4. Build the app
5. Verify server can start
6. Report success/failure

## 📋 Manual Build Steps

### 1. Clone Repository

```bash
git clone <repository-url>
cd formula_quizzer
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

**Expected output:**
```
Running "flutter pub get" in formula_quizzer...
Resolving dependencies...
Got dependencies!
```

### 3. Configure OpenAI API Key (Optional for AI features)

**Option A: For Development (Backend Server)**
```bash
cd server
cp .env.example .env
# Edit .env and add your OpenAI API key
nano .env  # or use your preferred editor
```

**Option B: For Production (Direct Flutter)**
```bash
# Create lib/config/api_config.dart
cp lib/config/api_config.example.dart lib/config/api_config.dart
# Edit and add your OpenAI API key
```

**Note:** App works WITHOUT API key - AI features will be disabled but core functionality remains.

### 4. Build the App

#### macOS Build
```bash
flutter build macos --release
```

**Expected output:**
```
Building macOS application...
✓ Built build/macos/Build/Products/Release/formula_quizzer.app
```

#### iOS Build
```bash
flutter build ios --release
```

#### Android Build
```bash
flutter build apk --release
```

### 5. Install Backend Server Dependencies (Optional)

```bash
cd server
npm install
```

**Expected output:**
```
added 150 packages, and audited 151 packages in 5s
found 0 vulnerabilities
```

### 6. Run the App

#### Using Automated Script
```bash
./start_app.sh
```

#### Manual Start
```bash
# Terminal 1: Start backend (optional)
cd server
npm run dev

# Terminal 2: Start Flutter app
flutter run -d macos
```

## 🔍 Verification Checklist

After building, verify:

- [ ] **Flutter app launches** without errors
- [ ] **Home screen displays** with subject cards
- [ ] **Can create a new subject** (tap + button)
- [ ] **Can take a quiz** (tap Quick Quiz button)
- [ ] **Backend server responds** (if running)
  ```bash
  curl http://localhost:8787/api/health
  # Should return: {"status":"healthy","timestamp":"..."}
  ```

## 🐛 Common Build Issues & Solutions

### Issue 1: "No such file or directory: lib/config/api_config.dart"

**Solution:**
```bash
# Create the config file
cat > lib/config/api_config.dart << 'EOF'
class ApiConfig {
  static const String openAiApiKey = 'YOUR_KEY_HERE';
  static const String baseUrl = 'http://localhost:8787';
}
EOF
```

### Issue 2: "Podfile.lock out of date"

**Solution:**
```bash
cd ios
rm Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### Issue 3: "Server won't start - port 8787 in use"

**Solution:**
```bash
# Kill existing process on port 8787
lsof -ti:8787 | xargs kill -9
# Then restart server
cd server && npm run dev
```

### Issue 4: "OPENAI_API_KEY not found"

**Solution:**
```bash
cd server
cp .env.example .env
# Edit .env and add: OPENAI_API_KEY=sk-your-key-here
```

### Issue 5: "Flutter build fails on macOS"

**Solution:**
```bash
flutter clean
flutter pub get
cd macos
pod repo update
pod install
cd ..
flutter build macos
```

## 📦 What's Included in Repository

### Required Files (Committed)
- ✅ `pubspec.yaml` - Flutter dependencies
- ✅ `lib/` - All Dart source code
- ✅ `assets/` - App assets (if any)
- ✅ `server/package.json` - Backend dependencies
- ✅ `server/src/` - Backend source code
- ✅ `server/.env.example` - Environment template
- ✅ `android/`, `ios/`, `macos/`, `linux/`, `windows/` - Platform configs
- ✅ `README.md` - Project documentation
- ✅ `.gitignore` - Proper exclusions

### Excluded Files (Generated/Private)
- ❌ `build/` - Build artifacts (regenerated)
- ❌ `client/` - Generated build directory (523MB)
- ❌ `.dart_tool/` - Dart tooling cache
- ❌ `server/node_modules/` - NPM packages (regenerated)
- ❌ `server/.env` - Private API keys
- ❌ `lib/config/api_config.dart` - Private config
- ❌ `*.db`, `*.sqlite` - Local databases
- ❌ `ios/Podfile.lock` - CocoaPods lock (platform-specific)

## 🎯 Success Criteria

The build is **100% verified** when:

1. ✅ `flutter pub get` succeeds with no errors
2. ✅ `flutter build <platform>` completes successfully
3. ✅ `npm install` (in server/) completes successfully
4. ✅ App launches and displays home screen
5. ✅ Can create subjects and take quizzes
6. ✅ Backend health check returns 200 OK (if running)

## 🔒 Security Notes

**Never commit these files:**
- Private API keys (`.env`, `api_config.dart`)
- Local databases (`*.db`, `*.sqlite`)
- Build artifacts (`build/`, `client/`)

**Always use:**
- `.env.example` for environment templates
- `api_config.example.dart` for config templates
- Proper `.gitignore` exclusions

## 📞 Support

If build fails after following all steps:

1. Check Flutter doctor: `flutter doctor -v`
2. Verify Node.js version: `node --version` (must be 20+)
3. Review error logs in `flutter_*.log`
4. Check GitHub Issues for similar problems

## 🎓 Educational Note

This app is designed for offline-first operation. All core features work without:
- Internet connection
- Backend server
- OpenAI API key

Only AI question generation requires external services.

---

**Last Updated:** December 14, 2024
**Verified On:** macOS Sonoma, Flutter 3.x, Node.js 20.x
