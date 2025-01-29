import 'dart:io';

import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/student_model.dart';
import '../models/document_model.dart'; // Import the Document model
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Only for mobile

class StudentDetail extends StatelessWidget {
  final Student student;

  const StudentDetail({Key? key, required this.student}) : super(key: key);

  // Function to fetch documents
  Future<List<Document>> fetchDocuments(String userId) async {
    final response = await http
        .get(Uri.parse('${getBaseUrl()}/api/documents/documents/$userId'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((doc) => Document.fromJson(doc)).toList();
    } else {
      throw Exception('Failed to load documents');
    }
  }

  // Function to launch the document URL
  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundImage: CachedNetworkImageProvider(
                student.photo.isNotEmpty
                    ? '${getBaseUrl()}/${student.photo}'
                    : 'https://via.placeholder.com/150',
              ),
              child: student.photo.isEmpty
                  ? Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              student.fullName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              student.email,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _buildDetailCard(
              icon: Icons.phone,
              title: 'Phone',
              value: student.phone,
            ),
            _buildDetailCard(
              icon: Icons.location_on,
              title: 'Address',
              value: student.address,
            ),
            _buildDetailCard(
              icon: Icons.cake,
              title: 'Age',
              value: student.age.toString(),
            ),
            _buildDetailCard(
              icon: Icons.work,
              title: 'Status',
              value: student.status,
            ),
            _buildDetailCard(
              icon: Icons.interests,
              title: 'Interests',
              value: student.interests.join(', '),
            ),
            const SizedBox(height: 20),
            Text(
              'Documents',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Document>>(
              future: fetchDocuments(student.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No documents found.');
                } else {
                  return Column(
                    children: snapshot.data!.map((document) {
                      return ListTile(
                        leading: Icon(Icons.insert_drive_file),
                        title: Text(document.name),
                        subtitle: Text(document.description),
                        onTap: () {
                          final documentUrl =
                              '${getBaseUrl()}/${document.path}';
                          if (document.path.endsWith('.pdf')) {
                            if (kIsWeb) {
                              // Open in a new tab on the web
                              _launchUrl(documentUrl);
                            } else {
                              // Use PDF viewer for mobile
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PdfViewerScreen(url: documentUrl),
                                ),
                              );
                            }
                          } else if (document.path.endsWith('.jpg') ||
                              document.path.endsWith('.png')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(title: Text('Image Viewer')),
                                  body: Center(
                                    child: CachedNetworkImage(
                                      imageUrl: documentUrl,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            _launchUrl(documentUrl);
                          }
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
      {required IconData icon, required String title, required String value}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: TextStyle(fontSize: 14)),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String url;

  const PdfViewerScreen({Key? key, required this.url}) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        // Get the temporary directory of the device
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/temp.pdf';

        // Save the PDF to a temporary file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localPath = filePath;
        });
      } else {
        throw Exception('Failed to load PDF');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      setState(() {
        localPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (localPath == null) {
      return Scaffold(
        appBar: AppBar(title: Text('PDF Viewer')),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer')),
      body: PDFView(
        filePath: localPath!,
      ),
    );
  }
}
