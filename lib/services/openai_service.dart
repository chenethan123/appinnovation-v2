import 'dart:convert';
import 'dart:math';
import 'package:dart_openai/dart_openai.dart';
import 'package:uuid/uuid.dart';
import '../models/mcq.dart';
import '../database/database_helper.dart';
import '../utils/stem_hasher.dart';

/// Direct OpenAI integration - no backend server needed!
/// This runs entirely within the Flutter app
class OpenAIService {
  static bool _initialized = false;
  
  /// Initialize OpenAI with your API key
  /// Call this once at app startup
  static void initialize(String apiKey) {
    if (!_initialized) {
      OpenAI.apiKey = apiKey;
      _initialized = true;
      print('✅ OpenAI initialized - ready to generate questions!');
    }
  }
  
  /// Check if OpenAI is initialized
  static bool get isInitialized => _initialized;
  
  /// Generate a novel MCQ using ChatGPT with deduplication
  Future<MCQ?> generateMCQ({
    required String subject,
    required int subjectId,
    int choices = 4,
    int maxRetries = 3,
  }) async {
    if (!_initialized) {
      print('❌ OpenAI not initialized. Call OpenAIService.initialize() first.');
      throw Exception('OpenAI not initialized. Please configure API key.');
    }
    
    final db = DatabaseHelper();
    
    // Fetch recent stems and topics for novelty
    final recentStems = await db.getRecentStems(subjectId, limit: 20);
    final recentTopics = await db.getRecentTopics(subjectId, limit: 20);
    
    print('🔍 Loaded ${recentStems.length} recent stems, ${recentTopics.length} recent topics for novelty check');
    
    int attempt = 0;
    Duration delay = const Duration(seconds: 1);
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        print('🤖 Generating MCQ for: $subject (attempt $attempt/$maxRetries)');
      
      // Build novelty contract in system prompt
      final systemPrompt = '''You are an expert educational content creator. Generate rigorous, unambiguous multiple-choice questions (MCQs) with exactly $choices options.

⚠️ NOVELTY CONTRACT - CRITICAL:
Do NOT repeat or paraphrase ANY of the following recently-seen question stems or topics:

IMPORTANT: Respond ONLY with valid JSON. No markdown, no code blocks, just raw JSON.

Required JSON format:
{
  "stem": "The question text",
  "options": [
    {"letter": "A", "text": "First option"},
    {"letter": "B", "text": "Second option"},
    {"letter": "C", "text": "Third option"},
    {"letter": "D", "text": "Fourth option"}
  ],
  "correct_option": "A",
  "explanation_correct": "Why the correct answer is correct",
  "explanations_by_option": {
    "A": "Why A is correct/incorrect",
    "B": "Why B is correct/incorrect",
    "C": "Why C is correct/incorrect",
    "D": "Why D is correct/incorrect"
  },
  "difficulty": "easy|medium|hard",
  "source_hint": "Topic or concept name"
}''';

      final userPrompt = '''Generate a $difficulty MCQ about "$subject" with exactly $choices options (A-${String.fromCharCode(64 + choices)}).

Requirements:
- Make it educational and accurate
- Include detailed explanations for EACH option
- Explain why wrong answers are incorrect
- Use proper formatting for math/science notation if needed''';

        final chat = await OpenAI.instance.chat.create(
          model: "gpt-4o-mini",
          messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(userPrompt),
            ],
          ),
          ],
          temperature: 0.7,
          maxTokens: 1000,
        );

        final responseText = chat.choices.first.message.content?.first.text ?? '';
        
        // Clean response (remove markdown code blocks if present)
        String cleanJson = responseText.trim();
        if (cleanJson.startsWith('```json')) {
          cleanJson = cleanJson.substring(7);
        }
        if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.substring(3);
        }
        if (cleanJson.endsWith('```')) {
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        }
        cleanJson = cleanJson.trim();
        
        // Parse JSON
        final data = jsonDecode(cleanJson) as Map<String, dynamic>;
        
        // Add required fields
        data['id'] = _generateId();
        data['subject'] = subject;
        
        // Create MCQ object
        final mcq = MCQ.fromJson(data);
        
        print('✅ MCQ generated successfully on attempt $attempt!');
        return mcq;
        
      } catch (error, stackTrace) {
        final errorMessage = error.toString();
        print('⚠️ Attempt $attempt failed: $errorMessage');
        
        // Check for quota/billing errors (403)
        if (errorMessage.contains('403')) {
          print('❌ 403 Error: Account access restricted');
          
          // Check if it's insufficient quota
          if (errorMessage.contains('quota') || errorMessage.contains('insufficient')) {
            print('💡 Quota exceeded - returning fallback question');
            // Return fallback question instead of failing completely
            return _generateFallbackMCQ(subject, choices);
          }
          
          // Account doesn't have model access
          if (errorMessage.contains('does not have access')) {
            print('💡 No model access - may need billing setup');
            
            if (attempt < maxRetries) {
              // Sometimes this is transient - retry a few times
              final backoffDelay = Duration(seconds: 2 * attempt);
              print('⏳ Retrying in ${backoffDelay.inSeconds}s... (attempt $attempt/$maxRetries)');
              await Future.delayed(backoffDelay);
              continue;
            } else {
              // After all retries, return fallback
              print('💡 Returning fallback question after retries');
              return _generateFallbackMCQ(subject, choices);
            }
          }
          
          // Generic 403 - likely billing issue
          throw AuthenticationException(
            'OpenAI account needs billing setup.\n\n'
            'Visit: platform.openai.com/settings/organization/billing\n'
            'Add a payment method to enable API access.'
          );
        }
        
        // Check for rate limit errors (429)
        if (errorMessage.contains('429') || 
            errorMessage.contains('rate') || 
            errorMessage.contains('limit')) {
          print('⚠️ Rate limit detected');
          
          if (attempt < maxRetries) {
            // Calculate delay with exponential backoff + jitter
            final baseDelay = Duration(seconds: 2 * attempt);
            final jitter = Random().nextInt(1000); // 0-1000ms jitter
            delay = baseDelay + Duration(milliseconds: jitter);
            
            print('⏳ Rate limit - waiting ${delay.inSeconds}s before retry...');
            await Future.delayed(delay);
            continue; // Retry
          } else {
            print('❌ Rate limit persists after $maxRetries attempts');
            print('💡 Returning fallback question');
            return _generateFallbackMCQ(subject, choices);
          }
        }
        
        // Check for authentication errors (401)
        if (errorMessage.contains('401') || 
            errorMessage.contains('Incorrect API key') ||
            errorMessage.contains('authentication')) {
          print('❌ Authentication error: Invalid API key');
          throw AuthenticationException(
            'Invalid OpenAI API key.\n\n'
            'Please update your key in:\n'
            'lib/config/api_config.dart\n\n'
            'Get a key from: platform.openai.com/api-keys'
          );
        }
        
        // Check for network errors
        if (errorMessage.contains('SocketException') ||
            errorMessage.contains('Connection') ||
            errorMessage.contains('TimeoutException') ||
            errorMessage.contains('network')) {
          print('⚠️ Network connectivity issue');
          
          if (attempt < maxRetries) {
            final networkDelay = Duration(seconds: 2 << attempt); // Exponential: 2, 4, 8
            print('⏳ Network error - retrying in ${networkDelay.inSeconds}s...');
            await Future.delayed(networkDelay);
            continue;
          } else {
            print('❌ Network unreachable after $maxRetries attempts');
            throw NetworkException(
              'Unable to connect to OpenAI.\n\n'
              'Please check:\n'
              '• Internet connection\n'
              '• Firewall settings\n'
              '• VPN configuration'
            );
          }
        }
        
        // Generic error - retry if attempts remaining
        if (attempt < maxRetries) {
          final genericDelay = Duration(seconds: 2 * attempt);
          print('⏳ Generic error - retrying in ${genericDelay.inSeconds}s...');
          print('📋 Error details: $error');
          await Future.delayed(genericDelay);
          delay = delay * 2;
          continue;
        }
        
        // Max retries exceeded - return fallback instead of throwing
        print('❌ All $maxRetries attempts failed');
        print('📋 Final error: $error');
        print('💡 Returning fallback question as last resort');
        return _generateFallbackMCQ(subject, choices);
      }
    }
    
    // Should never reach here, but just in case
    return null;
  }
  
  /// Generate multiple MCQs for batch pre-warming
  Future<List<MCQ>> generateMCQBatch({
    required String subject,
    required int subjectId,
    int choices = 4,
    int count = 5,
  }) async {
    final mcqs = <MCQ>[];
    
    for (int i = 0; i < count; i++) {
      print('Generating MCQ ${i + 1}/$count...');
      final mcq = await generateMCQ(
        subject: subject,
        subjectId: subjectId,
        choices: choices,
      );
      if (mcq != null) {
        mcqs.add(mcq);
      }
      
      // Small delay to avoid rate limits
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    print('✅ Generated ${mcqs.length}/$count MCQs');
    return mcqs;
  }
  
  /// Generate a unique ID for the MCQ
  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999).toString().padLeft(6, '0');
    return 'mcq-$timestamp-$randomPart';
  }
  
  /// Generate a fallback MCQ when API is unavailable
  /// This ensures the app never completely fails
  MCQ _generateFallbackMCQ(String subject, int choices) {
    print('📝 Generating fallback question for: $subject');
    
    // Subject-specific fallback questions
    final fallbackQuestions = {
      'mathematics': _getMathFallback(choices),
      'math': _getMathFallback(choices),
      'calculus': _getCalculusFallback(choices),
      'chemistry': _getChemistryFallback(choices),
      'physics': _getPhysicsFallback(choices),
      'biology': _getBiologyFallback(choices),
      'computer science': _getCSFallback(choices),
      'cs': _getCSFallback(choices),
    };
    
    // Try to find subject-specific fallback
    final subjectLower = subject.toLowerCase();
    for (final key in fallbackQuestions.keys) {
      if (subjectLower.contains(key)) {
        return fallbackQuestions[key]!;
      }
    }
    
    // Generic fallback
    return _getGenericFallback(subject, choices);
  }
  
  MCQ _getMathFallback(int choices) {
    return MCQ(
      id: _generateId(),
      subject: 'Mathematics',
      stem: 'What is the value of 7 × 8?',
      options: [
        MCQOption(letter: 'A', text: '54'),
        MCQOption(letter: 'B', text: '56'),
        MCQOption(letter: 'C', text: '63'),
        MCQOption(letter: 'D', text: '72'),
      ],
      correctOption: 'B',
      explanationCorrect: '7 × 8 = 56. This is a basic multiplication fact.',
      explanationsByOption: {
        'A': 'This would be 6 × 9, not 7 × 8.',
        'B': 'Correct! 7 × 8 = 56.',
        'C': 'This would be 7 × 9, not 7 × 8.',
        'D': 'This would be 8 × 9, not 7 × 8.',
      },
      difficulty: 'easy',
      sourceHint: 'Offline fallback question',
    );
  }
  
  MCQ _getCalculusFallback(int choices) {
    return MCQ(
      id: _generateId(),
      subject: 'Calculus',
      stem: 'What is the derivative of x² with respect to x?',
      options: [
        MCQOption(letter: 'A', text: 'x'),
        MCQOption(letter: 'B', text: '2x'),
        MCQOption(letter: 'C', text: 'x²'),
        MCQOption(letter: 'D', text: '2'),
      ],
      correctOption: 'B',
      explanationCorrect: 'Using the power rule: d/dx(x²) = 2x¹ = 2x',
      explanationsByOption: {
        'A': 'You might be thinking of the derivative of x², but forgot to multiply by the exponent.',
        'B': 'Correct! Using the power rule: d/dx(x²) = 2x',
        'C': 'This is the original function, not its derivative.',
        'D': 'This would be the second derivative, not the first.',
      },
      difficulty: 'medium',
      sourceHint: 'Offline fallback question',
    );
  }
  
  MCQ _getChemistryFallback(int choices) {
    return MCQ(
      id: _generateId(),
      subject: 'Chemistry',
      stem: 'What is the chemical symbol for water?',
      options: [
        MCQOption(letter: 'A', text: 'H₂O'),
        MCQOption(letter: 'B', text: 'O₂'),
        MCQOption(letter: 'C', text: 'CO₂'),
        MCQOption(letter: 'D', text: 'H₂'),
      ],
      correctOption: 'A',
      explanationCorrect: 'Water is H₂O - two hydrogen atoms bonded to one oxygen atom.',
      explanationsByOption: {
        'A': 'Correct! Water is H₂O (2 hydrogen + 1 oxygen).',
        'B': 'This is oxygen gas, not water.',
        'C': 'This is carbon dioxide, not water.',
        'D': 'This is hydrogen gas, not water.',
      },
      difficulty: 'easy',
      sourceHint: 'Offline fallback question',
    );
  }
  
  MCQ _getPhysicsFallback(int choices) {
    return MCQ(
      id: _generateId(),
      subject: 'Physics',
      stem: 'What is the acceleration due to gravity on Earth?',
      options: [
        MCQOption(letter: 'A', text: '8.8 m/s²'),
        MCQOption(letter: 'B', text: '9.8 m/s²'),
        MCQOption(letter: 'C', text: '10.8 m/s²'),
        MCQOption(letter: 'D', text: '11.8 m/s²'),
      ],
      correctOption: 'B',
      explanationCorrect: 'The standard acceleration due to gravity on Earth is approximately 9.8 m/s².',
      explanationsByOption: {
        'A': 'This is slightly too low. The actual value is 9.8 m/s².',
        'B': 'Correct! g = 9.8 m/s² (sometimes approximated as 10 m/s²)',
        'C': 'This is slightly too high. The actual value is 9.8 m/s².',
        'D': 'This is too high. The actual value is 9.8 m/s².',
      },
      difficulty: 'easy',
      sourceHint: 'Offline fallback question',
    );
  }
  
  MCQ _getBiologyFallback(int choices) {
    return MCQ(
      id: _generateId(),
      subject: 'Biology',
      stem: 'What is the powerhouse of the cell?',
      options: [
        MCQOption(letter: 'A', text: 'Nucleus'),
        MCQOption(letter: 'B', text: 'Mitochondria'),
        MCQOption(letter: 'C', text: 'Ribosome'),
        MCQOption(letter: 'D', text: 'Chloroplast'),
      ],
      correctOption: 'B',
      explanationCorrect: 'Mitochondria are the powerhouse of the cell, producing ATP through cellular respiration.',
      explanationsByOption: {
        'A': 'The nucleus contains genetic material but does not produce energy.',
        'B': 'Correct! Mitochondria produce ATP, the energy currency of cells.',
        'C': 'Ribosomes synthesize proteins, not energy.',
        'D': 'Chloroplasts are found in plant cells for photosynthesis, not in all cells.',
      },
      difficulty: 'easy',
      sourceHint: 'Offline fallback question',
    );
  }
  
  MCQ _getCSFallback(int choices) {
    return MCQ(
      id: _generateId(),
      subject: 'Computer Science',
      stem: 'What does CPU stand for?',
      options: [
        MCQOption(letter: 'A', text: 'Central Processing Unit'),
        MCQOption(letter: 'B', text: 'Computer Personal Unit'),
        MCQOption(letter: 'C', text: 'Central Program Utility'),
        MCQOption(letter: 'D', text: 'Computer Processing Unit'),
      ],
      correctOption: 'A',
      explanationCorrect: 'CPU stands for Central Processing Unit - the brain of the computer.',
      explanationsByOption: {
        'A': 'Correct! CPU = Central Processing Unit',
        'B': 'Incorrect. CPU stands for Central Processing Unit.',
        'C': 'Incorrect. CPU stands for Central Processing Unit.',
        'D': 'Close, but it\'s "Central" not "Computer" Processing Unit.',
      },
      difficulty: 'easy',
      sourceHint: 'Offline fallback question',
    );
  }
  
  MCQ _getGenericFallback(String subject, int choices) {
    return MCQ(
      id: _generateId(),
      subject: subject,
      stem: 'Which of the following is a fundamental concept in $subject?',
      options: [
        MCQOption(letter: 'A', text: 'Understanding basic principles'),
        MCQOption(letter: 'B', text: 'Memorizing formulas without context'),
        MCQOption(letter: 'C', text: 'Ignoring foundational knowledge'),
        MCQOption(letter: 'D', text: 'Skipping practice problems'),
      ],
      correctOption: 'A',
      explanationCorrect: 'Understanding basic principles is key to mastering any subject.',
      explanationsByOption: {
        'A': 'Correct! Fundamental understanding is crucial for learning.',
        'B': 'Memorization without understanding is not effective learning.',
        'C': 'Foundational knowledge is essential, not something to ignore.',
        'D': 'Practice is important for skill development.',
      },
      difficulty: 'easy',
      sourceHint: 'Offline fallback question - API unavailable',
    );
  }
  
  String difficulty = 'medium'; // Can be customized per call
}

// Custom exceptions for better error handling
class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class GenerationException implements Exception {
  final String message;
  GenerationException(this.message);
  @override
  String toString() => message;
}
