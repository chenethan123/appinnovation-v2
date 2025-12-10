import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_note.dart';
import '../providers/class_note_provider.dart';
import '../providers/subject_provider.dart';
import 'add_class_note_screen.dart';
import 'class_note_detail_screen.dart';

/// Screen for managing user-uploaded class notes
class ClassNotesScreen extends ConsumerWidget {
  const ClassNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classNotesAsync = ref.watch(classNotesProvider);
    final subjectsAsync = ref.watch(subjectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Class Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(classNotesProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: classNotesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading notes: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(classNotesProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No class notes yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload your class notes to generate\ncustomized quiz questions!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddNote(context, subjectsAsync),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Note'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          // Group notes by subject
          final notesBySubject = <String, List<ClassNote>>{};
          for (var note in notes) {
            notesBySubject.putIfAbsent(note.subjectName, () => []).add(note);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              _buildSummaryCard(notes),
              const SizedBox(height: 24),
              
              // Notes grouped by subject
              ...notesBySubject.entries.map((entry) {
                return _buildSubjectSection(
                  context,
                  entry.key,
                  entry.value,
                );
              }).toList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddNote(context, subjectsAsync),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }

  Widget _buildSummaryCard(List<ClassNote> notes) {
    final totalQuestions = notes.fold<int>(0, (sum, note) => sum + note.questionCount);
    final subjectCount = notes.map((note) => note.subjectName).toSet().length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn(
              icon: Icons.note,
              label: 'Notes',
              value: notes.length.toString(),
              color: Colors.blue,
            ),
            _buildStatColumn(
              icon: Icons.subject,
              label: 'Subjects',
              value: subjectCount.toString(),
              color: Colors.green,
            ),
            _buildStatColumn(
              icon: Icons.quiz,
              label: 'Questions',
              value: totalQuestions.toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSection(
    BuildContext context,
    String subjectName,
    List<ClassNote> notes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.folder, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                subjectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...notes.map((note) => _buildNoteCard(context, note)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, ClassNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassNoteDetailScreen(note: note),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (note.questionCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.quiz, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${note.questionCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.contentPreview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (note.fileName != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.insert_drive_file, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      note.fileSizeFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _navigateToAddNote(BuildContext context, AsyncValue subjectsAsync) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddClassNoteScreen(),
      ),
    );
  }
}
