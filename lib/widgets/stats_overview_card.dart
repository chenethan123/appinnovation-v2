import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart';

class StatsOverviewCard extends ConsumerWidget {
  const StatsOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            subjectsAsync.when(
              data: (subjects) {
                final activeSubjects = subjects.where((s) => s.isActive).toList();
                final totalQuestions = subjects.fold<int>(0, (sum, s) => sum + s.totalQuestions);
                final totalCorrect = subjects.fold<int>(0, (sum, s) => sum + s.correctAnswers);
                final overallAccuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

                return Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.subject,
                        label: 'Subjects',
                        value: '${activeSubjects.length}',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.quiz,
                        label: 'Questions',
                        value: '$totalQuestions',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.trending_up,
                        label: 'Accuracy',
                        value: '${overallAccuracy.toStringAsFixed(0)}%',
                        color: _getAccuracyColor(overallAccuracy),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Row(
                children: [
                  Expanded(child: _StatItemSkeleton()),
                  Expanded(child: _StatItemSkeleton()),
                  Expanded(child: _StatItemSkeleton()),
                ],
              ),
              error: (_, __) => const Text('Error loading stats'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatItemSkeleton extends StatelessWidget {
  const _StatItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
