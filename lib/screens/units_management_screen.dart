import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/unit.dart';
import '../database/database_helper.dart';
import '../services/course_units_service.dart';
import 'package:intl/intl.dart';

class UnitsManagementScreen extends StatefulWidget {
  final Subject subject;

  const UnitsManagementScreen({
    Key? key,
    required this.subject,
  }) : super(key: key);

  @override
  State<UnitsManagementScreen> createState() => _UnitsManagementScreenState();
}

class _UnitsManagementScreenState extends State<UnitsManagementScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final CourseUnitsService _courseUnitsService = CourseUnitsService();
  List<Unit> _units = [];
  bool _isLoading = true;
  bool _hasDefaultUnits = false;

  @override
  void initState() {
    super.initState();
    _checkDefaultUnits();
    _loadUnits();
  }

  Future<void> _checkDefaultUnits() async {
    await _courseUnitsService.loadCourseUnits();
    if (mounted) {
      setState(() {
        _hasDefaultUnits = _courseUnitsService.hasUnitsFor(widget.subject.name);
      });
    }
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final units = await _db.getUnitsForSubject(widget.subject.id!);
      if (mounted) {
        setState(() {
          _units = units;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading units: $e')),
        );
      }
    }
  }

  Future<void> _addUnit() async {
    await showDialog(
      context: context,
      builder: (context) => _UnitDialog(
        subjectId: widget.subject.id!,
        orderIndex: _units.length + 1,
        onSave: _loadUnits,
      ),
    );
  }

  Future<void> _autoPopulateUnits() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-populate Units'),
        content: Text(
          'This will automatically add the official units for ${widget.subject.name}. '
          'You can edit or delete them later.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Auto-populate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _courseUnitsService.autoPopulateUnits(
        widget.subject.id!,
        widget.subject.name,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Units auto-populated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadUnits();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Units already exist or could not be loaded'),
            ),
          );
        }
      }
    }
  }

  Future<void> _editUnit(Unit unit) async {
    await showDialog(
      context: context,
      builder: (context) => _UnitDialog(
        subjectId: widget.subject.id!,
        orderIndex: unit.orderIndex,
        unit: unit,
        onSave: _loadUnits,
      ),
    );
  }

  Future<void> _deleteUnit(Unit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to delete "${unit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteUnit(unit.id!);
      await _loadUnits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit deleted')),
        );
      }
    }
  }

  Future<void> _setCurrentUnit(Unit unit) async {
    await _db.setCurrentUnit(widget.subject.id!, unit.id!);
    await _loadUnits();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${unit.name} set as current unit')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject.name} Units'),
        actions: [
          if (_hasDefaultUnits && _units.isEmpty)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Auto-populate units',
              onPressed: _autoPopulateUnits,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _units.isEmpty
              ? _buildEmptyState()
              : _buildUnitsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUnit,
        icon: const Icon(Icons.add),
        label: const Text('Add Unit'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No units yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add units to organize your study topics and schedule',
              textAlign: TextAlign.center,
            ),
          ),
          if (_hasDefaultUnits) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _autoPopulateUnits,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Auto-populate Course Units'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Official units for ${widget.subject.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unit = _units[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: unit.isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              child: Text(
                unit.orderIndex.toString(),
                style: TextStyle(
                  color: unit.isCurrent
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(unit.name)),
                if (unit.isCurrent)
                  Chip(
                    label: const Text('Current', style: TextStyle(fontSize: 11)),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unit.description != null) Text(unit.description!),
                if (unit.startDate != null && unit.endDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat.MMMd().format(unit.startDate!)} - ${DateFormat.MMMd().format(unit.endDate!)}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                      ),
                      if (unit.isActive) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 2),
                        const Text('Active', style: TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ],
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editUnit(unit);
                    break;
                  case 'set_current':
                    _setCurrentUnit(unit);
                    break;
                  case 'delete':
                    _deleteUnit(unit);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (!unit.isCurrent)
                  const PopupMenuItem(value: 'set_current', child: Text('Set as Current')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UnitDialog extends StatefulWidget {
  final int subjectId;
  final int orderIndex;
  final Unit? unit;
  final VoidCallback onSave;

  const _UnitDialog({
    required this.subjectId,
    required this.orderIndex,
    this.unit,
    required this.onSave,
  });

  @override
  State<_UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<_UnitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.unit?.description ?? '');
    _startDate = widget.unit?.startDate;
    _endDate = widget.unit?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final db = DatabaseHelper();
      final unit = Unit(
        id: widget.unit?.id,
        subjectId: widget.subjectId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        orderIndex: widget.orderIndex,
        startDate: _startDate,
        endDate: _endDate,
        isCurrent: widget.unit?.isCurrent ?? false,
      );

      if (widget.unit == null) {
        await db.insertUnit(unit);
      } else {
        await db.updateUnit(unit);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.unit == null ? 'Add Unit' : 'Edit Unit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Unit Name',
                  hintText: 'e.g., Unit 1: Limits',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a unit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'What topics are covered in this unit?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Schedule (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectStartDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate == null
                          ? 'Start Date'
                          : DateFormat.yMMMd().format(_startDate!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectEndDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate == null
                          ? 'End Date'
                          : DateFormat.yMMMd().format(_endDate!)),
                    ),
                  ),
                ],
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_endDate!.difference(_startDate!).inDays} days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
