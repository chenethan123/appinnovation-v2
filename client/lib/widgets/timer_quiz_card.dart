import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart';
import '../providers/quiz_provider.dart';
import '../screens/quiz_screen.dart';

class TimerQuizCard extends ConsumerStatefulWidget {
  const TimerQuizCard({super.key});

  @override
  ConsumerState<TimerQuizCard> createState() => _TimerQuizCardState();
}

class _TimerQuizCardState extends ConsumerState<TimerQuizCard> {
  int _minMinutes = 5;
  int _maxMinutes = 15;
  bool _timerActive = false;

  @override
  Widget build(BuildContext context) {
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
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timer,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timer Quiz',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Auto-generate quizzes at random intervals',
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

            // Timer controls
            if (!_timerActive) ...[
              Text(
                'Interval Range',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Min: $_minMinutes min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Slider(
                          value: _minMinutes.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          onChanged: (value) {
                            if (!mounted) return;
                            setState(() {
                              _minMinutes = value.toInt();
                              if (_minMinutes >= _maxMinutes) {
                                _maxMinutes = _minMinutes + 1;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Max: $_maxMinutes min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Slider(
                          value: _maxMinutes.toDouble(),
                          min: 2,
                          max: 60,
                          divisions: 58,
                          onChanged: (value) {
                            if (!mounted) return;
                            setState(() {
                              _maxMinutes = value.toInt();
                              if (_maxMinutes <= _minMinutes) {
                                _minMinutes = _maxMinutes - 1;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  if (!mounted) return;
                  setState(() {
                    _timerActive = true;
                  });
                  // TODO: Implement actual timer logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Timer started! ($_minMinutes-$_maxMinutes min intervals)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Timer'),
              ),
            ] else ...[
              // Timer active - show controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timer Active',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                'Random quizzes every $_minMinutes-$_maxMinutes minutes',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            if (!mounted) return;
                            setState(() {
                              _timerActive = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Timer stopped'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            final subjectsAsync = ref.read(subjectProvider);
                            final subjects = subjectsAsync.valueOrNull ?? [];
                            final activeSubjects = subjects.where((s) => s.isActive).toList();
                            
                            if (activeSubjects.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No active subjects available')),
                                );
                              }
                              return;
                            }
                            
                            // Pick random subject
                            final randomSubject = activeSubjects[
                              DateTime.now().millisecond % activeSubjects.length
                            ];
                            
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
                          icon: const Icon(Icons.quiz),
                          label: const Text('Quiz Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
