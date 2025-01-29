import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'login_page.dart';

class PasswordResetPage extends StatefulWidget {
  final String email;
  final String resetCode;

  const PasswordResetPage(
      {super.key, required this.email, required this.resetCode});

  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage>
    with TickerProviderStateMixin {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String errorMessage = '';

  Future<void> resetPassword(
      String email, String resetCode, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/users/reset-password'),
        body: json.encode({
          'email': email,
          'resetCode': resetCode,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          errorMessage = responseData['message'] ?? 'Failed to reset password';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth > 600 ? 500 : screenWidth * 0.9;

    return Scaffold(
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            baseColor: Colors.orange,
            spawnOpacity: 0.1,
            opacityChangeRate: 0.25,
            minOpacity: 0.1,
            maxOpacity: 0.4,
            spawnMinSpeed: 20.0,
            spawnMaxSpeed: 50.0,
            spawnMinRadius: 5.0,
            spawnMaxRadius: 15.0,
            particleCount: 70,
          ),
        ),
        vsync: this,
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFA726),
                    Color(0xFFFF7043),
                  ], // Orange gradient colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Replace the animation with an image
                  Image.asset(
                    'assets/images/password_reset.png', // Update the path to your image
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Enter New Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      final newPassword = _newPasswordController.text;
                      final confirmPassword = _confirmPasswordController.text;

                      if (newPassword == confirmPassword) {
                        resetPassword(
                            widget.email, widget.resetCode, newPassword);
                      } else {
                        setState(() {
                          errorMessage = 'Passwords do not match';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      side: const BorderSide(
                          color: Colors.orange, width: 2), // Add border
                    ),
                    child: const Text(
                      'Reset Password',
                      style: TextStyle(fontSize: 18, color: Colors.orange),
                    ),
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
