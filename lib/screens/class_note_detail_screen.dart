import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_note.dart';
import '../providers/class_note_provider.dart';
import '../services/cloud_data_service.dart';
import '../models/question.dart';

/// Screen for viewing class note details and generating questions
class ClassNoteDetailScreen extends ConsumerStatefulWidget {
  final ClassNote note;

  const ClassNoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<ClassNoteDetailScreen> createState() => _ClassNoteDetailScreenState();
}

class _ClassNoteDetailScreenState extends ConsumerState<ClassNoteDetailScreen> {
  bool _isGenerating = false;
  int _questionCount = 5;
  String _difficulty = 'medium';

  Future<void> _generateQuestions() async {
    setState(() => _isGenerating = true);

    try {
      final questions = await ref.read(classNotesProvider.notifier).generateQuestions(
        noteId: widget.note.id!,
        noteContent: widget.note.content,
        subjectName: widget.note.subjectName,
        questionCount: _questionCount,
        difficulty: _difficulty,
      );

      if (questions != null && questions.isNotEmpty && mounted) {
        // Save questions to database
        await _saveQuestionsToDatabase(questions);

        // Show success
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Success!'),
                ],
              ),
              content: Text(
                'Generated ${questions.length} questions from your class notes!\n\n'
                'You can now find these questions in your quiz for ${widget.note.subjectName}.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to generate questions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _saveQuestionsToDatabase(List<Map<String, dynamic>> questions) async {
    // Get subject ID first - we'll need to fetch it
    final cloudService = CloudDataService();
    final subjects = await cloudService.getAllSubjects();
    final subject = subjects.firstWhere(
      (s) => s.name == widget.note.subjectName,
      orElse: () => throw Exception('Subject not found'),
    );

    // Save each question
    for (var questionData in questions) {
      final question = Question(
        subjectId: subject.id!,
        subjectName: subject.name,
        questionText: questionData['question'] ?? '',
        options: List<String>.from(questionData['options'] ?? []),
        correctAnswer: questionData['correct_answer'] ?? '',
        explanation: questionData['explanation'] ?? '',
        difficulty: questionData['difficulty'] ?? _difficulty,
        createdAt: DateTime.now(),
        isFromAI: true,
        classNoteId: widget.note.id,
        sourceType: 'class_notes',
      );

      await cloudService.createQuestion(question);
    }
  }

  void _showGenerateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Questions'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How many questions do you want to generate?'),
                const SizedBox(height: 16),
                
                // Question count slider
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _questionCount.toDouble(),
                        min: 3,
                        max: 10,
                        divisions: 7,
                        label: _questionCount.toString(),
                        onChanged: (value) {
                          setDialogState(() => _questionCount = value.toInt());
                        },
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        _questionCount.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Difficulty selection
                const Text('Difficulty:'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'easy', label: Text('Easy')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'hard', label: Text('Hard')),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() => _difficulty = newSelection.first);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateQuestions();
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
            tooltip: 'Delete note',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.note.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.note.subjectName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(widget.note.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.quiz,
                        label: '${widget.note.questionCount} Questions Generated',
                        color: Colors.green,
                      ),
                      if (widget.note.fileName != null) ...[
                        const SizedBox(width: 8),
                        _buildStatChip(
                          icon: Icons.attach_file,
                          label: widget.note.fileSizeFormatted,
                          color: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content
                  const Text(
                    'Content',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.note.content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Generate questions button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _showGenerateDialog,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _isGenerating
                            ? 'Generating Questions...'
                            : 'Generate Quiz Questions',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text(
          'Are you sure you want to delete "${widget.note.title}"?\n\n'
          'This will not delete the questions already generated from this note.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(classNotesProvider.notifier).deleteNote(widget.note.id!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
