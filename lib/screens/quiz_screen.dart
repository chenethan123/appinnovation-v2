import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  String? selectedAnswer;
  bool showExplanation = false;
  bool hasAnswered = false;

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Reset quiz state when navigating back
          ref.read(quizProvider.notifier).resetQuiz();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(quizState.currentSubject?.name ?? 'Quiz'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.read(quizProvider.notifier).resetQuiz();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            if (quizState.currentQuestion != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${quizState.currentQuestionIndex + 1}/${quizState.totalQuestions}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
          ],
        ),
        body: quizState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : quizState.error != null
                ? _buildErrorView(quizState.error!)
                : quizState.currentQuestion != null
                    ? _buildQuizView(quizState)
                    : _buildNoQuestionView(),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(quizProvider.notifier).clearError();
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuestionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'No questions available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adding more subjects or check your internet connection for AI-generated questions.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView(QuizState quizState) {
    final question = quizState.currentQuestion!;
    final subject = quizState.currentSubject!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(int.parse(subject.color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    subject.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (quizState.questionsAnswered > 0)
                    Text(
                      '${quizState.accuracy.toStringAsFixed(0)}% accuracy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question.difficulty.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedAnswer == option;
            final isCorrect = option == question.correctAnswer;
            
            Color? cardColor;
            Color? textColor;
            IconData? icon;

            if (hasAnswered) {
              if (isCorrect) {
                cardColor = Colors.green.withOpacity(0.1);
                textColor = Colors.green;
                icon = Icons.check_circle;
              } else if (isSelected && !isCorrect) {
                cardColor = Colors.red.withOpacity(0.1);
                textColor = Colors.red;
                icon = Icons.cancel;
              }
            } else if (isSelected) {
              cardColor = Theme.of(context).colorScheme.primaryContainer;
              textColor = Theme.of(context).colorScheme.onPrimaryContainer;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                color: cardColor,
                child: InkWell(
                  onTap: hasAnswered ? null : () {
                    setState(() {
                      selectedAnswer = option;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: textColor ?? Theme.of(context).colorScheme.outline,
                              width: 2,
                            ),
                            color: isSelected && !hasAnswered 
                                ? Theme.of(context).colorScheme.primary 
                                : null,
                          ),
                          child: Center(
                            child: icon != null 
                                ? Icon(icon, size: 16, color: textColor)
                                : isSelected && !hasAnswered
                                    ? Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onPrimary)
                                    : Text(
                                        String.fromCharCode(65 + index), // A, B, C, D
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textColor ?? Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textColor,
                              fontWeight: isSelected ? FontWeight.w500 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Submit/Next button
          SizedBox(
            width: double.infinity,
            child: hasAnswered
                ? FilledButton(
                    onPressed: () async {
                      await ref.read(quizProvider.notifier).nextQuestion();
                      setState(() {
                        selectedAnswer = null;
                        showExplanation = false;
                        hasAnswered = false;
                      });
                    },
                    child: const Text('Next Question'),
                  )
                : FilledButton(
                    onPressed: selectedAnswer == null ? null : () async {
                      await ref.read(quizProvider.notifier).submitAnswer(selectedAnswer!);
                      setState(() {
                        hasAnswered = true;
                        showExplanation = true;
                      });
                    },
                    child: const Text('Submit Answer'),
                  ),
          ),

          // Explanation
          if (showExplanation && hasAnswered) ...[
            const SizedBox(height: 16),
            if (question.explanation.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedAnswer == question.correctAnswer 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedAnswer == question.correctAnswer ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explanation:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.explanation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (question.source != null || question.sourceUrl != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.source,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.source ?? 'External Source',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
