import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'resetpass.dart';

class PasswordResetConfirmationPage extends StatefulWidget {
  final String email;

  const PasswordResetConfirmationPage({super.key, required this.email});

  @override
  _PasswordResetConfirmationPageState createState() =>
      _PasswordResetConfirmationPageState();
}

class _PasswordResetConfirmationPageState
    extends State<PasswordResetConfirmationPage> with TickerProviderStateMixin {
  final TextEditingController _resetCodeController = TextEditingController();
  String errorMessage = ''; // To store error message

  Future<void> verifyResetCode(String email, String resetCode) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/users/reset-password-confirmation'),
        body: json.encode({'email': email, 'resetCode': resetCode}),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Navigate directly to PasswordResetPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PasswordResetPage(email: email, resetCode: resetCode),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Invalid or expired reset code.';
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
    final screenWidth = MediaQuery.of(context).size.width;
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
                  // Add Lottie animation for a smooth experience
                  Lottie.asset(
                    'assets/animations/success_check.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Enter Reset Code',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A reset code has been sent to ${widget.email}. Enter the code below to proceed.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _resetCodeController,
                    decoration: InputDecoration(
                      labelText: 'Reset Code',
                      prefixIcon: Icon(Icons.lock, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      final resetCode = _resetCodeController.text;
                      if (resetCode.isNotEmpty) {
                        verifyResetCode(widget.email, resetCode);
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
                      'Verify Code',
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
