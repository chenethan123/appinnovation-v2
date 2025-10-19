import 'package:flutter/material.dart';

class DifficultyOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const DifficultyOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}

class DifficultySelectorDialog extends StatefulWidget {
  final String? currentDifficulty;

  const DifficultySelectorDialog({
    super.key,
    this.currentDifficulty,
  });

  @override
  State<DifficultySelectorDialog> createState() => _DifficultySelectorDialogState();
}

class _DifficultySelectorDialogState extends State<DifficultySelectorDialog> {
  String? _selectedDifficulty;

  static const List<DifficultyOption> _options = [
    DifficultyOption(
      value: 'all',
      label: 'All Difficulties',
      description: 'Mix of easy, medium, and hard questions',
      icon: Icons.shuffle,
    ),
    DifficultyOption(
      value: 'easy',
      label: 'Easy',
      description: 'Basic definitions and fundamental concepts',
      icon: Icons.sentiment_satisfied,
    ),
    DifficultyOption(
      value: 'medium',
      label: 'Medium',
      description: 'Understanding and application of concepts',
      icon: Icons.sentiment_neutral,
    ),
    DifficultyOption(
      value: 'hard',
      label: 'Hard',
      description: 'Advanced understanding and problem-solving',
      icon: Icons.sentiment_very_dissatisfied,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.currentDifficulty ?? 'all';
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Difficulty Level'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _options.map((option) {
            final isSelected = _selectedDifficulty == option.value;
            return Card(
              color: isSelected
                  ? _getDifficultyColor(option.value).withValues(alpha: 0.1)
                  : null,
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (!mounted) return;
                  setState(() {
                    _selectedDifficulty = option.value;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        option.icon,
                        size: 32,
                        color: isSelected
                            ? _getDifficultyColor(option.value)
                            : Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? _getDifficultyColor(option.value)
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: _getDifficultyColor(option.value),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedDifficulty);
          },
          child: const Text('Start Quiz'),
        ),
      ],
    );
  }
}

/// Show difficulty selector dialog and return selected difficulty
/// Returns null if cancelled, 'all' for mixed, or 'easy'/'medium'/'hard'
Future<String?> showDifficultySelector(
  BuildContext context, {
  String? currentDifficulty,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => DifficultySelectorDialog(
      currentDifficulty: currentDifficulty,
    ),
  );
}
