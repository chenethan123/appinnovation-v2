# Installation Guide for MCQ Backend

## Prerequisites

You need to install Node.js and npm before running this backend server.

### Install Node.js (macOS)

**Option 1: Using Homebrew (Recommended)**
```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js (includes npm)
brew install node

# Verify installation
node --version   # Should show v20.x.x or higher
npm --version    # Should show v10.x.x or higher
```

**Option 2: Download from Official Website**
1. Visit: https://nodejs.org/
2. Download the LTS (Long Term Support) version for macOS
3. Run the installer
4. Verify installation in Terminal:
   ```bash
   node --version
   npm --version
   ```

**Option 3: Using nvm (Node Version Manager)**
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Restart terminal, then install Node
nvm install 20
nvm use 20

# Verify
node --version
npm --version
```

## Setup Steps

Once Node.js is installed, follow these steps:

### 1. Navigate to Server Directory
```bash
cd "/Users/ethanchen/Desktop/CS Stuff/formula_quizzer/server"
```

### 2. Install Dependencies
```bash
npm install
```

This will install:
- Express (web framework)
- OpenAI SDK (AI integration)
- Zod (validation)
- Pino (logging)
- TypeScript and development tools

**Expected output**: Install takes ~1-2 minutes, creating `node_modules/` folder

### 3. Verify Environment Configuration
The `.env` file is already created with your API key. Check it exists:
```bash
cat .env
```

You should see your `OPENAI_API_KEY` set.

### 4. Start Development Server
```bash
npm run dev
```

**Expected output**:
```
API server running on port 8787
```

### 5. Test the API
Open a new terminal and test:

```bash
# Health check
curl http://localhost:8787/api/health

# Generate a test MCQ
curl -X POST http://localhost:8787/api/generate-mcq \
  -H "Content-Type: application/json" \
  -d '{"subject": "AP Physics 1", "choices": 4}'
```

## Troubleshooting

### "command not found: npm"
- Node.js is not installed or not in PATH
- Follow installation steps above
- Restart terminal after installation

### "OPENAI_API_KEY not configured"
- Check `.env` file exists in `/server` directory
- Verify API key is set correctly
- Restart server after changing `.env`

### Port 8787 already in use
- Change PORT in `.env` file
- Or kill the process using: `lsof -ti:8787 | xargs kill -9`

### OpenAI API errors
- Verify API key is valid: https://platform.openai.com/api-keys
- Check you have credits: https://platform.openai.com/usage
- Check OpenAI status: https://status.openai.com

### TypeScript errors during build
- Delete `node_modules/` and `package-lock.json`
- Run `npm install` again
- Ensure Node version is 18 or higher

## Next Steps

Once the server is running:

1. **Test all endpoints** using the curl commands in README.md
2. **Integrate with Flutter app** using the example Dart code
3. **Monitor logs** to see MCQ generation in action
4. **Check OpenAI usage** at https://platform.openai.com/usage

## Development Workflow

```bash
# Start development server (auto-reload on file changes)
npm run dev

# Build for production
npm run build

# Run production build
npm start

# Run tests (when implemented)
npm test
```

## Questions?

Check the main README.md for:
- API endpoint documentation
- Error handling guide
- Security best practices
- Deployment options
