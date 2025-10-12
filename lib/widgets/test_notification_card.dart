import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class TestNotificationCard extends StatefulWidget {
  const TestNotificationCard({Key? key}) : super(key: key);

  @override
  State<TestNotificationCard> createState() => _TestNotificationCardState();
}

class _TestNotificationCardState extends State<TestNotificationCard> {
  final NotificationService _notificationService = NotificationService();
  int _selectedMinutes = 1;
  bool _isScheduling = false;
  String? _scheduledTime;

  Future<void> _scheduleTestNotification() async {
    setState(() {
      _isScheduling = true;
    });

    try {
      // Request permissions first
      final granted = await _notificationService.requestPermissions();
      
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Notification permissions denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isScheduling = false;
        });
        return;
      }

      // Schedule the notification
      await _notificationService.scheduleTestNotification(_selectedMinutes);
      
      final scheduledTime = DateTime.now().add(Duration(minutes: _selectedMinutes));
      
      if (mounted) {
        setState(() {
          _scheduledTime = '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test notification scheduled for $_scheduledTime'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScheduling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Test Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Schedule a test notification to see how they work!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Minutes selector
            Row(
              children: [
                const Text('Notify me in: '),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _selectedMinutes.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_selectedMinutes min',
                    onChanged: (value) {
                      setState(() {
                        _selectedMinutes = value.toInt();
                      });
                    },
                  ),
                ),
                Text(
                  '$_selectedMinutes min',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Schedule button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isScheduling ? null : _scheduleTestNotification,
                icon: _isScheduling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.alarm_add),
                label: Text(_isScheduling 
                    ? 'Scheduling...' 
                    : 'Schedule Test Notification'),
              ),
            ),
            
            // Show scheduled time
            if (_scheduledTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notification scheduled for $_scheduledTime',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
