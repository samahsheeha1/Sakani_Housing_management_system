import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';

class AssignRoommate extends StatefulWidget {
  final Student student;

  const AssignRoommate({Key? key, required this.student}) : super(key: key);

  @override
  _AssignRoommateState createState() => _AssignRoommateState();
}

class _AssignRoommateState extends State<AssignRoommate> {
  final _studentService = StudentService();
  late Future<List<Student>> _students;
  String? _selectedRoommateId;

  @override
  void initState() {
    super.initState();
    _students = _studentService.getAllStudents();
  }

  Future<void> _assignRoommate() async {
    if (_selectedRoommateId != null) {
      try {
        await _studentService.assignRoommate(
            widget.student.id, _selectedRoommateId!);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Roommate assigned successfully')));
        Navigator.pop(context, true); // Return to refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a roommate')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Roommate'),
        centerTitle: true,
        backgroundColor: Colors.orange, // Changed to orange
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FutureBuilder<List<Student>>(
            future: _students,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final students = snapshot.data!;
                final availableStudents = students
                    .where((s) =>
                        s.status == 'Available' && s.id != widget.student.id)
                    .toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_alt,
                      size: 50,
                      color: Colors.orange, // Changed to orange
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Assign a Roommate',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange, // Changed to orange
                      ),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Roommate',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person,
                            color: Colors.orange), // Changed to orange
                      ),
                      items: availableStudents.map((student) {
                        return DropdownMenuItem<String>(
                          value: student.id,
                          child: Text(student.fullName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoommateId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _assignRoommate,
                      child: Text('Assign Roommate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, // Changed to orange
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
