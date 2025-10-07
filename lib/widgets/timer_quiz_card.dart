import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mcq_provider.dart';
import '../screens/mcq_quiz_screen.dart';

class TimerQuizCard extends ConsumerStatefulWidget {
  const TimerQuizCard({super.key});

  @override
  ConsumerState<TimerQuizCard> createState() => _TimerQuizCardState();
}

class _TimerQuizCardState extends ConsumerState<TimerQuizCard> {
  int _minMinutes = 5;
  int _maxMinutes = 15;

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(mcqQuizProvider);
    final timeUntilNext = ref.watch(timeUntilNextQuizProvider);

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
            if (!quizState.timerActive) ...[
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
                  ref.read(mcqQuizProvider.notifier).startTimer(
                        minMinutes: _minMinutes,
                        maxMinutes: _maxMinutes,
                      );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Timer'),
              ),
            ] else ...[
              // Timer active - show countdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
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
                              timeUntilNext.when(
                                data: (duration) {
                                  if (duration == null) {
                                    return const Text('Calculating...');
                                  }
                                  final minutes = duration.inMinutes;
                                  final seconds = duration.inSeconds % 60;
                                  return Text(
                                    'Next quiz in: ${minutes}m ${seconds}s',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  );
                                },
                                loading: () => const Text('Loading...'),
                                error: (_, __) => const Text('Error'),
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
                            ref.read(mcqQuizProvider.notifier).stopTimer();
                          },
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            ref.read(mcqQuizProvider.notifier).generateRandomMCQ();
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const MCQQuizScreen(),
                                ),
                              );
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

            // Show current question if one is loaded
            if (quizState.currentMCQ != null && !quizState.isAnswered) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notification_important,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'New Question Available!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quizState.currentMCQ!.subject,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MCQQuizScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Take Quiz'),
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
