/**
 * Quiz Screen
 * Take quiz for a subject
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _isStarted = false;
  bool _showingResult = false;
  String? _selectedAnswer;
  Map<String, dynamic>? _currentResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartDialog();
    });
  }

  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Start your quiz'),
            const SizedBox(height: 16),
            const Text('Choose quiz settings:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _startQuiz();
            },
            child: const Text('Start Quiz (5 Questions)'),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuiz() async {
    if (!mounted) return;
    
    try {
      // Quiz should already be started before navigating here
      // await ref.read(quizProvider.notifier).startQuiz(...);

      if (!mounted) return;
      setState(() {
        _isStarted = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting quiz: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) return;

    try {
      final result = await ref.read(quizProvider.notifier).submitAnswer(_selectedAnswer!);
      
      if (!mounted) return;
      setState(() {
        _showingResult = true;
        _currentResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting answer: $e')),
      );
    }
  }

  void _nextQuestion() {
    final quizState = ref.read(quizProvider);
    
    if (quizState.hasMoreQuestions) {
      ref.read(quizProvider.notifier).nextQuestion();
      setState(() {
        _selectedAnswer = null;
        _showingResult = false;
        _currentResult = null;
      });
    } else {
      _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    try {
      final result = await ref.read(quizProvider.notifier).completeQuiz();
      
      if (!mounted) return;
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quiz Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${result['score']}/${result['total_questions']}',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Accuracy: ${result['accuracy'].toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing quiz: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    if (!_isStarted || quizState.currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = quizState.currentQuestion;
    if (currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Question ${quizState.currentQuestionIndex + 1}/${quizState.currentSession!.totalQuestions}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (quizState.currentQuestionIndex + 1) / quizState.currentSession!.totalQuestions,
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Question text
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                currentQuestion.difficulty.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            if (currentQuestion.isFromAI) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.psychology, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI Generated',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentQuestion.questionText,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Options
                ...currentQuestion.options.map((option) {
                  final isSelected = _selectedAnswer == option;
                  final isCorrect = _currentResult != null && option == _currentResult!['correct_answer'];
                  final isWrong = _showingResult && isSelected && !isCorrect;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: _showingResult ? null : () {
                        setState(() {
                          _selectedAnswer = option;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCorrect && _showingResult
                              ? Colors.green.withOpacity(0.2)
                              : isWrong
                                  ? Colors.red.withOpacity(0.2)
                                  : isSelected
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Colors.grey.withOpacity(0.1),
                          border: Border.all(
                            color: isCorrect && _showingResult
                                ? Colors.green
                                : isWrong
                                    ? Colors.red
                                    : isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (_showingResult) ...[
                              Icon(
                                isCorrect ? Icons.check_circle : isWrong ? Icons.cancel : Icons.circle_outlined,
                                color: isCorrect ? Colors.green : isWrong ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                option,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Explanation (shown after answering)
                if (_showingResult && _currentResult != null) ...[
                  Card(
                    color: _currentResult!['is_correct']
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _currentResult!['is_correct'] ? Icons.check_circle : Icons.info,
                                color: _currentResult!['is_correct'] ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currentResult!['is_correct'] ? 'Correct!' : 'Incorrect',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: _currentResult!['is_correct'] ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_currentResult!['explanation']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit/Next button
                FilledButton(
                  onPressed: _showingResult
                      ? _nextQuestion
                      : (_selectedAnswer != null ? _submitAnswer : null),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_showingResult
                      ? (quizState.hasMoreQuestions ? 'Next Question' : 'Complete Quiz')
                      : 'Submit Answer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
