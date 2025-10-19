import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart';
import '../providers/quiz_provider.dart';
import '../screens/quiz_screen.dart';

class QuickQuizCard extends ConsumerWidget {
  const QuickQuizCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectProvider);

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
            
            subjectsAsync.when(
              data: (subjects) {
                final activeSubjects = subjects.where((s) => s.isActive).toList();
                
                if (activeSubjects.isEmpty) {
                  return Column(
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
                  );
                }
                
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          // Start random quiz from active subjects
                          if (activeSubjects.isEmpty) return;
                          
                          // Pick random subject
                          final randomSubject = activeSubjects[
                            DateTime.now().millisecond % activeSubjects.length
                          ];
                          
                          final quizNotifier = ref.read(quizProvider.notifier);
                          await quizNotifier.startQuiz(randomSubject.name);
                          
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
                          // Pick random subject for AI quiz
                          if (activeSubjects.isEmpty) return;
                          
                          final randomSubject = activeSubjects[
                            DateTime.now().millisecond % activeSubjects.length
                          ];
                          
                          // Start AI quiz
                          try {
                            final quizNotifier = ref.read(quizProvider.notifier);
                            await quizNotifier.startQuiz(randomSubject.name);
                            
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const QuizScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('AI Quiz'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading subjects'),
            ),
          ],
        ),
      ),
    );
  }
}
