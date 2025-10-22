import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/mcq_provider.dart';
import '../providers/course_provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/background_sync_service.dart';
import 'question_management_screen.dart';
import 'auth_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(quizSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz Schedule Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz Schedule',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Notifications toggle
                      SwitchListTile(
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Receive quiz reminders'),
                        value: settings.notificationsEnabled,
                        onChanged: (value) async {
                          if (value) {
                            final granted = await NotificationService().requestPermissions();
                            if (!granted) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notification permission denied'),
                                  ),
                                );
                              }
                              return;
                            }
                          }
                          
                          final updatedSettings = settings.copyWith(
                            notificationsEnabled: value,
                            updatedAt: DateTime.now(),
                          );
                          await ref.read(quizSettingsProvider.notifier).updateSettings(updatedSettings);
                          
                          if (value) {
                            await NotificationService().scheduleQuizNotifications(updatedSettings);
                          } else {
                            await NotificationService().cancelAllNotifications();
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      const Divider(),
                      
                      // Daily quiz limit
                      ListTile(
                        title: const Text('Daily Quiz Limit'),
                        subtitle: Text('${settings.maxDailyQuizzes} quizzes per day'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showDailyLimitDialog(context, settings),
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      const Divider(),
                      
                      // Active hours
                      ListTile(
                        title: const Text('Active Hours'),
                        subtitle: Text('${settings.startHour}:00 - ${settings.endHour}:00'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showActiveHoursDialog(context, settings),
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      const Divider(),
                      
                      // Active days
                      ListTile(
                        title: const Text('Active Days'),
                        subtitle: Text(_getActiveDaysText(settings.activeDays)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showActiveDaysDialog(context, settings),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Question Management Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question Database',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ListTile(
                        leading: const Icon(Icons.quiz),
                        title: const Text('Manage Questions'),
                        subtitle: const Text('Import and manage educational question datasets'),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const QuestionManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Account Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Show user email if logged in
                      if (AuthService().isLoggedIn) ...[
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Logged in as'),
                          subtitle: Text(AuthService().userEmail ?? 'Unknown'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        const Divider(),
                        
                        // Sync status
                        ListTile(
                          leading: const Icon(Icons.cloud),
                          title: const Text('Cloud Sync'),
                          subtitle: const Text('Your data is synced across devices'),
                          trailing: const Icon(Icons.check_circle, color: Colors.green),
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        const Divider(),
                        
                        // Manual sync button
                        ListTile(
                          leading: const Icon(Icons.sync),
                          title: const Text('Sync Now'),
                          subtitle: const Text('Manually sync your data'),
                          trailing: const Icon(Icons.chevron_right),
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            if (!mounted) return;
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🔄 Syncing...')),
                            );
                            
                            try {
                              final result = await SyncService().fullSync();
                              if (!mounted) return;
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.success ? '✅ Sync complete!' : '❌ ${result.message}'),
                                  backgroundColor: result.success ? Colors.green : Colors.red,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Sync failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        
                        const Divider(),
                        
                        // Logout button
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          subtitle: const Text('Sign out of your account'),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ] else ...[
                        // Show login prompt if not logged in
                        ListTile(
                          leading: const Icon(Icons.cloud_off),
                          title: const Text('Offline Mode'),
                          subtitle: const Text('Login to sync across devices'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        const Divider(),
                        
                        // Login button
                        ListTile(
                          leading: const Icon(Icons.login, color: Colors.blue),
                          title: const Text(
                            'Login',
                            style: TextStyle(color: Colors.blue),
                          ),
                          subtitle: const Text('Sign in to enable cloud sync'),
                          trailing: const Icon(Icons.chevron_right),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // App Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ListTile(
                        title: const Text('Version'),
                        subtitle: const Text('1.0.0'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      const Divider(),
                      
                      ListTile(
                        title: const Text('Educational Disclaimer'),
                        subtitle: const Text('AI-generated content for educational purposes only'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(quizSettingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActiveDaysText(List<int> activeDays) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final activeDayNames = activeDays.map((day) => dayNames[day]).toList();
    
    if (activeDayNames.length == 7) return 'Every day';
    if (activeDayNames.length == 5 && 
        activeDays.contains(1) && activeDays.contains(2) && 
        activeDays.contains(3) && activeDays.contains(4) && 
        activeDays.contains(5)) {
      return 'Weekdays';
    }
    
    return activeDayNames.join(', ');
  }

  void _showDailyLimitDialog(BuildContext context, settings) {
    int selectedLimit = settings.maxDailyQuizzes;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Daily Quiz Limit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How many quizzes per day?'),
              const SizedBox(height: 16),
              Slider(
                value: selectedLimit.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                label: '$selectedLimit',
                onChanged: (value) {
                  setDialogState(() {
                    selectedLimit = value.round();
                  });
                },
              ),
              Text('$selectedLimit quizzes per day'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final updatedSettings = settings.copyWith(
                  maxDailyQuizzes: selectedLimit,
                  updatedAt: DateTime.now(),
                );
                await ref.read(quizSettingsProvider.notifier).updateSettings(updatedSettings);
                
                if (updatedSettings.notificationsEnabled) {
                  await NotificationService().scheduleQuizNotifications(updatedSettings);
                }
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showActiveHoursDialog(BuildContext context, settings) {
    int startHour = settings.startHour;
    int endHour = settings.endHour;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Active Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('When should you receive quiz notifications?'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Start Time'),
                        DropdownButton<int>(
                          value: startHour,
                          items: List.generate(24, (i) => DropdownMenuItem(
                            value: i,
                            child: Text('${i.toString().padLeft(2, '0')}:00'),
                          )),
                          onChanged: (value) {
                            if (value != null && value < endHour) {
                              setDialogState(() {
                                startHour = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Text('End Time'),
                        DropdownButton<int>(
                          value: endHour,
                          items: List.generate(24, (i) => DropdownMenuItem(
                            value: i,
                            child: Text('${i.toString().padLeft(2, '0')}:00'),
                          )),
                          onChanged: (value) {
                            if (value != null && value > startHour) {
                              setDialogState(() {
                                endHour = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final updatedSettings = settings.copyWith(
                  startHour: startHour,
                  endHour: endHour,
                  updatedAt: DateTime.now(),
                );
                await ref.read(quizSettingsProvider.notifier).updateSettings(updatedSettings);
                
                if (updatedSettings.notificationsEnabled) {
                  await NotificationService().scheduleQuizNotifications(updatedSettings);
                }
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showActiveDaysDialog(BuildContext context, settings) {
    List<int> selectedDays = List.from(settings.activeDays);
    final dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Active Days'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Which days should you receive quiz notifications?'),
              const SizedBox(height: 16),
              ...List.generate(7, (index) {
                final isSelected = selectedDays.contains(index);
                return CheckboxListTile(
                  title: Text(dayNames[index]),
                  value: isSelected,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        selectedDays.add(index);
                      } else {
                        selectedDays.remove(index);
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedDays.isEmpty ? null : () async {
                final updatedSettings = settings.copyWith(
                  activeDays: selectedDays,
                  updatedAt: DateTime.now(),
                );
                await ref.read(quizSettingsProvider.notifier).updateSettings(updatedSettings);
                
                if (updatedSettings.notificationsEnabled) {
                  await NotificationService().scheduleQuizNotifications(updatedSettings);
                }
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?\n\n'
          'Your data is saved locally and will be synced when you login again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                // Stop background sync
                BackgroundSyncService().stopBackgroundSync();
                
                // Clear all provider cache/state
                print('🗑️ Clearing provider cache...');
                ref.invalidate(subjectProvider);
                ref.invalidate(quizProvider);
                ref.invalidate(mcqQuizProvider);
                ref.invalidate(courseProvider);
                ref.invalidate(quizSettingsProvider);
                print('✅ Provider cache cleared');
                
                // Logout from Supabase (also clears local database)
                await AuthService().signOut();
                
                if (!context.mounted) return;
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Navigate back to auth screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Logout failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
