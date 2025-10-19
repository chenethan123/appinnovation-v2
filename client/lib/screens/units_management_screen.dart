import 'package:flutter/material.dart';

class UnitsManagementScreen extends StatelessWidget {
  final int subjectId;
  final String subjectName;
  
  const UnitsManagementScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Units: $subjectName')),
      body: const Center(
        child: Text('Units management coming soon!'),
      ),
    );
  }
}
