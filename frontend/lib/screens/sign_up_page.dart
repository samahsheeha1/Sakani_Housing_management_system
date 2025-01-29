import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For File
import 'dart:typed_data'; // For Uint8List (web)
import 'package:image_picker/image_picker.dart'; // For image picker
import 'package:flutter/foundation.dart'; // For kIsWeb

import '../config.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  final String role;

  const SignUpPage({super.key, required this.role});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final List<String> interests = [];
  final List<String> availableInterests = [
    'Sports',
    'Music',
    'Art',
    'Reading',
    'Gaming',
    'Traveling',
    'Cooking',
    'Movies',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _notificationKey = GlobalKey();

  String? errorMessage;
  File? _image; // To store the selected image for mobile
  Uint8List? _webImage; // To store the selected image for web
  final ImagePicker _picker = ImagePicker(); // For image picking

  void _showNotification(String message, IconData icon, bool isError) {
    final overlay = Overlay.of(context);
    final RenderBox renderBox =
        _notificationKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.width > 600 ? position.dy - 60 : 20,
        left: MediaQuery.of(context).size.width > 600 ? position.dx : 20,
        right: MediaQuery.of(context).size.width > 600 ? null : 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width > 600
                ? renderBox.size.width
                : null,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, read the image as bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _image = null; // Clear the mobile File object
        });
      } else {
        // For mobile, use the File object
        setState(() {
          _image = File(pickedFile.path);
          _webImage = null; // Clear the web Uint8List
        });
      }

      // Debugging: Print the image path or bytes
      print('Image Path: ${_image?.path}');
      print('Image Bytes: $_webImage');
    }
  }

  Future<void> _signUpUser() async {
    setState(() {
      errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      _showNotification('Passwords do not match', Icons.error, true);
      return;
    }

    // Debugging: Print selected interests
    print('Selected Interests: $interests');
    if (widget.role == 'Student' && interests.isEmpty) {
      _showNotification(
          'Please select at least one interest', Icons.error, true);
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${getBaseUrl()}/api/users/register'),
      );

      // Add fields to the request
      request.fields['fullName'] = fullNameController.text;
      request.fields['email'] = emailController.text;
      request.fields['phone'] = phoneNumberController.text;
      request.fields['address'] = addressController.text;
      request.fields['age'] = ageController.text;
      request.fields['role'] = widget.role;
      request.fields['password'] = passwordController.text;

      // Add interests field
      if (widget.role == 'Student') {
        request.fields['interests'] = jsonEncode(interests);
        print(
            'Interests being sent: ${request.fields['interests']}'); // Debug log
      }

      // Add image file if selected
      if (_image != null || _webImage != null) {
        if (kIsWeb) {
          // Handle file upload for web
          request.files.add(
            http.MultipartFile.fromBytes(
              'photo', // Field name for the file
              _webImage!, // File bytes
              filename: 'profile.jpg', // Provide a filename
            ),
          );
          print('Image being sent as bytes'); // Debug log
        } else {
          // Handle file upload for mobile
          request.files.add(
            await http.MultipartFile.fromPath(
              'photo', // Field name for the file
              _image!.path, // File path
            ),
          );
          print('Image being sent from path: ${_image!.path}'); // Debug log
        }
      }

      // Debug log: Print all fields being sent
      print('Request fields: ${request.fields}');

      var response = await request.send();

      if (response.statusCode == 201) {
        _showNotification(
            'Account created successfully!', Icons.check_circle, false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        final data = jsonDecode(await response.stream.bytesToString());
        _showNotification(
            data['message'] ?? 'Error occurred', Icons.error, true);
      }
    } catch (e) {
      _showNotification('Something went wrong.', Icons.error, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.orange.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            if (isWeb)
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/sign_up_logo.png',
                        width: screenWidth * 0.4,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Welcome to Sakni!",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Join us and simplify your experience.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: isWeb ? 450 : double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 30.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              key: _notificationKey,
                              child: Text(
                                'Sign Up as ${widget.role}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                            if (errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign:
                                      MediaQuery.of(context).size.width > 600
                                          ? TextAlign.center
                                          : TextAlign.start,
                                ),
                              ),
                            const SizedBox(height: 20),
                            Center(
                              child: Column(
                                children: [
                                  if (_image != null || _webImage != null)
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: kIsWeb
                                              ? MemoryImage(
                                                  _webImage!) // Use MemoryImage for web
                                              : FileImage(_image!)
                                                  as ImageProvider, // Use FileImage for mobile
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[200],
                                      ),
                                      child: Icon(Icons.camera_alt,
                                          color: Colors.grey[800]),
                                    ),
                                  TextButton(
                                    onPressed: _pickImage,
                                    child: Text(
                                      _image == null && _webImage == null
                                          ? 'Upload Photo'
                                          : 'Change Photo',
                                      style: TextStyle(
                                          color: Colors.orange.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              'Full Name',
                              fullNameController,
                              Icons.person,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              'Email',
                              emailController,
                              Icons.email,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  _showNotification('Please enter your email',
                                      Icons.error, true);
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
                                    .hasMatch(value)) {
                                  _showNotification(
                                      'Please enter a valid email',
                                      Icons.error,
                                      true);
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              'Phone Number',
                              phoneNumberController,
                              Icons.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  _showNotification(
                                      'Please enter your phone number',
                                      Icons.error,
                                      true);
                                  return 'Please enter your phone number';
                                }
                                if (!RegExp(r"^\d+").hasMatch(value)) {
                                  _showNotification(
                                      'Phone number must be digits only',
                                      Icons.error,
                                      true);
                                  return 'Phone number must be digits only';
                                }
                                if (value.length < 8 || value.length > 15) {
                                  _showNotification(
                                      'Phone number must be between 8 and 15 digits',
                                      Icons.error,
                                      true);
                                  return 'Phone number must be between 8 and 15 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              'Address',
                              addressController,
                              Icons.location_on,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              'Age',
                              ageController,
                              Icons.cake,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  _showNotification('Please enter your age',
                                      Icons.error, true);
                                  return 'Please enter your age';
                                }
                                final age = int.tryParse(value);
                                if (age == null || age < 18 || age > 120) {
                                  _showNotification(
                                      'Age must be between 18 and 120',
                                      Icons.error,
                                      true);
                                  return 'Age must be between 18 and 120';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            if (widget.role == 'Student')
                              _buildMultiSelectDropdown(),
                            const SizedBox(height: 15),
                            _buildTextField(
                              'Password',
                              passwordController,
                              Icons.lock,
                              isPassword: true,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              'Confirm Password',
                              confirmPasswordController,
                              Icons.lock,
                              isPassword: true,
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _signUpUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => LoginPage()),
                                      );
                                    },
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildMultiSelectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8.0,
          children: availableInterests.map((interest) {
            final isSelected = interests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              selectedColor: Colors.orange.shade300,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    interests.add(interest);
                  } else {
                    interests.remove(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
