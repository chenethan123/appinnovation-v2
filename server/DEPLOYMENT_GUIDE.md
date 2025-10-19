# FormulaQuizzer Server Deployment Guide

Complete guide for deploying the FormulaQuizzer Server to production environments.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Environment Configuration](#environment-configuration)
3. [Docker Deployment](#docker-deployment)
4. [Cloud Platform Deployments](#cloud-platform-deployments)
5. [Database Setup](#database-setup)
6. [Monitoring & Logging](#monitoring--logging)
7. [Security Hardening](#security-hardening)
8. [Performance Optimization](#performance-optimization)
9. [Backup & Disaster Recovery](#backup--disaster-recovery)
10. [Troubleshooting](#troubleshooting)

---

## Pre-Deployment Checklist

### ✅ Code Readiness

```bash
# 1. Run all tests
npm test

# 2. Check TypeScript compilation
npm run build

# 3. Run linter
npm run lint

# 4. Security audit
npm audit

# 5. Check for outdated dependencies
npm outdated
```

### ✅ Configuration Readiness

- [ ] Environment variables configured
- [ ] Database credentials secured
- [ ] OpenAI API key obtained and valid
- [ ] API keys generated for authentication
- [ ] CORS origins configured
- [ ] Rate limits configured appropriately
- [ ] SSL/TLS certificates obtained (for HTTPS)

### ✅ Infrastructure Readiness

- [ ] Production database provisioned (PostgreSQL 15+)
- [ ] Redis instance provisioned (optional, for caching)
- [ ] Domain name registered and DNS configured
- [ ] Monitoring and alerting set up
- [ ] Backup strategy defined

---

## Environment Configuration

### Production Environment Variables

Create a `.env.production` file:

```bash
# Server Configuration
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgresql://user:password@postgres-host:5432/formula_quizzer?ssl=true
DB_POOL_MIN=5
DB_POOL_MAX=20
DB_SSL=true

# Redis Configuration (Optional)
REDIS_URL=redis://:password@redis-host:6379
REDIS_TLS=true
REDIS_TTL=300

# OpenAI Configuration
OPENAI_API_KEY=sk-prod-your-key-here
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_MAX_TOKENS=2000
OPENAI_TEMPERATURE=0.7
OPENAI_TIMEOUT_MS=30000

# Authentication
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
API_KEYS=key1_prod,key2_prod,key3_prod

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# CORS
CORS_ORIGIN=https://yourdomain.com,https://app.yourdomain.com

# Monitoring
SENTRY_DSN=https://your-sentry-dsn
PROMETHEUS_ENABLED=true

# Misc
TZ=UTC
```

### Security Best Practices for Secrets

```bash
# NEVER commit .env files to git
echo ".env*" >> .gitignore

# Use environment-specific configs
.env.development
.env.production
.env.staging

# Use secrets managers in production:
# - AWS Secrets Manager
# - HashiCorp Vault
# - Railway/Render built-in secrets
```

---

## Docker Deployment

### Dockerfile

Create `Dockerfile` in project root:

```dockerfile
# Multi-stage build for optimal image size
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY src ./src

# Build TypeScript
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built artifacts and dependencies
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/v1/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["node", "dist/index.js"]
```

### Docker Compose (Local/Staging)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://postgres:password@db:5432/formula_quizzer
      REDIS_URL: redis://redis:6379
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      JWT_SECRET: ${JWT_SECRET}
      API_KEYS: ${API_KEYS}
    depends_on:
      - db
      - redis
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: formula_quizzer
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres-data:
  redis-data:

networks:
  app-network:
    driver: bridge
```

### Build and Run

```bash
# Build image
docker build -t formula-quizzer-server:latest .

# Run with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down
```

---

## Cloud Platform Deployments

### Railway.app (Recommended for Beginners)

**Step 1: Install Railway CLI**
```bash
npm install -g @railway/cli
```

**Step 2: Login and Initialize**
```bash
railway login
railway init
```

**Step 3: Add PostgreSQL**
```bash
railway add postgresql
```

**Step 4: Configure Environment Variables**
```bash
# Set via CLI
railway variables set OPENAI_API_KEY=sk-...
railway variables set JWT_SECRET=your-secret
railway variables set API_KEYS=key1,key2

# Or via Railway Dashboard (recommended)
# https://railway.app/dashboard -> Variables
```

**Step 5: Deploy**
```bash
railway up
```

**Step 6: Get URL**
```bash
railway domain
```

**Cost:** Free tier includes $5/month credit, then pay-as-you-go.

---

### Render.com

**Step 1: Connect GitHub Repository**
1. Go to https://render.com/dashboard
2. Click "New +" → "Web Service"
3. Connect your GitHub repository

**Step 2: Configure Service**

```yaml
# render.yaml
services:
  - type: web
    name: formula-quizzer-server
    env: node
    buildCommand: npm install && npm run build
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: formula-quizzer-db
          property: connectionString
      - key: OPENAI_API_KEY
        sync: false  # Set manually in dashboard
      - key: JWT_SECRET
        generateValue: true
      - key: API_KEYS
        sync: false
      - key: LOG_LEVEL
        value: info

databases:
  - name: formula-quizzer-db
    databaseName: formula_quizzer
    user: formula_quizzer_user
    plan: starter
```

**Step 3: Add Environment Secrets**
- Go to Dashboard → Environment
- Add `OPENAI_API_KEY` and `API_KEYS` manually

**Step 4: Deploy**
- Push to GitHub `main` branch
- Render auto-deploys on every push

**Cost:** Free tier available, Pro plans start at $7/month.

---

### AWS Elastic Beanstalk

**Step 1: Install EB CLI**
```bash
pip install awsebcli
```

**Step 2: Initialize EB Application**
```bash
eb init formula-quizzer-server \
  --platform node.js-20 \
  --region us-east-1
```

**Step 3: Create Environment**
```bash
eb create production \
  --database \
  --database.engine postgres \
  --envvars \
    NODE_ENV=production,\
    OPENAI_API_KEY=sk-...,\
    JWT_SECRET=your-secret
```

**Step 4: Configure RDS**
```bash
# Add RDS PostgreSQL via AWS Console
# Update DATABASE_URL environment variable
```

**Step 5: Deploy**
```bash
eb deploy
```

**Step 6: Access Application**
```bash
eb open
```

**Cost:** t3.micro instance (~$10/month) + RDS (~$15/month).

---

### Fly.io

**Step 1: Install Fly CLI**
```bash
curl -L https://fly.io/install.sh | sh
```

**Step 2: Login and Launch**
```bash
fly auth login
fly launch
```

**Step 3: Configure `fly.toml`**
```toml
app = "formula-quizzer-server"
primary_region = "ewr"

[build]
  builder = "heroku/buildpacks:20"

[env]
  NODE_ENV = "production"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

[[services]]
  protocol = "tcp"
  internal_port = 8080

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

[health_check]
  type = "http"
  path = "/api/v1/health"
  interval = "30s"
  timeout = "5s"
```

**Step 4: Add PostgreSQL**
```bash
fly postgres create
fly postgres attach --app formula-quizzer-server
```

**Step 5: Set Secrets**
```bash
fly secrets set OPENAI_API_KEY=sk-...
fly secrets set JWT_SECRET=your-secret
fly secrets set API_KEYS=key1,key2
```

**Step 6: Deploy**
```bash
fly deploy
```

**Cost:** Free tier includes 3 VMs with 256MB RAM.

---

### Heroku

**Step 1: Install Heroku CLI**
```bash
brew tap heroku/brew && brew install heroku
```

**Step 2: Login and Create App**
```bash
heroku login
heroku create formula-quizzer-server
```

**Step 3: Add PostgreSQL**
```bash
heroku addons:create heroku-postgresql:mini
```

**Step 4: Set Environment Variables**
```bash
heroku config:set NODE_ENV=production
heroku config:set OPENAI_API_KEY=sk-...
heroku config:set JWT_SECRET=your-secret
heroku config:set API_KEYS=key1,key2
```

**Step 5: Deploy**
```bash
git push heroku main
```

**Step 6: Run Migrations**
```bash
heroku run npm run migrate
```

**Cost:** Basic dyno ($7/month) + Mini PostgreSQL ($5/month).

---

## Database Setup

### PostgreSQL Production Setup

**Step 1: Create Database and User**
```sql
-- Connect as postgres superuser
CREATE DATABASE formula_quizzer;
CREATE USER formula_quizzer_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE formula_quizzer TO formula_quizzer_user;

-- Grant schema privileges
\c formula_quizzer
GRANT ALL ON SCHEMA public TO formula_quizzer_user;
```

**Step 2: Run Migrations**
```bash
# Using migration script
npm run migrate

# Or manually
psql $DATABASE_URL -f database/migrations/001_initial.sql
```

**Step 3: Configure SSL**
```javascript
// config/database.ts
{
  ssl: process.env.NODE_ENV === 'production' ? {
    rejectUnauthorized: false  // For most cloud providers
  } : false
}
```

### Database Optimization

**Create Indexes:**
```sql
-- Performance indexes
CREATE INDEX CONCURRENTLY idx_questions_subject_id ON questions(subject_id);
CREATE INDEX CONCURRENTLY idx_quiz_sessions_answered_at ON quiz_sessions(answered_at);
CREATE INDEX CONCURRENTLY idx_subjects_is_active ON subjects(is_active);

-- Analyze tables
ANALYZE subjects;
ANALYZE questions;
ANALYZE quiz_sessions;
```

**Enable Connection Pooling:**
```javascript
const pool = new Pool({
  max: 20,  // Maximum connections
  min: 5,   // Minimum connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

---

## Monitoring & Logging

### Structured Logging with Pino

```javascript
// utils/logger.ts
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  redact: ['req.headers.authorization', 'password', 'api_key'],
});
```

### Log Aggregation

**Option 1: CloudWatch (AWS)**
```bash
# Install CloudWatch agent
npm install aws-cloudwatch-log

# Configure
export AWS_REGION=us-east-1
export LOG_GROUP=/aws/formula-quizzer
```

**Option 2: Datadog**
```bash
# Install Datadog agent
npm install dd-trace

# Configure
DD_ENV=production DD_SERVICE=formula-quizzer node dist/index.js
```

**Option 3: Papertrail**
```bash
# Forward logs
npm install winston-papertrail

# Configure in logger
```

### Error Tracking with Sentry

```bash
# Install Sentry
npm install @sentry/node @sentry/tracing

# Configure in index.ts
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
});
```

### Application Performance Monitoring (APM)

**New Relic Integration:**
```bash
npm install newrelic

# newrelic.js
exports.config = {
  app_name: ['FormulaQuizzer Server'],
  license_key: process.env.NEW_RELIC_LICENSE_KEY,
  logging: { level: 'info' },
};
```

**Prometheus Metrics:**
```javascript
// metrics/prometheus.ts
import promClient from 'prom-client';

const register = new promClient.Registry();

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

export { register, httpRequestDuration };
```

---

## Security Hardening

### HTTPS/TLS Configuration

**Option 1: Reverse Proxy (Nginx)**
```nginx
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Option 2: Cloud Platform SSL** (Automatic)
- Railway, Render, Fly.io provide automatic SSL
- No configuration needed

### Firewall Rules

```bash
# Allow only necessary ports
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable
```

### API Key Rotation

```bash
# Generate new API keys periodically
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Update API_KEYS environment variable
# Notify clients of upcoming key expiration
```

### Rate Limiting

```javascript
// middleware/rate_limit.ts
import rateLimit from 'express-rate-limit';

export const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // Max requests per window
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: 'rate_limit_exceeded',
      message: 'Too many requests. Try again later.',
    });
  },
});
```

---

## Performance Optimization

### Caching Strategies

**Redis Cache Configuration:**
```javascript
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  lazyConnect: true,
});

// Cache middleware
async function cacheMiddleware(req, res, next) {
  const key = `cache:${req.path}:${JSON.stringify(req.query)}`;
  const cached = await redis.get(key);
  
  if (cached) {
    return res.json(JSON.parse(cached));
  }
  
  res.sendResponse = res.json;
  res.json = (data) => {
    redis.setex(key, 300, JSON.stringify(data));
    res.sendResponse(data);
  };
  
  next();
}
```

### Database Query Optimization

```sql
-- Add covering indexes
CREATE INDEX idx_questions_subject_difficulty 
ON questions(subject_id, difficulty) 
INCLUDE (id, question_text, options);

-- Partition large tables
CREATE TABLE quiz_sessions_2024 PARTITION OF quiz_sessions
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

### Load Balancing

**Nginx Load Balancer:**
```nginx
upstream api_backend {
    least_conn;  # or ip_hash
    server api1.yourdomain.com:3000;
    server api2.yourdomain.com:3000;
    server api3.yourdomain.com:3000;
}

server {
    listen 80;
    location / {
        proxy_pass http://api_backend;
    }
}
```

---

## Backup & Disaster Recovery

### Database Backups

**Automated PostgreSQL Backups:**
```bash
# Backup script (backup.sh)
#!/bin/bash
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/formula_quizzer_$TIMESTAMP.sql"

pg_dump $DATABASE_URL > $BACKUP_FILE
gzip $BACKUP_FILE

# Upload to S3
aws s3 cp $BACKUP_FILE.gz s3://your-backup-bucket/

# Delete backups older than 30 days
find $BACKUP_DIR -type f -mtime +30 -delete
```

**Cron Job:**
```bash
# Run daily at 2 AM
0 2 * * * /path/to/backup.sh
```

### Point-in-Time Recovery

```bash
# Enable WAL archiving (postgresql.conf)
wal_level = replica
archive_mode = on
archive_command = 'aws s3 cp %p s3://your-wal-archive/%f'

# Restore to specific time
pg_restore --dbname=formula_quizzer \
  --clean --if-exists \
  --target-time="2024-10-13 09:00:00" \
  backup.sql
```

---

## Troubleshooting

### Common Issues

**1. Database Connection Timeout**
```bash
# Check connection string
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT 1"

# Check connection pool
# Increase max connections in pool config
```

**2. High Memory Usage**
```bash
# Monitor Node.js process
node --max-old-space-size=512 dist/index.js

# Enable garbage collection logs
node --trace-gc dist/index.js
```

**3. OpenAI API Rate Limits**
```bash
# Implement exponential backoff
# Check usage: https://platform.openai.com/usage
# Increase cache TTL to reduce API calls
```

**4. Slow API Response Times**
```bash
# Enable query logging
LOG_LEVEL=debug npm start

# Add database indexes
# Enable Redis caching
# Use APM tool (New Relic, Datadog)
```

---

## Post-Deployment Checklist

- [ ] Verify health check endpoint responds
- [ ] Test all API endpoints in production
- [ ] Confirm database migrations completed
- [ ] Verify environment variables are set correctly
- [ ] Test API authentication with production keys
- [ ] Confirm HTTPS/SSL is working
- [ ] Set up monitoring alerts
- [ ] Configure log aggregation
- [ ] Test backup/restore procedures
- [ ] Document production URLs and credentials (securely)
- [ ] Update DNS records
- [ ] Enable auto-scaling (if applicable)

---

## Maintenance Schedule

### Daily
- Review error logs
- Monitor API response times
- Check OpenAI API usage/costs

### Weekly
- Review and merge dependabot PRs
- Database performance review
- Security audit logs review

### Monthly
- Rotate API keys
- Database vacuum and optimization
- Review and update documentation
- Performance testing
- Backup restore testing

---

## Cost Estimation

### Small Scale (< 1000 users)
- **Hosting**: $7-15/month (Render/Railway basic plan)
- **Database**: $5-10/month (Managed PostgreSQL)
- **OpenAI API**: $20-50/month (assuming 1000 questions/month)
- **Total**: ~$35-75/month

### Medium Scale (1000-10,000 users)
- **Hosting**: $25-50/month (Multiple instances)
- **Database**: $25-50/month (Larger managed DB)
- **Redis**: $10-20/month
- **OpenAI API**: $200-500/month
- **Total**: ~$260-620/month

### Large Scale (10,000+ users)
- **Hosting**: $200-500/month (Auto-scaling)
- **Database**: $100-200/month (High-performance)
- **Redis**: $30-50/month
- **OpenAI API**: $2000+/month
- **Monitoring**: $50-100/month
- **Total**: ~$2380+/month

---

## Support & Resources

- **Documentation**: `/docs` directory
- **Issues**: GitHub Issues
- **Monitoring Dashboard**: Your APM tool
- **Status Page**: Consider statuspage.io

---

**Last Updated:** 2024-10-13  
**Next Review:** 2024-11-13
