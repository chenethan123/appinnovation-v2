# Deploy Backend to Railway (Free)

Railway is a free hosting platform perfect for your Node.js backend. Your app will work for all users without requiring Node.js installation.

## 🚀 Quick Deploy (5 Minutes)

### Step 1: Create Railway Account
1. Go to https://railway.app
2. Sign up with GitHub (free)
3. Verify your email

### Step 2: Deploy from Command Line

```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login
railway login

# 3. Navigate to your server directory
cd "/Users/ethanchen/Desktop/CS Stuff/formula_quizzer/server"

# 4. Initialize Railway project
railway init

# 5. Deploy!
railway up
```

**Expected output:**
```
✓ Deployment successful
🎉 Your app is live at: https://your-app-name.up.railway.app
```

### Step 3: Set Environment Variables

```bash
# Set your OpenAI API key
railway variables set OPENAI_API_KEY="sk-proj-4l0rNvL1Yrm1W..."

# Set other variables
railway variables set PORT=8787
railway variables set LOG_LEVEL=info
railway variables set CORS_ORIGIN="*"
```

### Step 4: Get Your Deployment URL

```bash
railway domain
```

Copy the URL (e.g., `https://formula-quizzer-production.up.railway.app`)

### Step 5: Update Flutter App

1. Open `lib/config/api_config.dart`
2. Update `productionBaseUrl`:
   ```dart
   static const String productionBaseUrl = 'https://YOUR-APP-NAME.up.railway.app';
   ```
3. Set `useLocalBackend = false`
4. Save and run `flutter run -d macos`

---

## 🧪 Test Your Deployment

```bash
# Health check
curl https://YOUR-APP-NAME.up.railway.app/api/health

# Generate test MCQ
curl -X POST https://YOUR-APP-NAME.up.railway.app/api/generate-mcq \
  -H "Content-Type: application/json" \
  -d '{"subject": "AP Physics 1", "choices": 4}'
```

---

## 📊 Railway Dashboard

View your deployment at: https://railway.app/dashboard

Features:
- ✅ Real-time logs
- ✅ Resource usage monitoring
- ✅ Environment variables management
- ✅ Custom domains (optional)
- ✅ Automatic deployments from Git

---

## 💰 Pricing

**Free Tier:**
- $5 credit per month
- Perfect for personal projects
- ~2,500 MCQ generations/month
- No credit card required

**Pro Tier ($20/month):**
- $20 credit
- 10,000+ MCQ generations/month
- Priority support

---

## 🔄 Auto-Deploy from Git (Optional)

### Connect GitHub Repository

```bash
# 1. Create GitHub repo
cd "/Users/ethanchen/Desktop/CS Stuff/formula_quizzer"
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/formula-quizzer.git
git push -u origin main

# 2. Connect to Railway
railway link

# 3. Enable auto-deploy
railway up --detach
```

Now every `git push` automatically deploys!

---

## 🛠️ Alternative: Deploy via Railway UI

### Option 2: Web Interface

1. Go to https://railway.app/new
2. Click **"Deploy from GitHub repo"**
3. Select your `formula_quizzer` repository
4. Railway auto-detects Node.js
5. Set root directory: `/server`
6. Add environment variables:
   - `OPENAI_API_KEY`
   - `PORT=8787`
   - `CORS_ORIGIN=*`
7. Click **Deploy**

---

## 📝 Project Structure for Railway

Railway needs these files (already created):

```
server/
├── package.json       ✅ Dependencies
├── tsconfig.json      ✅ TypeScript config
├── src/               ✅ Source code
│   ├── index.ts
│   ├── openai.ts
│   └── cache.ts
├── .env.example       ✅ Template
└── .gitignore         ✅ Ignore .env
```

Railway automatically:
- Runs `npm install`
- Compiles TypeScript (`npm run build`)
- Starts server (`npm start`)

---

## 🐛 Troubleshooting

### Deployment fails
**Check logs:**
```bash
railway logs
```

**Common issues:**
- Missing `.env` variables → Set via `railway variables`
- Port conflicts → Railway uses `process.env.PORT`
- Build errors → Check `package.json` scripts

### Backend not responding
**Verify deployment:**
```bash
railway status
```

**Test endpoint:**
```bash
curl https://YOUR-APP-NAME.up.railway.app/api/health
```

### OpenAI errors
**Check API key:**
```bash
railway variables
```

**Verify credits:**
https://platform.openai.com/usage

---

## 🔒 Security Checklist

- [x] API key in environment variables (not code)
- [x] `.env` in `.gitignore`
- [x] Rate limiting enabled (60 req/min)
- [x] CORS configured
- [x] No PII logging
- [x] Request validation with Zod

---

## 📱 Update Flutter App

After deploying, update these files:

**1. `lib/config/api_config.dart`:**
```dart
static const bool useLocalBackend = false;
static const String productionBaseUrl = 'https://YOUR-APP-NAME.up.railway.app';
```

**2. Rebuild app:**
```bash
flutter clean
flutter pub get
flutter run -d macos
```

**3. Test:**
- Click "AI Quiz (ChatGPT)" button
- Should generate question successfully
- No Node.js required on user's device!

---

## 🎉 Success Criteria

- [x] Backend deployed to Railway
- [x] HTTPS URL working
- [x] Health check returns `{"ok": true}`
- [x] MCQ generation works via API
- [x] Flutter app connects successfully
- [x] No local Node.js required

---

## 📚 Resources

- Railway Docs: https://docs.railway.app
- CLI Reference: https://docs.railway.app/develop/cli
- Pricing: https://railway.app/pricing
- Status: https://status.railway.app

---

## 🆘 Support

**Railway Issues:**
- Discord: https://discord.gg/railway
- Docs: https://docs.railway.app

**App Issues:**
- Check logs: `railway logs`
- Check variables: `railway variables`
- Test locally first: `npm run dev`

---

**Ready to deploy?** → `railway up`

Your app will be live in ~2 minutes! 🚀
