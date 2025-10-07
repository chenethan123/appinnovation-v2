# OpenAI API Key Setup Guide

## 🚀 Quick Setup (5 minutes)

Your app now calls OpenAI **directly from Flutter** - no backend server needed! Just add your API key and you're done.

---

## Step 1: Get Your OpenAI API Key

1. Go to: https://platform.openai.com/api-keys
2. Sign in or create an OpenAI account
3. Click **"Create new secret key"**
4. **Copy the key** (starts with `sk-proj-...`)
   - ⚠️ **Save it now!** You won't be able to see it again.

---

## Step 2: Add Key to Your App

Open `lib/config/api_config.dart` and replace the placeholder:

```dart
// BEFORE:
static const String openAIApiKey = 'YOUR_OPENAI_API_KEY_HERE';

// AFTER (use your actual key):
static const String openAIApiKey = 'sk-proj-abc123...your_actual_key_here...xyz789';
```

---

## Step 3: Run the App

```bash
flutter run -d macos
```

That's it! Click **"AI Quiz (ChatGPT)"** and it will work! 🎉

---

## 💰 Pricing

- **Cost**: ~$0.02-0.04 per question
- **Free tier**: $5 in credits for new accounts
- **That's ~125-250 free questions!**

Set a usage limit in OpenAI dashboard to avoid surprises:
1. Go to: https://platform.openai.com/usage
2. Click **"Limits"** → Set monthly budget

---

## 🔧 Advanced: Error Handling

Your app now has **smart retry logic**:

### Rate Limits (429 errors)
- ✅ **Auto-retry** with exponential backoff (2s, 4s, 8s)
- ✅ **Jitter** to avoid thundering herd
- ✅ **Friendly message**: "ChatGPT API Busy - wait 1-2 minutes"

### Network Errors
- ✅ **Auto-retry** up to 3 times
- ✅ **Exponential backoff**
- ✅ **Friendly message**: "Connection Error - check internet"

### Authentication Errors
- ✅ **No retry** (won't work without valid key)
- ✅ **Friendly message**: "Invalid API key - check config"

---

## 🧪 Test Your Setup

### 1. Test with Valid Key

```bash
# Run the app
flutter run -d macos

# Click "AI Quiz (ChatGPT)"
# Should see: "Generating question with ChatGPT..."
# Then: Question appears in 2-5 seconds ✅
```

### 2. Test Error Handling

**Test rate limit handling:**
```dart
// In openai_service.dart, temporarily change:
int maxRetries = 3,  // Change to 1 for faster testing
```

Click AI Quiz button rapidly 5-10 times. You should see:
- ⏳ "ChatGPT API Busy - wait 1-2 minutes"
- Button remains clickable
- Works again after waiting

**Test invalid key:**
```dart
// In api_config.dart:
static const String openAIApiKey = 'INVALID_KEY';
```

Click AI Quiz button. You should see:
- 🔑 "API Configuration Error"
- Clear instructions to fix
- Regular Quiz still works

---

## 🔒 Security Best Practices

### For Development (You)
✅ **Current setup is fine** - API key in source code  
✅ Add `lib/config/api_config.dart` to `.gitignore` if pushing to public repo

### For Production (App Store)
When publishing to App Store, consider:

1. **Environment Variables** (recommended):
   ```dart
   static const String openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');
   ```

2. **Backend Proxy** (most secure):
   - Deploy the Node.js backend to Railway/Render
   - Backend holds the API key (not in app)
   - Set `useDirectOpenAI = false` in api_config.dart
   - See: `PRODUCTION_DEPLOYMENT.md`

3. **Firebase Remote Config**:
   - Store key in Firebase
   - Fetch at runtime
   - Can change key without app update

---

## 🆘 Troubleshooting

### "Incorrect API key provided" (401)

**Fix**: Your API key is invalid or not set

```bash
# Check your key in api_config.dart
cat lib/config/api_config.dart | grep openAIApiKey

# Should see: 'sk-proj-...' NOT 'YOUR_OPENAI_API_KEY_HERE'
```

### "Rate limit exceeded" (429)

**Fix**: Wait 1-2 minutes or set usage limits

```bash
# Check your usage:
# Visit: https://platform.openai.com/usage

# Set limits:
# Visit: https://platform.openai.com/account/limits
```

### "Connection error" / "Network error"

**Fix**: Check internet and firewall

```bash
# Test OpenAI connectivity:
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"

# Should return JSON with models
```

### "OpenAI not initialized"

**Fix**: Restart the app

```bash
# Kill and restart:
flutter run -d macos
```

---

## 📊 Monitoring

### Check API Usage

```bash
# View usage dashboard:
open https://platform.openai.com/usage
```

### Check App Logs

```bash
# In Flutter DevTools console, you'll see:
✅ OpenAI initialized - ready to generate questions!
🤖 Generating MCQ for: Physics (attempt 1/3)
✅ MCQ generated successfully on attempt 1!

# Or if errors:
⏳ Rate limit hit. Retrying in 2s... (attempt 1/3)
✅ MCQ generated successfully on attempt 2!
```

---

## ✅ Success Checklist

Before using AI Quiz:
- [ ] OpenAI account created
- [ ] API key generated
- [ ] Key added to `api_config.dart`
- [ ] App restarted
- [ ] "AI Quiz (ChatGPT)" button works
- [ ] Question generates in 2-5 seconds
- [ ] Usage limits set (optional but recommended)

---

## 🎓 How It Works

```
User clicks "AI Quiz"
       ↓
OpenAIService.generateMCQ()
       ↓
Try attempt 1 → Call ChatGPT API
       ↓
   Success? → Return MCQ ✅
       ↓
   Rate limit? → Wait 2s → Retry (attempt 2)
       ↓
   Success? → Return MCQ ✅
       ↓
   Network error? → Wait 4s → Retry (attempt 3)
       ↓
   Success? → Return MCQ ✅
       ↓
   Still failing? → Show friendly error ⚠️
```

**Key Features**:
- **3 retry attempts** with exponential backoff
- **Random jitter** to prevent API stampede
- **Smart error detection** (rate limit vs auth vs network)
- **Friendly UI messages** (no raw errors!)
- **Graceful degradation** (regular Quiz still works)

---

## 🚀 Ready to Go!

Once you've added your API key:

```bash
flutter run -d macos
```

1. Click **"AI Quiz (ChatGPT)"**
2. Wait 2-5 seconds
3. Answer the question
4. See detailed explanations for each option! 🎉

**Enjoy your AI-powered quiz app!** 🤖📚
