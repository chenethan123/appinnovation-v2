# Production Deployment Guide

This app works WITHOUT requiring users to install Node.js. Here's how:

## 🎯 Architecture Overview

```
User's Device (Flutter App)
        ↓
   HTTPS Request
        ↓
Railway Cloud (Your Backend)
        ↓
   OpenAI API
        ↓
   MCQ Response
```

**Key Point**: The backend runs in the cloud, not on user devices!

---

## 🚀 Quick Deployment (Choose One)

### Option 1: Railway (Recommended - FREE)

**Why Railway?**
- ✅ Free $5/month credit
- ✅ One-command deploy
- ✅ Automatic HTTPS
- ✅ Easy environment variables
- ✅ Auto-deploy from Git

**Deploy in 3 Commands:**

```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Navigate and login
cd server
railway login

# 3. Deploy!
railway init
railway up
```

**Get your URL:**
```bash
railway domain
# Copy URL: https://your-app-name.up.railway.app
```

**Set environment variables:**
```bash
railway variables set OPENAI_API_KEY="sk-proj-YOUR-KEY"
```

📖 **Full guide**: See `server/DEPLOY_RAILWAY.md`

---

### Option 2: Render (FREE Alternative)

1. Go to https://render.com
2. Click "New Web Service"
3. Connect GitHub repo
4. Select `/server` directory
5. Build: `npm install && npm run build`
6. Start: `npm start`
7. Add environment variables
8. Deploy!

---

### Option 3: Fly.io (FREE with Credit Card)

```bash
# Install Fly CLI
brew install flyctl

# Login and deploy
cd server
fly launch
fly secrets set OPENAI_API_KEY="sk-proj-YOUR-KEY"
fly deploy
```

---

## 📱 Update Flutter App

### Step 1: Get Your Backend URL

After deploying, you'll get a URL like:
- Railway: `https://formula-quizzer-production.up.railway.app`
- Render: `https://formula-quizzer.onrender.com`
- Fly.io: `https://formula-quizzer.fly.dev`

### Step 2: Update Configuration

Open `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Set to FALSE for production
  static const bool useLocalBackend = false;
  
  // Paste your deployed URL here
  static const String productionBaseUrl = 'https://YOUR-DEPLOYED-URL.com';
  
  static const String localBaseUrl = 'http://localhost:8787';
  
  static String get baseUrl {
    return useLocalBackend ? localBaseUrl : productionBaseUrl;
  }
  
  // ... rest of file
}
```

### Step 3: Test & Build

```bash
# Clean build
flutter clean
flutter pub get

# Test on macOS
flutter run -d macos

# Build for production
flutter build macos --release

# Or for iOS
flutter build ios --release
```

---

## 🧪 Verify Deployment

### 1. Test Backend Health

```bash
curl https://YOUR-DEPLOYED-URL.com/api/health
```

**Expected:**
```json
{"ok": true, "timestamp": "2024-10-04T...", "cache_size": 0}
```

### 2. Test MCQ Generation

```bash
curl -X POST https://YOUR-DEPLOYED-URL.com/api/generate-mcq \
  -H "Content-Type: application/json" \
  -d '{"subject": "AP Physics 1", "choices": 4}'
```

**Expected:** Full MCQ JSON with explanations

### 3. Test in App

1. Open Flutter app
2. Click "AI Quiz (ChatGPT)"
3. Should see: "Generating question with ChatGPT..."
4. Question appears in ~2-5 seconds
5. Answer and see explanation ✨

---

## 💰 Cost Comparison

| Service | Free Tier | Pros | Cons |
|---------|-----------|------|------|
| **Railway** | $5/month credit | Easiest, Auto-deploy | Credit required after trial |
| **Render** | 750 hours/month | No credit card | Slower cold starts |
| **Fly.io** | 3 VMs free | Fast, Global | Credit card required |
| **Heroku** | Deprecated | - | No longer free |

**Recommendation**: Start with Railway for development, consider Render for completely free production.

---

## 🔒 Security Checklist

Before deploying:

