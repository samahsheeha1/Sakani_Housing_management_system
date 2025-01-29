import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/student_model.dart';

class StudentService {
  final String baseUrl = '${getBaseUrl()}/api/users';
  final String baseUrl2 = '${getBaseUrl()}/api/student';

  Future<List<Student>> getAllStudents() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List students = json.decode(response.body);
      return students.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  Future<void> addStudent(Student student) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(student.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add student');
    }
  }

  Future<void> editStudent(String id, Student student) async {
    final url = Uri.parse('$baseUrl/$id');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(student.toJson());

    try {
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Success
        print('Student updated successfully');
      } else {
        // Handle errors
        throw Exception('Failed to update student: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating student: $e');
    }
  }

  Future<void> deleteStudent(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl2/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete student');
    }
  }

  Future<void> assignRoommate(String studentId, String roommateId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assign-roommate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'studentId': studentId, 'roommateId': roommateId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to assign roommate');
    }
  }
}
