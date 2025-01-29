import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../RoomOwner/roomOwner_dashboard.dart';
import '../adminScreens/adminDashboard.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'ChooseRolePage.dart';
import 'user_dashboar.dart';
import 'forgot_password_page.dart'; // Import Forgot Password Page

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _notificationKey = GlobalKey();

  String? errorMessage;

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

  Future<void> _loginUser() async {
    setState(() {
      errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/users/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Fetch user profile to determine the role
        final profile = await ApiService.fetchUserProfile(data['token']);
        final role = profile['role'];
        /*
        String? fcmToken;

        if (kIsWeb) {
          try {
            fcmToken = await FirebaseMessaging.instance.getToken(
              vapidKey:
                  "BNIXv5mkY36iUkypLB3uB_qmQJZzzhIYfnahRu9IqXGxlkkAYllkNwR6EyIUD0umyll-GeKgyQ07CV6fF-KKgf0", // Replace with your Web Push certificate key
            );
            if (fcmToken == null) {
              print("Failed to retrieve FCM Token on Web: Token is null");
            } else {
              print("Retrieved FCM Token on Web: $fcmToken");
            }
          } catch (e) {
            print("Error retrieving FCM Token on Web: $e");
          }
        } else {
          // Handle token retrieval for mobile
          fcmToken = await FirebaseMessaging.instance.getToken();
        }

        print("Retrieved FCM Token: $fcmToken");
        print("User ID: ${profile['_id']}");

        if (fcmToken != null) {
          print("Retrieved FCM Token: $fcmToken");

          // Save the FCM token after login
          await NotificationService().saveFCMToken(profile['_id'], fcmToken);
        }*/
        if (role == 'Admin') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboard(
                  token: data['token']), // Replace with the actual token
            ),
          );
        } else if (role == 'Student') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDashboard(
                userName: data['fullName'], // Pass userName
                userEmail: data['email'], // Pass userEmail
                token: data['token'], // Pass token
              ),
            ),
          );
        } else if (role == 'Room Owner') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomOwnerDashboard(
                  token: data['token']), // Replace with the actual token
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = 'Incorrect email or password';
        });
        _showNotification('Incorrect email or password', Icons.error, true);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Something went wrong.';
      });
      _showNotification('Something went wrong.', Icons.error, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: Center(
        child: isWeb
            ? Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildLoginForm(),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Image.asset(
                      'assets/images/login_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isPortrait
                      ? Column(
                          children: [
                            Image.asset(
                              'assets/images/login_logo.png',
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 20),
                            _buildLoginForm(),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Image.asset(
                                'assets/images/login_logo.png',
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildLoginForm(),
                            ),
                          ],
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Login to Sakni',
            key: _notificationKey,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
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
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email, color: Colors.orange.shade700),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                _showNotification('Please enter your email', Icons.error, true);
                return 'Please enter your email';
              } else if (!RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                  .hasMatch(value)) {
                _showNotification(
                    'Please enter a valid email', Icons.error, true);
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock, color: Colors.orange.shade700),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                _showNotification(
                    'Please enter your password', Icons.error, true);
                return 'Please enter your password';
              } else if (value.length < 8) {
                _showNotification('Password must be at least 8 characters',
                    Icons.error, true);
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navigate to the Forgot Password page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForgotPasswordPage(),
                  ),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loginUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Login',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChooseRolePage(),
                    ),
                  );
                },
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
