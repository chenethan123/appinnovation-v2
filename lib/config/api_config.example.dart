/// API Configuration
/// Choose between backend server or direct OpenAI integration
class ApiConfig {
  // ====== INTEGRATION MODE ======
  // Set to true to call OpenAI directly from Flutter (RECOMMENDED)
  // Set to false to use backend server (requires deployment)
  static const bool useDirectOpenAI = true;
  
  // ====== BACKEND SERVER MODE (only used if useDirectOpenAI = false) ======
  // Set to false for production (uses deployed backend)
  // Set to true for local development (requires running local server)
  static const bool useLocalBackend = false;
  
  // ====== OPENAI DIRECT INTEGRATION ======
  // Your OpenAI API key for direct integration
  // Get it from: https://platform.openai.com/api-keys
  // REPLACE WITH YOUR ACTUAL KEY:
  static const String openAIApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  
  // ====== BACKEND SERVER URLS (only used if useDirectOpenAI = false) ======
  // Production backend URL (deploy your server here)
  // Options: Railway, Render, Fly.io, Heroku, etc.
  static const String productionBaseUrl = 'https://YOUR_APP_NAME.up.railway.app';
  
  // Local development URL
  static const String localBaseUrl = 'http://localhost:8787';
  
  /// Get the active base URL based on environment
  static String get baseUrl {
    return useLocalBackend ? localBaseUrl : productionBaseUrl;
  }
  
  /// API endpoints
  static String get generateMcqEndpoint => '$baseUrl/api/generate-mcq';
  static String get generateMcqBatchEndpoint => '$baseUrl/api/generate-mcq-batch';
  static String get healthEndpoint => '$baseUrl/api/health';
  
  /// Timeout duration for API calls
  static const Duration timeout = Duration(seconds: 30);
  
  /// Display current configuration
  static String get info {
    if (useDirectOpenAI) {
      return 'API Config: DIRECT OpenAI (No backend needed)';
    }
    return 'API Config: ${useLocalBackend ? "LOCAL" : "PRODUCTION"} Backend ($baseUrl)';
  }
  
  /// Check if OpenAI API key is configured
  static bool get hasOpenAIKey {
    return openAIApiKey.isNotEmpty && !openAIApiKey.contains('YOUR');
  }
}
