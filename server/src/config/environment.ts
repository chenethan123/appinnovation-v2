/**
 * Environment Configuration
 * Following ARCHITECTURE.md - Configuration Management
 */

import dotenv from 'dotenv';
import { z } from 'zod';

// Load environment variables
dotenv.config();

// Validation schema for environment variables
const envSchema = z.object({
  // Server
  PORT: z.string().default('3000'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  
  // Database
  DATABASE_URL: z.string().default('memory'),
  
  // OpenAI
  OPENAI_API_KEY: z.string().min(1, 'OpenAI API key is required'),
  OPENAI_MODEL: z.string().default('gpt-4-turbo-preview'),
  OPENAI_MAX_TOKENS: z.string().default('1000'),
  OPENAI_TEMPERATURE: z.string().default('0.7'),
  
  // API Security
  API_KEY: z.string().default('dev_key_1'),
  JWT_SECRET: z.string().default('change_in_production'),
  
  // CORS
  CORS_ORIGIN: z.string().default('http://localhost:3000'),
  
  // Rate Limiting
  RATE_LIMIT_WINDOW_MS: z.string().default('60000'),
  RATE_LIMIT_MAX_REQUESTS: z.string().default('60'),
  
  // Cache
  CACHE_TTL_SECONDS: z.string().default('300'),
  CACHE_MAX_ITEMS: z.string().default('50'),
  
  // Logging
  LOG_LEVEL: z.string().default('info'),
});

// Parse and validate environment variables
const parseEnv = () => {
  try {
    return envSchema.parse(process.env);
  } catch (error) {
    if (error instanceof z.ZodError) {
      console.error('❌ Environment validation failed:');
      error.errors.forEach(err => {
        console.error(`  - ${err.path.join('.')}: ${err.message}`);
      });
      process.exit(1);
    }
    throw error;
  }
};

const env = parseEnv();

// Export typed configuration
export const config = {
  server: {
    port: parseInt(env.PORT, 10),
    nodeEnv: env.NODE_ENV,
    isDevelopment: env.NODE_ENV === 'development',
    isProduction: env.NODE_ENV === 'production',
    isTest: env.NODE_ENV === 'test',
  },
  
  database: {
    url: env.DATABASE_URL,
    useMockData: env.DATABASE_URL === 'memory',
  },
  
  openai: {
    apiKey: env.OPENAI_API_KEY,
    model: env.OPENAI_MODEL,
    maxTokens: parseInt(env.OPENAI_MAX_TOKENS, 10),
    temperature: parseFloat(env.OPENAI_TEMPERATURE),
  },
  
  security: {
    apiKey: env.API_KEY,
    jwtSecret: env.JWT_SECRET,
  },
  
  cors: {
    origin: env.CORS_ORIGIN.split(',').map(o => o.trim()),
  },
  
  rateLimit: {
    windowMs: parseInt(env.RATE_LIMIT_WINDOW_MS, 10),
    maxRequests: parseInt(env.RATE_LIMIT_MAX_REQUESTS, 10),
  },
  
  cache: {
    ttlSeconds: parseInt(env.CACHE_TTL_SECONDS, 10),
    maxItems: parseInt(env.CACHE_MAX_ITEMS, 10),
  },
  
  logging: {
    level: env.LOG_LEVEL,
  },
} as const;

// Validate critical configuration
if (config.openai.apiKey.length < 20) {
  console.error('❌ Invalid OpenAI API key. Please check your .env file.');
  process.exit(1);
}

console.log('✅ Configuration loaded successfully');
console.log(`📍 Environment: ${config.server.nodeEnv}`);
console.log(`🗄️  Database: ${config.database.useMockData ? 'In-Memory (Mock)' : 'External'}`);
console.log(`🤖 OpenAI Model: ${config.openai.model}`);
