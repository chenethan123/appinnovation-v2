import 'dart:convert';
import 'dart:math';
import 'package:dart_openai/dart_openai.dart';
import 'package:uuid/uuid.dart';
import '../models/mcq.dart';
import '../database/database_helper.dart';
import '../utils/stem_hasher.dart';

/// Enhanced OpenAI integration with novelty enforcement and deduplication
class OpenAIServiceNovel {
  static bool _initialized = false;
  final _uuid = const Uuid();
  final _db = DatabaseHelper();
  
  /// Initialize OpenAI with your API key
  static void initialize(String apiKey) {
    if (!_initialized) {
      OpenAI.apiKey = apiKey;
      _initialized = true;
      print('✅ OpenAI initialized with novelty enforcement!');
    }
  }
  
  static bool get isInitialized => _initialized;
  
  /// Generate a novel MCQ with deduplication
  Future<MCQ?> generateMCQ({
    required String subject,
    required int subjectId,
    int choices = 4,
    int maxRetries = 3,
    String? difficulty,  // 'easy', 'medium', 'hard', or null for mixed
    String? unitContext,  // Current unit/topic being studied
  }) async {
    if (!_initialized) {
      throw Exception('OpenAI not initialized');
    }
    
    // Fetch recent stems and topics for novelty
    final recentStems = await _db.getRecentStems(subjectId, limit: 20);
    final recentTopics = await _db.getRecentTopics(subjectId, limit: 20);
    
    print('🔍 Novelty check: ${recentStems.length} recent stems, ${recentTopics.length} topics');
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🤖 Generating novel MCQ for: $subject (attempt $attempt/$maxRetries)');
        
        // Build novelty contract prompt
        final systemPrompt = _buildNoveltyPrompt(choices, recentStems, recentTopics, subject, difficulty, unitContext);
        final userPrompt = _buildUserPrompt(subject, choices, recentTopics, attempt, difficulty, unitContext);
        
        // Call OpenAI with novelty parameters
        final chat = await OpenAI.instance.chat.create(
          model: "gpt-4o-mini",
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.system,
              content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
            ),
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.user,
              content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userPrompt)],
            ),
          ],
          temperature: 0.9,         // High for variety
          topP: 0.9,               // Nucleus sampling
          presencePenalty: 0.6,    // Discourage repetition
          frequencyPenalty: 0.6,   // Discourage common patterns
          maxTokens: 1200,
        );

        final responseText = chat.choices.first.message.content?.first.text ?? '';
        final cleanJson = _cleanJsonResponse(responseText);
        final data = jsonDecode(cleanJson) as Map<String, dynamic>;
        
        // Generate unique ID
        final mcqId = _uuid.v4();
        data['id'] = mcqId;
        data['subject'] = subject;
        
        final mcq = MCQ.fromJson(data);
        
        // Deduplication check
        final stemHash = StemHasher.hashStem(mcq.stem);
        final isDuplicate = await _db.stemExists(subjectId, stemHash);
        
        if (isDuplicate) {
          print('⚠️ Duplicate stem detected! Hash collision on attempt $attempt');
          
          if (attempt < maxRetries) {
            print('🔄 Retrying with perturbation...');
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue; // Retry with different prompt
          } else {
            print('❌ Max retries reached with duplicates - returning anyway');
          }
        }
        
        // Save to database
        await _saveMCQToDatabase(mcq, subjectId, stemHash);
        
        print('✅ Novel MCQ generated and saved (hash: ${stemHash.substring(0, 8)}...)');
        return mcq;
        
      } catch (error) {
        print('⚠️ Attempt $attempt failed: $error');
        
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        }
        
        print('❌ All attempts failed - returning fallback');
        return _generateFallbackMCQ(subject, choices);
      }
    }
    
    return null;
  }
  
  String _buildNoveltyPrompt(int choices, List<String> recentStems, List<String> recentTopics, String subject, String? difficulty, String? unitContext) {
    final stemsSection = recentStems.isNotEmpty
        ? '\n\nRECENT QUESTION STEMS (DO NOT REPEAT):\n${recentStems.take(10).map((s) => '- $s').join('\n')}'
        : '';
    
    final topicsSection = recentTopics.isNotEmpty
        ? '\n\nRECENT TOPICS COVERED (CHOOSE DIFFERENT CONCEPTS):\n${recentTopics.take(10).map((t) => '- $t').join('\n')}'
        : '';
    
    final unitFocusSection = unitContext != null
        ? '\n🎯 UNIT FOCUS: The student is currently studying "$unitContext". Generate questions specifically related to this unit/topic within $subject.\n'
        : '';
    
    return '''You are an expert educational content creator specializing in **$subject**.

🎯 CRITICAL REQUIREMENT - SUBJECT VERIFICATION:
You MUST generate a question that is DIRECTLY RELEVANT to "$subject" and ONLY "$subject".$unitFocusSection
- If the subject is "Introduction to Philosophy", generate questions about philosophical concepts, theories, and thinkers.
- If the subject is "Calculus", generate questions about derivatives, integrals, and limits.
- If the subject is "AP Computer Science A", generate questions about Java programming and CS concepts.
- DO NOT mix subjects. DO NOT generate calculus questions for philosophy or vice versa.
- The question MUST be verifiable as being about "$subject" by reading the stem and options.

⚠️ NOVELTY CONTRACT - CRITICAL:
Do NOT repeat, paraphrase, or create questions similar to the following recently-seen content:$stemsSection$topicsSection

REQUIREMENTS:
- Generate a completely DIFFERENT question on a NEW topic/concept
- Use novel phrasing and question structure
- Focus on unexplored aspects of the subject
- Ensure all options are plausible but clearly distinguishable

OUTPUT FORMAT (JSON only, no markdown):
{
  "stem": "The question text",
  "options": [
    {"letter": "A", "text": "Option 1"},
    {"letter": "B", "text": "Option 2"},
    {"letter": "C", "text": "Option 3"},
    {"letter": "D", "text": "Option 4"}
  ],
  "correct_option": "A",
  "explanation_correct": "Why this answer is correct",
  "explanations_by_option": {
    "A": "Explanation for A",
    "B": "Explanation for B",
    "C": "Explanation for C",
    "D": "Explanation for D"
  },
  "difficulty": "${difficulty ?? 'medium'}",
  "source_hint": "Specific topic/concept name"
}''';
  }
  
  String _buildUserPrompt(String subject, int choices, List<String> recentTopics, int attempt, String? difficulty, String? unitContext) {
    final perturbation = attempt > 1
        ? '\n\nIMPORTANT: Previous attempts were too similar. Generate a question on a COMPLETELY DIFFERENT concept than: ${recentTopics.take(3).join(', ')}'
        : '';
    
    final difficultyText = difficulty != null && difficulty != 'all' ? difficulty : 'varied difficulty';
    final difficultyGuidance = difficulty != null && difficulty != 'all'
        ? '\n- Difficulty Level: ${difficulty.toUpperCase()} - ${_getDifficultyGuidance(difficulty)}'
        : '';
    
    final unitFocus = unitContext != null
        ? '\n\n🎯 UNIT FOCUS: Generate questions specifically about "$unitContext" within $subject.\n- Focus on concepts, terminology, and problems from this unit\n- Stay within the scope of $unitContext'
        : '';
    
    return '''Generate a $difficultyText MCQ **specifically about "$subject"** with exactly $choices options (A-${String.fromCharCode(64 + choices)}).$unitFocus

🎯 SUBJECT VERIFICATION:
- The question MUST be directly relevant to "$subject"${unitContext != null ? ' and specifically about "$unitContext"' : ''}
- All options MUST relate to "$subject" content
- DO NOT generate questions from other subjects
- Verify your question is actually about "$subject" before responding

Requirements:
- Choose a NOVEL topic not in the recent list above
- Stay strictly within the "$subject" domain
- Make it educational, accurate, and unambiguous$difficultyGuidance
- Include detailed explanations for EACH option
- Explain why wrong answers are incorrect
- Use proper formatting for math/science notation if needed$perturbation

Generate ONLY valid JSON, no other text.''';
  }
  
  String _getDifficultyGuidance(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Test basic definitions, fundamental concepts, or simple recall. Suitable for beginners.';
      case 'medium':
        return 'Test understanding and application of concepts. Requires some analysis.';
      case 'hard':
        return 'Test advanced understanding, synthesis, or complex problem-solving. Requires deep knowledge.';
      default:
        return '';
    }
  }
  
  String _cleanJsonResponse(String response) {
    String clean = response.trim();
    if (clean.startsWith('```json')) clean = clean.substring(7);
    if (clean.startsWith('```')) clean = clean.substring(3);
    if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
    return clean.trim();
  }
  
  Future<void> _saveMCQToDatabase(MCQ mcq, int subjectId, String stemHash) async {
    try {
      final mcqData = {
        'id': mcq.id,
        'subject_id': subjectId,
        'stem': mcq.stem,
        'stem_hash': stemHash,
        'correct_option': mcq.correctOption,
        'options': jsonEncode(mcq.options.map((o) => {'letter': o.letter, 'text': o.text}).toList()),
        'explanation_correct': mcq.explanationCorrect,
        'explanations_by_option': jsonEncode(mcq.explanationsByOption),
        'difficulty': mcq.difficulty,
        'source_hint': mcq.sourceHint,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _db.insertMCQHistory(mcqData);
      print('💾 MCQ saved to history');
    } catch (e) {
      print('⚠️ Failed to save MCQ to database: $e');
    }
  }
  
  /// Log MCQ completion
  Future<void> logCompletion({
    required String mcqId,
    required int subjectId,
    required String pickedOption,
    required bool wasCorrect,
    required double accuracyAfter,
  }) async {
    try {
      final completionData = {
        'id': _uuid.v4(),
        'mcq_id': mcqId,
        'subject_id': subjectId,
        'picked_option': pickedOption,
        'was_correct': wasCorrect ? 1 : 0,
        'accuracy_after': accuracyAfter,
        'happened_at': DateTime.now().toIso8601String(),
      };
      
      await _db.insertMCQCompletion(completionData);
      print('📊 Completion logged: ${wasCorrect ? '✓' : '✗'} | Accuracy: ${accuracyAfter.toStringAsFixed(1)}%');
    } catch (e) {
      print('⚠️ Failed to log completion: $e');
    }
  }
  
  MCQ _generateFallbackMCQ(String subject, int choices) {
    print('📝 Generating fallback question');
    return MCQ(
      id: _uuid.v4(),
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
      sourceHint: 'Fallback question - API unavailable',
    );
  }
  
  String difficulty = 'medium';
}
