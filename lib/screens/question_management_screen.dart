import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/question_import_service.dart';
import '../database/question_database.dart';

class QuestionManagementScreen extends ConsumerStatefulWidget {
  const QuestionManagementScreen({super.key});

  @override
  ConsumerState<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends ConsumerState<QuestionManagementScreen> {
  final QuestionImportService _importService = QuestionImportService();
  final QuestionDatabase _questionDb = QuestionDatabase();
  
  bool _isImporting = false;
  Map<String, dynamic>? _importResults;
  Map<String, dynamic>? _dbStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _importService.getImportStats();
    if (mounted) {
      setState(() {
        _dbStats = stats;
      });
    }
  }

  Future<void> _importQuestions() async {
    setState(() {
      _isImporting = true;
      _importResults = null;
    });

    try {
      final results = await _importService.importAllQuestions();
      if (mounted) {
        setState(() {
          _importResults = results;
          _isImporting = false;
        });
        await _loadStats();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${results['total_imported']} questions successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllQuestions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Questions'),
        content: const Text('Are you sure you want to delete all questions? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _importService.clearAllQuestions();
        await _loadStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All questions cleared successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear questions: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Database Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database Statistics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_dbStats != null) ...[
                      _buildStatRow('Total Questions', '${_dbStats!['total_questions']}'),
                      _buildStatRow('Subjects', '${_dbStats!['subjects']}'),
                      _buildStatRow('Easy Questions', '${_dbStats!['easy_questions']}'),
                      _buildStatRow('Medium Questions', '${_dbStats!['medium_questions']}'),
                      _buildStatRow('Hard Questions', '${_dbStats!['hard_questions']}'),
                    ] else
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Import Questions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Questions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Download and import questions from multiple educational sources including Open Trivia Database, educational samples, and AP-style questions.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isImporting)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Importing questions...'),
                        ],
                      )
                    else
                      FilledButton.icon(
                        onPressed: _importQuestions,
                        icon: const Icon(Icons.download),
                        label: const Text('Import Questions'),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Import Results Card
            if (_importResults != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Import Results',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Total Imported: ${_importResults!['total_imported']}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'Sources:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      
                      ...(_importResults!['sources'] as Map<String, int>).entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Text('• ${entry.key}: ${entry.value} questions'),
                        ),
                      ),
                      
                      if ((_importResults!['errors'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Errors:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...(_importResults!['errors'] as List<String>).map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Text(
                              '• $error',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Danger Zone Card
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danger Zone',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Permanently delete all questions from the database. This action cannot be undone.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    OutlinedButton.icon(
                      onPressed: _clearAllQuestions,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Clear All Questions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[700]!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Information Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Questions are imported from multiple educational sources\n'
                      '• Open Trivia Database provides general knowledge questions\n'
                      '• Educational samples include curriculum-aligned content\n'
                      '• AP-style questions are designed for advanced placement courses\n'
                      '• All questions include explanations and difficulty levels\n'
                      '• Questions are stored locally in SQLite database',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
