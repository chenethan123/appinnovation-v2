import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../providers/course_provider.dart';

class CourseAutocomplete extends ConsumerStatefulWidget {
  final Function(Course?) onCourseSelected;
  final String? initialValue;

  const CourseAutocomplete({
    super.key,
    required this.onCourseSelected,
    this.initialValue,
  });

  @override
  ConsumerState<CourseAutocomplete> createState() => _CourseAutocompleteState();
}

class _CourseAutocompleteState extends ConsumerState<CourseAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  List<Course> _suggestions = [];
  bool _showSuggestions = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _loadCourses();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final service = ref.read(courseServiceProvider);
    final courses = await service.getAllCourses();
    if (mounted) {
      setState(() {
        _suggestions = courses;
      });
    }
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      await _loadCourses();
      setState(() {
        _showSuggestions = false;
      });
      return;
    }

    final service = ref.read(courseServiceProvider);
    final results = await service.searchCourses(query);
    
    if (mounted) {
      setState(() {
        _suggestions = results;
        _showSuggestions = true;
      });
    }
  }

  void _onCategoryChanged(String? category) async {
    setState(() {
      _selectedCategory = category;
    });

    if (category == null || category.isEmpty) {
      await _loadCourses();
      return;
    }

    final service = ref.read(courseServiceProvider);
    final results = await service.getCoursesByCategory(category);
    
    if (mounted) {
      setState(() {
        _suggestions = results;
      });
    }
  }

  void _selectCourse(Course course) {
    setState(() {
      _controller.text = '${course.courseId} - ${course.subjectName}';
      _showSuggestions = false;
    });
    widget.onCourseSelected(course);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category filter
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filter by Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                value: _selectedCategory,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  )),
                ],
                onChanged: _onCategoryChanged,
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Search field
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Course ID or Name',
            hintText: 'e.g., MATH 101 or Calculus',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged('');
                      widget.onCourseSelected(null);
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: _onSearchChanged,
          onTap: () {
            setState(() {
              _showSuggestions = _suggestions.isNotEmpty;
            });
          },
        ),

        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final course = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(course.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        course.courseId.split(' ')[0],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(course.category),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  title: Text(
                    course.courseId,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    course.subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(course.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      course.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCategoryColor(course.category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  onTap: () => _selectCourse(course),
                );
              },
            ),
          ),

        // Helper text
        if (_suggestions.isEmpty && _controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No courses found. You can create a custom course.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'STEM':
        return Colors.blue;
      case 'Humanities':
        return Colors.purple;
      case 'Social Science':
        return Colors.orange;
      case 'Languages':
        return Colors.green;
      case 'Business':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
