import { MCQ } from "./openai";

interface CacheEntry<T> {
  value: T;
  timestamp: number;
}

/**
 * Simple LRU cache with TTL support
 */
export class LRUCache<T> {
  private cache: Map<string, CacheEntry<T>>;
  private maxSize: number;
  private ttlMs: number;

  constructor(maxSize: number = 100, ttlMinutes: number = 5) {
    this.cache = new Map();
    this.maxSize = maxSize;
    this.ttlMs = ttlMinutes * 60 * 1000;
  }

  get(key: string): T | null {
    const entry = this.cache.get(key);
    
    if (!entry) {
      return null;
    }

    // Check if expired
    if (Date.now() - entry.timestamp > this.ttlMs) {
      this.cache.delete(key);
      return null;
    }

    // Move to end (most recently used)
    this.cache.delete(key);
    this.cache.set(key, entry);

    return entry.value;
  }

  set(key: string, value: T): void {
    // Remove if exists to update position
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }

    // Evict oldest if at capacity
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      if (firstKey) {
        this.cache.delete(firstKey);
      }
    }

    this.cache.set(key, {
      value,
      timestamp: Date.now()
    });
  }

  has(key: string): boolean {
    return this.get(key) !== null;
  }

  clear(): void {
    this.cache.clear();
  }

  size(): number {
    return this.cache.size;
  }

  /**
   * Remove expired entries
   */
  cleanup(): void {
    const now = Date.now();
    for (const [key, entry] of this.cache.entries()) {
      if (now - entry.timestamp > this.ttlMs) {
        this.cache.delete(key);
      }
    }
  }
}

/**
 * MCQ-specific cache with subject-based keys
 */
export class MCQCache {
  private cache: LRUCache<MCQ[]>;

  constructor(maxSize: number = 50, ttlMinutes: number = 5) {
    this.cache = new LRUCache<MCQ[]>(maxSize, ttlMinutes);
    
    // Run cleanup every 5 minutes
    setInterval(() => this.cache.cleanup(), 5 * 60 * 1000);
  }

  getCacheKey(subject: string, choices: number): string {
    return `${subject.toLowerCase().trim()}:${choices}`;
  }

  get(subject: string, choices: number): MCQ | null {
    const key = this.getCacheKey(subject, choices);
    const items = this.cache.get(key);
    
    if (!items || items.length === 0) {
      return null;
    }

    // Return random item from cached array to provide variety
    const randomIndex = Math.floor(Math.random() * items.length);
    return items[randomIndex];
  }

  add(subject: string, choices: number, mcq: MCQ): void {
    const key = this.getCacheKey(subject, choices);
    const existing = this.cache.get(key) || [];
    
    // Limit cache per subject to 20 items for variety
    if (existing.length >= 20) {
      existing.shift();
    }
    
    existing.push(mcq);
    this.cache.set(key, existing);
  }

  clear(): void {
    this.cache.clear();
  }

  size(): number {
    return this.cache.size();
  }
}
