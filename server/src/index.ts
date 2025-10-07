import "dotenv/config";
import express from "express";
import cors from "cors";
import { rateLimit } from "express-rate-limit";
import pino from "pino";
import pinoHttp from "pino-http";
import { v4 as uuidv4 } from "uuid";
import { generateMcq, generateMcqBatch } from "./openai";
import { MCQCache } from "./cache";
import { z } from "zod";

// Initialize logger
const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  transport: {
    target: "pino-pretty",
    options: {
      colorize: true
    }
  }
});

// Initialize Express app
const app = express();

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || "*",
  credentials: true
}));
app.use(express.json());
app.use(pinoHttp({ logger }));

// Rate limiting: 60 requests per minute per IP
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60,
  message: { error: "rate_limit_exceeded", message: "Too many requests, please try again later" },
  standardHeaders: true,
  legacyHeaders: false
});

app.use("/api", limiter);

// Initialize cache
const mcqCache = new MCQCache(50, 5);

// Request validation schemas
const GenerateMCQRequestSchema = z.object({
  subject: z.string().min(1, "Subject is required").max(200),
  choices: z.number().int().min(2).max(5).optional().default(4)
});

const GenerateMCQBatchRequestSchema = z.object({
  subject: z.string().min(1, "Subject is required").max(200),
  choices: z.number().int().min(2).max(5).optional().default(4),
  count: z.number().int().min(1).max(20).optional().default(5)
});

/**
 * POST /api/generate-mcq
 * Generate a single MCQ for the given subject
 */
app.post("/api/generate-mcq", async (req, res) => {
  try {
    // Validate request body
    const validation = GenerateMCQRequestSchema.safeParse(req.body);
    
    if (!validation.success) {
      return res.status(400).json({ 
        error: "invalid_request", 
        message: validation.error.errors[0].message 
      });
    }

    const { subject, choices } = validation.data;

    logger.info({ subject, choices }, "Generating MCQ");

    // Check cache first
    const cached = mcqCache.get(subject, choices);
    if (cached) {
      logger.info({ subject, id: cached.id }, "Returning cached MCQ");
      return res.json(cached);
    }

    // Generate new MCQ
    const mcq = await generateMcq(subject, choices);
    
    // Ensure ID is set
    if (!mcq.id) {
      mcq.id = uuidv4();
    }
    
    // Ensure subject matches request
    mcq.subject = subject;

    // Add to cache
    mcqCache.add(subject, choices, mcq);

    logger.info({ subject, id: mcq.id, difficulty: mcq.difficulty }, "MCQ generated successfully");

    res.json(mcq);
  } catch (error: any) {
    logger.error({ error: error.message }, "Error generating MCQ");
    
    // Handle specific error types
    if (error.message.includes("OPENAI_API_KEY")) {
      return res.status(500).json({ 
        error: "configuration_error", 
        message: "API key not configured" 
      });
    }
    
    if (error.message.includes("OpenAI API error")) {
      return res.status(503).json({ 
        error: "openai_error", 
        message: "OpenAI service temporarily unavailable" 
      });
    }

    res.status(500).json({ 
      error: "generation_failed", 
      message: "Failed to generate MCQ" 
    });
  }
});

/**
 * POST /api/generate-mcq-batch
 * Generate multiple MCQs for pre-warming cache
 */
app.post("/api/generate-mcq-batch", async (req, res) => {
  try {
    // Validate request body
    const validation = GenerateMCQBatchRequestSchema.safeParse(req.body);
    
    if (!validation.success) {
      return res.status(400).json({ 
        error: "invalid_request", 
        message: validation.error.errors[0].message 
      });
    }

    const { subject, choices, count } = validation.data;

    logger.info({ subject, choices, count }, "Generating MCQ batch");

    // Generate batch of MCQs
    const mcqs = await generateMcqBatch(subject, choices, count);

    // Add all to cache
    for (const mcq of mcqs) {
      mcqCache.add(subject, choices, mcq);
    }

    logger.info(
      { subject, count: mcqs.length, requested: count }, 
      "MCQ batch generated successfully"
    );

    res.json({ items: mcqs, count: mcqs.length });
  } catch (error: any) {
    logger.error({ error: error.message }, "Error generating MCQ batch");
    
    if (error.message.includes("OPENAI_API_KEY")) {
      return res.status(500).json({ 
        error: "configuration_error", 
        message: "API key not configured" 
      });
    }

    res.status(500).json({ 
      error: "batch_generation_failed", 
      message: "Failed to generate MCQ batch" 
    });
  }
});

/**
 * GET /api/health
 * Health check endpoint
 */
app.get("/api/health", (_req, res) => {
  res.json({ 
    ok: true, 
    timestamp: new Date().toISOString(),
    cache_size: mcqCache.size()
  });
});

/**
 * GET /api/cache/stats
 * Get cache statistics
 */
app.get("/api/cache/stats", (_req, res) => {
  res.json({
    size: mcqCache.size(),
    timestamp: new Date().toISOString()
  });
});

/**
 * POST /api/cache/clear
 * Clear the cache (admin endpoint)
 */
app.post("/api/cache/clear", (_req, res) => {
  mcqCache.clear();
  logger.info("Cache cleared");
  res.json({ ok: true, message: "Cache cleared" });
});

/**
 * 404 handler
 */
app.use((_req, res) => {
  res.status(404).json({ error: "not_found", message: "Endpoint not found" });
});

/**
 * Error handler
 */
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error({ error: err.message, stack: err.stack }, "Unhandled error");
  res.status(500).json({ error: "internal_error", message: "Internal server error" });
});

// Start server
const PORT = process.env.PORT || 8787;

app.listen(PORT, () => {
  logger.info({ port: PORT }, `API server running on port ${PORT}`);
  
  if (!process.env.OPENAI_API_KEY) {
    logger.warn("OPENAI_API_KEY not set - API calls will fail!");
  }
});
