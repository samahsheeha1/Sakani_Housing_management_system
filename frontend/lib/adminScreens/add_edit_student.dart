import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // For web check
import 'package:image_picker/image_picker.dart'; // For mobile
import 'package:file_picker/file_picker.dart'; // For web
import 'dart:io'; // For mobile (not available on web)
import 'dart:typed_data'; // For web image handling
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';

class AddEditStudent extends StatefulWidget {
  final Student? student; // Null if adding a new student

  const AddEditStudent({Key? key, this.student}) : super(key: key);

  @override
  _AddEditStudentState createState() => _AddEditStudentState();
}

class _AddEditStudentState extends State<AddEditStudent> {
  final _formKey = GlobalKey<FormState>();
  final _studentService = StudentService();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _ageController;

  File? _imageFile; // To store the selected image file (for mobile)
  Uint8List? _imageBytes; // To store the selected image bytes (for web)
  String? _imageUrl; // To store the URL of the uploaded image

  // List of interests
  final List<String> _interests = [
    'Sports',
    'Music',
    'Art',
    'Reading',
    'Gaming',
    'Traveling',
    'Cooking',
    'Movies',
  ];

  // Selected interests
  final List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.student?.fullName ?? '');
    _emailController = TextEditingController(text: widget.student?.email ?? '');
    _passwordController =
        TextEditingController(text: widget.student?.password ?? '');
    _phoneController = TextEditingController(text: widget.student?.phone ?? '');
    _addressController =
        TextEditingController(text: widget.student?.address ?? '');
    _ageController =
        TextEditingController(text: widget.student?.age.toString() ?? '');
    _imageUrl = widget.student?.photo != null
        ? '${getBaseUrl()}/${widget.student!.photo}' // Use full URL for the image
        : null; // Initialize with existing photo URL
    _selectedInterests.addAll(
        widget.student?.interests ?? []); // Initialize with existing interests
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Use file_picker for web
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _imageBytes = result.files.single.bytes; // Get the file bytes
          _imageFile = null; // Clear the file object for web
          _imageUrl = null; // Clear the URL when a new image is picked
        });
      }
    } else {
      // Use image_picker for mobile
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageBytes = null; // Clear the bytes for mobile
          _imageUrl = null; // Clear the URL when a new image is picked
        });
      }
    }
  }

  // Function to upload the image to the backend
  Future<void> _uploadImage() async {
    if (_imageFile == null && _imageBytes == null) return;

    final uri = Uri.parse('${getBaseUrl()}/api/upload');
    final request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      // For web, use the bytes directly
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          _imageBytes!,
          filename: 'uploaded_image.png',
        ),
      );
    } else {
      // For mobile, use the file path
      request.files.add(
        await http.MultipartFile.fromPath('images', _imageFile!.path),
      );
    }

    try {
      final response = await request.send();
      if (response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final imagePaths = json.decode(responseData)['imagePaths'] as List;
        setState(() {
          _imageUrl =
              '${getBaseUrl()}/${imagePaths.first}'; // Use full URL for the uploaded image
        });
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      // Upload the image if a new one is selected
      if (_imageFile != null || _imageBytes != null) {
        await _uploadImage();
      }

      final student = Student(
        id: widget.student?.id ?? DateTime.now().toString(),
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        interests: _selectedInterests, // Use the selected interests
        photo: _imageUrl != null
            ? _imageUrl!
                .replaceFirst('${getBaseUrl()}/', '') // Save relative path
            : widget.student?.photo ?? '', // Use the new or existing photo URL
        status: widget.student?.status ?? 'Available',
        matchedWith: widget.student?.matchedWith?.isEmpty ?? true
            ? null
            : widget.student?.matchedWith,
        role: 'Student',
        documents: widget.student?.documents ??
            [], // Initialize with existing documents or an empty list
      );
      print('Saving student: ${student.toJson()}');

      try {
        if (widget.student == null) {
          await _studentService.addStudent(student);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          await _studentService.editStudent(student.id, student);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        Navigator.pop(context, student);
      } catch (e) {
        print('Error saving student: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Container(
          width: kIsWeb ? 600 : double.infinity, // Limit width for web
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                // Circular Image Upload Section
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: ClipOval(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: _imageBytes != null
                            ? Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                              ) // For web
                            : _imageFile != null
                                ? Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ) // For mobile
                                : _imageUrl != null
                                    ? Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.camera_alt,
                                        size: 50,
                                        color: Colors.orange,
                                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: Colors.orange),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter full name'
                      : null,
                ),
                const SizedBox(height: 16),
                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, color: Colors.orange),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter email'
                      : null,
                ),
                const SizedBox(height: 16),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: Colors.orange),
                  ),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter password'
                      : null,
                ),
                const SizedBox(height: 16),
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone, color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 16),
                // Address Field
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home, color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 16),
                // Age Field
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.calendar_today, color: Colors.orange),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || int.tryParse(value) == null
                          ? 'Please enter a valid age'
                          : null,
                ),
                const SizedBox(height: 16),
                // Interests Field
                Text(
                  'Interests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: _interests.map((interest) {
                    return FilterChip(
                      label: Text(interest),
                      selected: _selectedInterests.contains(interest),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                      selectedColor: Colors.orange.withOpacity(0.3),
                      checkmarkColor: Colors.orange,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Save Button
                ElevatedButton(
                  onPressed: _saveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
