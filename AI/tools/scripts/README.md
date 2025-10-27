# AI Tools Scripts

Command-line utilities for testing and troubleshooting the FormulaQuizzer system.

## Scripts

### `supabase_auth.sh`
Authenticates with Supabase and queries user data.

**Usage:**
```bash
# Use default credentials (testing@gmail.com / testing)
./supabase_auth.sh

# Use custom credentials
./supabase_auth.sh user@example.com password123
```

**What it does:**
1. Authenticates with Supabase using email/password
2. Gets user info and ID
3. Queries subjects for the user
4. Queries questions for the user  
5. Queries quiz sessions for the user
6. Shows summary counts

### `backend_health.sh`
Tests the Node.js backend server endpoints.

**Usage:**
```bash
./backend_health.sh
```

**What it does:**
1. Tests `/api/health` endpoint
2. Tests `/api/cache/stats` endpoint
3. Tests `/api/generate-mcq` endpoint (shows auth requirement)
4. Shows response status and data

## Prerequisites

- `curl` - for HTTP requests
- `jq` - for JSON formatting (optional but recommended)
- Backend server running on `localhost:8787` (for backend_health.sh)

## Installation

```bash
# Install jq on macOS
brew install jq

# Install jq on Ubuntu/Debian
sudo apt-get install jq
```

## Troubleshooting

### Supabase Connection Issues
- Check if Supabase URL and anon key are correct
- Verify user credentials exist in Supabase
- Check network connectivity

### Backend Connection Issues
- Ensure backend server is running: `cd server && npm run dev`
- Check if port 8787 is available
- Verify CORS settings allow your requests

### JSON Parsing Issues
- Install `jq` for better JSON formatting
- Scripts will still work without `jq` but output will be raw JSON
