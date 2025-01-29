import 'package:flutter/material.dart';
import 'package:sakani/config.dart';

import '../../models/student_model.dart';

class StudentTable extends StatelessWidget {
  final List<Student> students;
  final bool isMobile;
  final Function(Student) onEdit;
  final Function(Student) onDelete;
  final Function(Student) onAssign;
  final Function(Student) onSelect; // Add this callback

  StudentTable({
    required this.students,
    required this.isMobile,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
    required this.onSelect, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Photo')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Actions')),
        ],
        rows: students.map((student) {
          return DataRow(
            cells: [
              DataCell(
                CircleAvatar(
                  radius: 25,
                  backgroundImage:
                      NetworkImage('${getBaseUrl()}/${student.photo}'),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle image loading errors
                  },
                  child: student.photo.isEmpty
                      ? Icon(Icons.person) // Placeholder icon
                      : null,
                ),
                onTap: () => onSelect(student), // Trigger onSelect callback
              ),
              DataCell(
                Text(student.fullName),
                onTap: () => onSelect(student), // Trigger onSelect callback
              ),
              DataCell(
                Text(student.email),
                onTap: () => onSelect(student), // Trigger onSelect callback
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => onEdit(student),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => onDelete(student),
                    ),
                    IconButton(
                      icon: Icon(Icons.group_add),
                      onPressed: () => onAssign(student),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
