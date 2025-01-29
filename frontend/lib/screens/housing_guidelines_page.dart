import 'package:flutter/material.dart';

import 'upload_documents_page.dart';

class ApplicationGuidelinesPage extends StatelessWidget {
  final String token;

  const ApplicationGuidelinesPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Guidelines'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade200, Colors.orange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title Section
                const Text(
                  'Application Guidelines',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Explore the resources below to get started with your application.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Interactive Box with Buttons
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: isWeb ? 500 : screenWidth * 0.85,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildInteractiveButton(
                          context,
                          icon: Icons.article,
                          title: 'Step-by-Step Application',
                          description:
                              'Detailed steps for submitting your application.',
                          onTap: () {
                            // Navigate to Step-by-Step Application Page
                          },
                        ),
                        _buildInteractiveButton(
                          context,
                          icon: Icons.upload_file,
                          title: 'Required Documents',
                          description:
                              'Upload necessary documents for your application.',
                          onTap: () {
                            // Navigate to Required Documents Page
                          },
                        ),
                        _buildInteractiveButton(
                          context,
                          icon: Icons.rule,
                          title: 'Rules and Policies',
                          description:
                              'Understand the rules for campus housing.',
                          onTap: () {
                            // Navigate to Rules and Policies Page
                          },
                        ),
                        _buildInteractiveButton(
                          context,
                          icon: Icons.question_answer,
                          title: 'FAQs',
                          description: 'Get answers to common questions.',
                          onTap: () {
                            // Navigate to FAQs Page
                          },
                        ),
                        _buildInteractiveButton(
                          context,
                          icon: Icons.shield,
                          title: 'Safety Guidelines',
                          description: 'Learn about campus safety measures.',
                          onTap: () {
                            // Navigate to Safety Guidelines Page
                          },
                        ),
                        _buildInteractiveButton(
                          context,
                          icon: Icons.support,
                          title: 'Support and Contact',
                          description: 'Need help? Reach out to us anytime.',
                          onTap: () {
                            // Navigate to Support and Contact Page
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Start Application Button
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the UploadDocumentsPage with the token
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UploadDocumentsPage(token: token),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                    backgroundColor: Colors.orange.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Start Application',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Function to Build Interactive Buttons
  Widget _buildInteractiveButton(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
