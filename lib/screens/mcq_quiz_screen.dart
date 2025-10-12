import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mcq_provider.dart';

class MCQQuizScreen extends ConsumerStatefulWidget {
  const MCQQuizScreen({super.key});

  @override
  ConsumerState<MCQQuizScreen> createState() => _MCQQuizScreenState();
}

class _MCQQuizScreenState extends ConsumerState<MCQQuizScreen> {
  String? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(mcqQuizProvider);
    final mcq = quizState.currentMCQ;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quizState.currentSubject != null 
                ? quizState.currentSubject! 
                : 'AI-Powered Quiz',
              style: const TextStyle(fontSize: 18),
            ),
            if (quizState.totalQuestions > 0)
              Text(
                'Question ${quizState.currentQuestionNumber} of ${quizState.totalQuestions}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (mcq != null && !quizState.isAnswered)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'New Questions',
              onPressed: () {
                // Generate new questions for the current subject
                if (quizState.currentSubject != null) {
                  ref.read(mcqQuizProvider.notifier).generateMCQ(quizState.currentSubject!);
                } else {
                  ref.read(mcqQuizProvider.notifier).generateRandomMCQ();
                }
                setState(() => _selectedAnswer = null);
              },
            ),
        ],
      ),
      body: _buildBody(quizState),
    );
  }

  Widget _buildBody(MCQQuizState quizState) {
    if (quizState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating question with ChatGPT...'),
            SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (quizState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                quizState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(mcqQuizProvider.notifier).generateRandomMCQ();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final mcq = quizState.currentMCQ;
    if (mcq == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Ready to test your knowledge?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Click the button below to generate an AI-powered question',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(mcqQuizProvider.notifier).generateRandomMCQ();
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Question'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subject and difficulty
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(mcq.subject),
                avatar: const Icon(Icons.subject, size: 16),
              ),
              Chip(
                label: Text(mcq.difficulty.toUpperCase()),
                backgroundColor: _getDifficultyColor(mcq.difficulty),
              ),
              if (mcq.sourceHint != null)
                Chip(
                  label: Text(mcq.sourceHint!),
                  avatar: const Icon(Icons.tag, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Question
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                mcq.stem,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...mcq.options.map((option) {
            final isSelected = _selectedAnswer == option.letter;
            final isAnswered = quizState.isAnswered;
            final isCorrect = mcq.correctOption == option.letter;

            Color? cardColor;
            if (isAnswered) {
              if (isCorrect) {
                cardColor = Colors.green.withOpacity(0.1);
              } else if (isSelected) {
                cardColor = Colors.red.withOpacity(0.1);
              }
            }

            return Card(
              color: cardColor,
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: isAnswered
                    ? null
                    : () {
                        setState(() => _selectedAnswer = option.letter);
                      },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Letter
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isAnswered && isCorrect
                              ? Colors.green
                              : isAnswered && isSelected
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            option.letter,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isAnswered && (isCorrect || isSelected)
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Option text
                      Expanded(
                        child: Text(
                          option.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      // Radio/Checkmark
                      if (isAnswered && isCorrect)
                        const Icon(Icons.check_circle, color: Colors.green)
                      else if (isAnswered && isSelected)
                        const Icon(Icons.cancel, color: Colors.red)
                      else if (isSelected)
                        const Icon(Icons.radio_button_checked)
                      else
                        const Icon(Icons.radio_button_unchecked),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Submit button or explanation
          if (!quizState.isAnswered)
            FilledButton(
              onPressed: _selectedAnswer == null
                  ? null
                  : () async {
                      await ref.read(mcqQuizProvider.notifier).submitAnswer(_selectedAnswer!);
                    },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Submit Answer', style: TextStyle(fontSize: 16)),
              ),
            )
          else
            _buildExplanation(quizState),

          const SizedBox(height: 16),

          // Next question button - smart navigation
          if (quizState.isAnswered)
            FilledButton.icon(
              onPressed: () {
                final hasMore = quizState.hasMoreQuestions;
                
                if (hasMore) {
                  // Move to next question in queue
                  ref.read(mcqQuizProvider.notifier).moveToNextQuestion();
                } else {
                  // Generate new questions for the same subject
                  if (quizState.currentSubject != null) {
                    ref.read(mcqQuizProvider.notifier).generateMCQ(quizState.currentSubject!);
                  } else {
                    ref.read(mcqQuizProvider.notifier).generateRandomMCQ();
                  }
                }
                setState(() => _selectedAnswer = null);
              },
              icon: Icon(
                quizState.hasMoreQuestions ? Icons.arrow_forward : Icons.refresh,
              ),
              label: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  quizState.hasMoreQuestions 
                    ? 'Next Question' 
                    : 'Generate More Questions',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExplanation(MCQQuizState quizState) {
    final isCorrect = ref.read(mcqQuizProvider.notifier).isCorrectAnswer();
    final explanation = ref.read(mcqQuizProvider.notifier).getExplanation();

    if (explanation == null) return const SizedBox.shrink();

    return Card(
      color: isCorrect == true
          ? Colors.green.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect == true ? Icons.check_circle : Icons.info_outline,
                  color: isCorrect == true ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect == true ? 'Correct!' : 'Not Quite',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCorrect == true ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              explanation,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              '✨ AI-generated explanation - Educational purpose only',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.withOpacity(0.2);
      case 'hard':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.orange.withOpacity(0.2);
    }
  }
}
