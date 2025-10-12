import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../models/course.dart';
import '../providers/subject_provider.dart';
import '../providers/course_provider.dart';

class SubjectSearchScreen extends ConsumerStatefulWidget {
  const SubjectSearchScreen({super.key});

  @override
  ConsumerState<SubjectSearchScreen> createState() => _SubjectSearchScreenState();
}

class _SubjectSearchScreenState extends ConsumerState<SubjectSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Course> _filteredCourses = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String _selectedCourseType = 'All'; // All, AP, College, High School, IB

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final service = ref.read(courseServiceProvider);
    final courses = await service.getAllCourses();
    if (mounted) {
      setState(() {
        _filteredCourses = courses;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchChanged() async {
    final service = ref.read(courseServiceProvider);
    final query = _searchController.text;
    
    List<Course> results;
    if (query.isEmpty && _selectedCategory == 'All' && _selectedCourseType == 'All') {
      results = await service.getAllCourses();
    } else if (query.isEmpty) {
      results = await service.getAllCourses();
      // Apply category filter
      if (_selectedCategory != 'All') {
        results = results.where((c) => c.category == _selectedCategory).toList();
      }
      // Apply course type filter
      results = _applyCourseTypeFilter(results);
    } else {
      results = await service.searchCourses(query);
      // Apply category filter
      if (_selectedCategory != 'All') {
        results = results.where((c) => c.category == _selectedCategory).toList();
      }
      // Apply course type filter
      results = _applyCourseTypeFilter(results);
    }
    
    if (mounted) {
      setState(() {
        _filteredCourses = results;
      });
    }
  }

  Future<void> _onCategoryChanged(String category) async {
    setState(() {
      _selectedCategory = category;
    });
    await _onSearchChanged();
  }

  List<Course> _applyCourseTypeFilter(List<Course> courses) {
    if (_selectedCourseType == 'All') return courses;
    
    return courses.where((course) {
      switch (_selectedCourseType) {
        case 'AP':
          return course.courseId.startsWith('AP-');
        case 'College':
          // College courses typically have format like "MATH 101", "ENG 102" etc.
          return !course.courseId.startsWith('AP-') && 
                 !course.courseId.startsWith('IB-') &&
                 RegExp(r'^[A-Z]+ \d+').hasMatch(course.courseId);
        case 'High School':
          // High school courses don't have AP- prefix and aren't college format
          return !course.courseId.startsWith('AP-') && 
                 !course.courseId.startsWith('IB-') &&
                 !RegExp(r'^[A-Z]+ \d+').hasMatch(course.courseId);
        case 'IB':
          return course.courseId.startsWith('IB-');
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _onCourseTypeChanged(String type) async {
    setState(() {
      _selectedCourseType = type;
    });
    await _onSearchChanged();
  }

  Widget _buildCourseTypeChip(String type, IconData icon) {
    final isSelected = _selectedCourseType == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(type),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _onCourseTypeChanged(type),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Future<void> _addSubject(Course course) async {
    try {
      // Generate a color based on category
      final categoryColors = {
        'STEM': '#2196F3',          // Blue
        'Humanities': '#9C27B0',    // Purple
        'Social Science': '#FF9800', // Orange
        'Languages': '#4CAF50',     // Green
        'Business': '#00BCD4',      // Teal
      };
      
      final subject = Subject(
        name: course.subjectName,
        description: course.description.isNotEmpty 
            ? course.description 
            : '${course.courseId} - ${course.subjectName}',
        color: categoryColors[course.category] ?? '#607D8B', // Default grey
        isActive: true,
        totalQuestions: 0,
        correctAnswers: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(subjectProvider.notifier).addSubject(subject);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${course.courseId} - ${course.subjectName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding subject: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subject'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses (e.g., MATH 101, Calculus)...',
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
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
          ),

          // Category filter
          categoriesAsync.when(
            data: (categories) {
              final allCategories = ['All', ...categories];
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allCategories.length,
                  itemBuilder: (context, index) {
                    final category = allCategories[index];
                    final isSelected = category == _selectedCategory;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _onCategoryChanged(category);
                          }
                        },
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 50),
            error: (_, __) => const SizedBox(height: 50),
          ),

          // Course Type Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Type:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCourseTypeChip('All', Icons.apps),
                      const SizedBox(width: 8),
                      _buildCourseTypeChip('AP', Icons.school),
                      const SizedBox(width: 8),
                      _buildCourseTypeChip('College', Icons.account_balance),
                      const SizedBox(width: 8),
                      _buildCourseTypeChip('High School', Icons.local_library),
                      const SizedBox(width: 8),
                      _buildCourseTypeChip('IB', Icons.public),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                    ? Center(
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
                              'No courses found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or category filter',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          
                          // Get category color
                          final categoryColors = {
                            'STEM': Colors.blue,
                            'Humanities': Colors.purple,
                            'Social Science': Colors.orange,
                            'Languages': Colors.green,
                            'Business': Colors.teal,
                          };
                          final categoryColor = categoryColors[course.category] ?? Colors.grey;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: categoryColor,
                                child: Text(
                                  course.courseId.split(' ').map((word) => word[0]).take(2).join(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${course.courseId} - ${course.subjectName}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (course.description.isNotEmpty)
                                    Text(
                                      course.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: categoryColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      course.category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: categoryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: FilledButton(
                                onPressed: () => _addSubject(course),
                                child: const Text('Add'),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
