import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/mcq_provider.dart';
import '../widgets/subject_card.dart';
import '../widgets/quick_quiz_card.dart';
import '../widgets/timer_quiz_card.dart';
import '../widgets/stats_overview_card.dart';
import '../widgets/test_notification_card.dart';
import 'subjects_screen.dart';
import 'quiz_screen.dart';
import 'mcq_quiz_screen.dart';
import 'mcq_loading_screen.dart';
import 'settings_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const _QuizTab(),
    const SubjectsScreen(),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.subject_outlined),
            selectedIcon: Icon(Icons.subject),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _QuizTab extends ConsumerWidget {
  const _QuizTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        automaticallyImplyLeading: false,
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No subjects available',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add subjects first to start taking quizzes!',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        // Switch to subjects tab
                        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                        homeState?.setState(() {
                          homeState._selectedIndex = 2; // Subjects tab
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Subjects'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI-Powered Quiz',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a subject for a fresh ChatGPT-generated question',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(int.parse(subject.color.replaceFirst('#', '0xFF'))),
                            child: Text(
                              subject.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            subject.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            subject.description.isNotEmpty ? subject.description : 'No description',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          trailing: SizedBox(
                            width: 80,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.psychology,
                                        size: 12,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'AI',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                          onTap: () {
                            // Navigate to full-screen loading view immediately
                            // This screen handles generation, retries, and transitions
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MCQLoadingScreen(
                                  subjectName: subject.name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading subjects: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(subjectProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectProvider);
    final todayQuizCountAsync = ref.watch(todayQuizCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formula Quizzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notification settings or pending notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subjectProvider);
          ref.invalidate(todayQuizCountProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section with Manage Subjects button
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Welcome back!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                              homeState?.setState(() {
                                homeState._selectedIndex = 2; // Navigate to Subjects tab
                              });
                            },
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('Subjects', style: TextStyle(fontSize: 13)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to test your knowledge? Start a quiz or manage your subjects.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      todayQuizCountAsync.when(
                        data: (count) => Text(
                          'Quizzes completed today: $count',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Quiz section
              const QuickQuizCard(),
              const SizedBox(height: 24),

              // Test Notifications
              const TestNotificationCard(),
              const SizedBox(height: 24),

              // Timer Quiz section
              const TimerQuizCard(),
              const SizedBox(height: 24),

              // Stats Overview
              const StatsOverviewCard(),
              const SizedBox(height: 24),

              // Recent Subjects
              Text(
                'Your Subjects',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              subjectsAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.subject_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No subjects yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first subject to start quizzing!',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SubjectsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Subject'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final activeSubjects = subjects.where((s) => s.isActive).take(3).toList();
                  
                  return Column(
                    children: [
                      ...activeSubjects.map((subject) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SubjectCard(
                          subject: subject,
                          onTap: () {
                            print('🎯 Home page subject tapped: ${subject.name}');
                            // Navigate to full-screen loading view for AI quiz
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MCQLoadingScreen(
                                  subjectName: subject.name,
                                ),
                              ),
                            );
                          },
                        ),
                      )),
                      if (subjects.length > 3)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SubjectsScreen(),
                              ),
                            );
                          },
                          child: Text('View all ${subjects.length} subjects'),
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Error loading subjects: $error'),
                        TextButton(
                          onPressed: () => ref.invalidate(subjectProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
