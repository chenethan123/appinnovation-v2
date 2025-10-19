import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../widgets/subject_card.dart';
import 'mcq_loading_screen.dart';

class SubjectSearchScreen extends ConsumerStatefulWidget {
  const SubjectSearchScreen({super.key});

  @override
  ConsumerState<SubjectSearchScreen> createState() => _SubjectSearchScreenState();
}

class _SubjectSearchScreenState extends ConsumerState<SubjectSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Subject> _filteredSubjects = [];
  String _sortBy = 'name'; // name, accuracy, questions

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final subjectsAsync = ref.read(subjectProvider);
    subjectsAsync.whenData((subjects) {
      final query = _searchController.text.toLowerCase();
      
      if (query.isEmpty) {
        _filterAndSort(subjects);
        return;
      }
      
      final filtered = subjects.where((subject) {
        return subject.name.toLowerCase().contains(query) ||
               subject.description.toLowerCase().contains(query);
      }).toList();
      
      _filterAndSort(filtered);
    });
  }

  void _filterAndSort(List<Subject> subjects) {
    var sorted = List<Subject>.from(subjects);
    
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'accuracy':
        sorted.sort((a, b) => b.accuracy.compareTo(a.accuracy));
        break;
      case 'questions':
        sorted.sort((a, b) => b.totalQuestions.compareTo(a.totalQuestions));
        break;
    }
    
    if (!mounted) return;
    setState(() {
      _filteredSubjects = sorted;
    });
  }

  void _onSortChanged(String? newSort) {
    if (newSort == null) return;
    setState(() {
      _sortBy = newSort;
    });
    _onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Subjects'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(subjectProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Sort dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Sort by:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name (A-Z)')),
                      DropdownMenuItem(value: 'accuracy', child: Text('Accuracy (High to Low)')),
                      DropdownMenuItem(value: 'questions', child: Text('Questions (Most to Least)')),
                    ],
                    onChanged: _onSortChanged,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: subjectsAsync.when(
              data: (subjects) {
                // Initialize filtered subjects if empty
                if (_filteredSubjects.isEmpty && _searchController.text.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _filterAndSort(subjects);
                  });
                }
                
                if (_filteredSubjects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No subjects found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = _filteredSubjects[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SubjectCard(
                        subject: subject,
                        onTap: () {
                          // Start AI quiz for this subject
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
                );
              },
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
    );
  }
}