- [x] OpenAI API key in environment variables (NOT in code)
- [x] `.env` file in `.gitignore`
- [x] Rate limiting enabled (60 req/min)
- [x] CORS configured properly
- [x] HTTPS enabled (automatic on all platforms)
- [x] No sensitive data in logs

---

## 🔄 Update Workflow

### For Development (Local Testing)

```dart
// lib/config/api_config.dart
static const bool useLocalBackend = true;
```

```bash
# Terminal 1: Start backend
cd server
npm run dev

# Terminal 2: Run Flutter
flutter run -d macos
```

### For Production (Published App)

```dart
// lib/config/api_config.dart
static const bool useLocalBackend = false;
static const String productionBaseUrl = 'https://YOUR-DEPLOYED-URL.com';
```

```bash
# Just run Flutter (backend is in cloud)
flutter run -d macos
# Or build for release
flutter build macos --release
```

---

## 📊 Monitoring

### Railway Dashboard
- View logs: `railway logs`
- Check metrics: https://railway.app/dashboard
- Monitor costs: See usage tab

### OpenAI Dashboard
- Track API usage: https://platform.openai.com/usage
- Set billing limits: Account → Billing → Limits
- Monitor costs: ~$0.02-0.04 per MCQ

---

## 🐛 Troubleshooting

### "Backend not available" in app

**Check deployment status:**
```bash
# Railway
railway status

# Render
# Check dashboard: https://dashboard.render.com

# Fly.io
fly status
```

**Check logs:**
```bash
# Railway
railway logs --tail

# Fly.io
fly logs
```

### OpenAI errors

**Verify API key is set:**
```bash
# Railway
railway variables

# Should see: OPENAI_API_KEY=sk-proj-...
```

**Check OpenAI credits:**
- Go to https://platform.openai.com/usage
- Verify you have credits available
- Check rate limits aren't exceeded

### CORS errors

**Update backend CORS settings:**

In `server/src/index.ts`, ensure:
```typescript
app.use(cors({
  origin: process.env.CORS_ORIGIN || "*",
  credentials: true
}));
```

Set environment variable:
```bash
railway variables set CORS_ORIGIN="*"
# Or specify your domain for security:
# railway variables set CORS_ORIGIN="https://yourdomain.com"
```

---

## 🎓 How Users Get the App

### macOS App Store

1. Build release: `flutter build macos --release`
2. Sign with Apple Developer account
3. Upload to App Store Connect
4. Users download from Mac App Store
5. Backend is already deployed and working!

### Direct Download

1. Build release: `flutter build macos --release`
2. App is in `build/macos/Build/Products/Release/`
3. Distribute `.app` file
4. Users run it (no Node.js needed!)

### iOS App Store

1. Build: `flutter build ios --release`
2. Open in Xcode
3. Archive and upload to App Store
4. Users download from App Store

**In ALL cases**: Backend runs in the cloud, users never install Node.js!

---

## ✅ Pre-Launch Checklist

Before publishing your app:

- [ ] Backend deployed to cloud
- [ ] Environment variables set (OPENAI_API_KEY)
- [ ] `useLocalBackend = false` in api_config.dart
- [ ] `productionBaseUrl` points to deployed backend
- [ ] Health check works: `curl YOUR-URL/api/health`
- [ ] MCQ generation works in production
- [ ] App tested with production backend
- [ ] OpenAI billing limits set
- [ ] Monitoring/logging configured
- [ ] Error handling tested (what if backend is down?)

---

## 🆘 Need Help?

**Railway Issues:**
- Docs: https://docs.railway.app
- Discord: https://discord.gg/railway

**Render Issues:**
- Docs: https://render.com/docs
- Community: https://community.render.com

**App Issues:**
- Check `lib/config/api_config.dart`
- Verify backend URL is correct
- Test backend directly with curl
- Check app logs: `flutter run -v`

---

## 🎉 Success!

Once deployed:
- ✅ Users install Flutter app from App Store
- ✅ App connects to your cloud backend
- ✅ Backend calls OpenAI for questions
- ✅ Everything works seamlessly
- ✅ No Node.js required on user devices!

**Users just need**: Your Flutter app
**You manage**: Cloud backend + OpenAI API key

---

**Ready to deploy?** → Choose a platform and follow the guide!
