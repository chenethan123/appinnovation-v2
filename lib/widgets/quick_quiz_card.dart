import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/mcq_provider.dart';
import '../screens/quiz_screen.dart';
import '../screens/mcq_quiz_screen.dart';
import './difficulty_selector_dialog.dart';

class QuickQuizCard extends ConsumerWidget {
  const QuickQuizCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSubjects = ref.watch(activeSubjectsProvider);
    final todayQuizCount = ref.watch(todayQuizCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.flash_on,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Quiz',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Test your knowledge instantly',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (activeSubjects.isEmpty)
              Column(
                children: [
                  Text(
                    'No active subjects available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to subjects screen
                    },
                    child: const Text('Add Subjects'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        // Start random quiz
                        final quizNotifier = ref.read(quizProvider.notifier);
                        await quizNotifier.startQuiz();
                        
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const QuizScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Random Quiz'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        // Show difficulty selector
                        final difficulty = await showDifficultySelector(context);
                        if (difficulty != null && context.mounted) {
                          ref.read(mcqQuizProvider.notifier).generateRandomMCQ(difficulty: difficulty);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MCQQuizScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('AI Quiz'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Today's progress
                  todayQuizCount.when(
                    data: (count) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.today,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today: $count quizzes completed',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (count > 0)
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
