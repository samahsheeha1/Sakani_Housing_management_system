import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For image loading
import '../config.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';
import 'add_edit_student.dart';
import 'assign_roommate.dart';
import 'student_detail.dart';

class ManageStudents extends StatefulWidget {
  @override
  _ManageStudentsState createState() => _ManageStudentsState();
}

class _ManageStudentsState extends State<ManageStudents> {
  final StudentService _studentService = StudentService();
  late Future<List<Student>> _students;
  List<Student> _filteredStudents = []; // List to display filtered students
  final TextEditingController _searchController = TextEditingController();
  Student? _selectedStudent;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // Load students from the backend
  void _loadStudents() async {
    setState(() {
      _students = _studentService.getAllStudents();
    });
  }

  // Delete a student
  void _showDeleteConfirmation(Student student) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _studentService.deleteStudent(student.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${student.fullName} deleted successfully'),
          backgroundColor: Colors.orange,
        ));
        setState(() {
          _filteredStudents
              .removeWhere((s) => s.id == student.id); // Remove from the list
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting student: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Search functionality
  void _onSearch(String query) async {
    final students = await _students;
    setState(() {
      _filteredStudents = students.where((student) {
        return student.fullName.toLowerCase().contains(query.toLowerCase()) ||
            student.email.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Select a student (for web layout)
  void _onStudentSelected(Student student) {
    setState(() {
      _selectedStudent = student;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Students'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Student>>(
        future: _students,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No students found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          } else {
            final students = snapshot.data!;
            if (_searchController.text.isEmpty) {
              _filteredStudents =
                  students; // Show all students if no search query
            }
            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: isWeb ? 600 : double.infinity, // Limit width for web
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by Name or Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search, color: Colors.orange),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.orange),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearch(
                                      ''); // Clear search and show all students
                                },
                              )
                            : null,
                      ),
                      onChanged: _onSearch, // Filter students as the user types
                    ),
                  ),
                ),
                // Student List
                Expanded(
                  child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditStudent(),
            ),
          ).then((updatedStudent) {
            if (updatedStudent != null) {
              setState(() {
                _filteredStudents.add(updatedStudent); // Add new student
              });
              _loadStudents(); // Reload the student list
            }
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Web Layout
  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student List (Left Side)
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _filteredStudents.length,
            itemBuilder: (context, index) {
              final student = _filteredStudents[index];
              return _buildStudentCard(student);
            },
          ),
        ),
        // Student Details (Right Side)
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: _selectedStudent == null
                ? Center(
                    child: Text(
                      'Select a student to view details',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : StudentDetail(student: _selectedStudent!),
          ),
        ),
      ],
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  // Student Card Widget
  Widget _buildStudentCard(Student student) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          if (isWeb) {
            _onStudentSelected(student);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Student Details'),
                    backgroundColor: Colors.orange,
                  ),
                  body: StudentDetail(student: student),
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Use CachedNetworkImage for faster image loading
              CachedNetworkImage(
                imageUrl: '${getBaseUrl()}/${student.photo}',
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  radius: 30,
                  backgroundImage: imageProvider,
                ),
                placeholder: (context, url) => CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.orange),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditStudent(student: student),
                    ),
                  ).then((updatedStudent) {
                    if (updatedStudent != null) {
                      setState(() {
                        final index = _filteredStudents
                            .indexWhere((s) => s.id == updatedStudent.id);
                        if (index != -1) {
                          _filteredStudents[index] =
                              updatedStudent; // Update existing student
                        }
                      });
                      _loadStudents(); // Reload the student list
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmation(student);
                },
              ),
              IconButton(
                icon: Icon(Icons.group_add, color: Colors.green),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignRoommate(student: student),
                    ),
                  ).then((_) => _loadStudents()); // Reload the student list
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
