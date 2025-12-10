import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/class_note_provider.dart';
import '../providers/subject_provider.dart';

/// Screen for adding a new class note
class AddClassNoteScreen extends ConsumerStatefulWidget {
  const AddClassNoteScreen({super.key});

  @override
  ConsumerState<AddClassNoteScreen> createState() => _AddClassNoteScreenState();
}

class _AddClassNoteScreenState extends ConsumerState<AddClassNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String? _selectedSubject;
  String? _selectedFileName;
  int? _selectedFileSize;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'doc', 'docx', 'md'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();
        
        // Read file content (only for text files)
        if (fileName.endsWith('.txt') || fileName.endsWith('.md')) {
          final content = await file.readAsString();
          setState(() {
            _contentController.text = content;
            _selectedFileName = fileName;
            _selectedFileSize = fileSize;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File loaded: $fileName')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Currently only .txt and .md files can be read automatically. Please paste your notes manually.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
          setState(() {
            _selectedFileName = fileName;
            _selectedFileSize = fileSize;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading file: $e')),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final noteId = await ref.read(classNotesProvider.notifier).createNote(
        subjectName: _selectedSubject!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        fileName: _selectedFileName,
        fileSize: _selectedFileSize,
      );

      if (noteId != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Class note added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to add class note'),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Class Note'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload your class notes to generate customized quiz questions using AI',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subject selection
            subjectsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error loading subjects: $e'),
              data: (subjects) {
                final activeSubjects = subjects.where((s) => s.isActive).toList();
                
                return DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.subject),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select a subject'),
                  items: activeSubjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.name,
                      child: Text(subject.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubject = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a subject';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Chapter 5: Thermodynamics',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // File picker button
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _selectedFileName ?? 'Upload File (Optional)',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            if (_selectedFileName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_selectedFileName (${_formatFileSize(_selectedFileSize)})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedFileName = null;
                        _selectedFileSize = null;
                      });
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Content field
            TextFormField(
              controller: _contentController,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Paste or type your class notes here...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the note content';
                }
                if (value.trim().length < 50) {
                  return 'Please enter at least 50 characters for better question generation';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Character count: ${_contentController.text.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveNote,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
