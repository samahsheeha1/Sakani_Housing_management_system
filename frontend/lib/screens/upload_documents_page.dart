import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import 'HomePage.dart';
import 'room_selection_page.dart';

class UploadDocumentsPage extends StatefulWidget {
  final String token;

  const UploadDocumentsPage({super.key, required this.token});

  @override
  State<UploadDocumentsPage> createState() => _UploadDocumentsPageState();
}

class _UploadDocumentsPageState extends State<UploadDocumentsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<dynamic> documents = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    fetchDocuments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchDocuments() async {
    final url = Uri.parse('${getBaseUrl()}/api/documents/list');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      setState(() {
        documents = json.decode(response.body);
      });
    } else {
      print('Error fetching documents: ${response.body}');
    }
  }

  Future<void> uploadDocument(String label) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes;
      final fileName = result.files.single.name;

      final url = Uri.parse('${getBaseUrl()}/api/documents/upload');
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer ${widget.token}'
        ..fields['description'] = label
        ..files.add(http.MultipartFile.fromBytes(
          'document',
          fileBytes!,
          filename: fileName,
          contentType: MediaType.parse(_getMimeType(fileName)),
        ));

      final response = await request.send();

      if (response.statusCode == 201) {
        print('Document uploaded successfully');
        fetchDocuments();
      } else {
        final responseBody = await http.Response.fromStream(response);
        print('Error uploading document: ${response.statusCode}');
        print('Response body: ${responseBody.body}');
      }
    } else {
      print('No file selected or file content is null');
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> deleteDocument(String id) async {
    final url = Uri.parse('${getBaseUrl()}/api/documents/delete/$id');
    try {
      final response = await http.delete(url, headers: {
        'Authorization': 'Bearer ${widget.token}',
      });

      if (response.statusCode == 200) {
        print('Document deleted successfully');
        fetchDocuments();
      } else {
        print('Error deleting document: ${response.body}');
      }
    } catch (e) {
      print('Error during deletion: $e');
    }
  }

  Widget _buildUploadSection(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onUpload,
  }) {
    return Row(
      children: [
        Icon(icon, size: 30, color: Colors.orange.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Upload",
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final boxWidth = isWeb ? 450 : screenWidth * 0.9;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade300,
                      Colors.orange.shade400,
                      Colors.deepOrange.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    transform: GradientRotation(_controller.value * 2 * pi),
                  ),
                ),
              );
            },
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Step 2 of 4: Upload Documents",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: boxWidth.toDouble(),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildUploadSection(
                            context,
                            label: "Student ID Proof",
                            icon: Icons.badge,
                            onUpload: () => uploadDocument("Student ID Proof"),
                          ),
                          const Divider(thickness: 1.2, color: Colors.orange),
                          _buildUploadSection(
                            context,
                            label: "Proof of Registration",
                            icon: Icons.receipt_long,
                            onUpload: () =>
                                uploadDocument("Proof of Registration"),
                          ),
                          const Divider(thickness: 1.2, color: Colors.orange),
                          _buildUploadSection(
                            context,
                            label: "Other Documents",
                            icon: Icons.folder_open,
                            onUpload: () => uploadDocument("Other Documents"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Uploaded Documents",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...documents.map((doc) {
                    return Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: boxWidth.toDouble(),
                          child: ListTile(
                            leading: Icon(
                              Icons.description,
                              color: Colors.orange.shade700,
                            ),
                            title: Text(doc['description']),
                            subtitle: Text(doc['name']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteDocument(doc['_id']),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (documents.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "Please upload at least one document before proceeding.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HomePage(token: widget.token),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Next",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
