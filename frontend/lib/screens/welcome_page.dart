import 'package:flutter/material.dart';

import 'ChooseRolePage.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 600; // Check if it's web or mobile

    return Scaffold(
      body: Center(
        child: isWeb
            ? Row(
                // Web layout: Animation on the right, content centered
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Centered Welcome Text
                            Text(
                              'Welcome to Sakni!',
                              style: TextStyle(
                                fontSize:
                                    screenWidth * 0.03, // Responsive font size
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenWidth * 0.01), // Spacing
                            Text(
                              'Simplify your housing experience.',
                              style: TextStyle(
                                fontSize:
                                    screenWidth * 0.02, // Responsive font size
                                color: Colors.orange.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenWidth * 0.05), // Spacing
                            // Centered Buttons
                            SizedBox(
                              width: screenWidth > 400 ? 300 : 250,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginPage()),
                                  ); // Navigate to Login Page
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: screenWidth *
                                        0.02, // Responsive font size
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: screenWidth > 400 ? 300 : 250,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ChooseRolePage()),
                                  ); // Navigate to Sign-Up Page
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.orange.shade700, width: 2),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: screenWidth *
                                        0.02, // Responsive font size
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Animation on the right
                  Expanded(
                    flex: 1,
                    child: Image.asset(
                      'assets/images/welcome_animation.gif', // Ensure the animation is in assets/images
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                // Mobile layout: Animation on top
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation on top
                    Image.asset(
                      'assets/images/welcome_animation.gif',
                      height: screenWidth > 400 ? 300 : 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Centered Welcome Text
                          Text(
                            'Welcome to Sakni!',
                            style: TextStyle(
                              fontSize:
                                  screenWidth * 0.08, // Responsive font size
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Simplify your housing experience.',
                            style: TextStyle(
                              fontSize:
                                  screenWidth * 0.05, // Responsive font size
                              color: Colors.orange.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          // Centered Buttons
                          SizedBox(
                            width: screenWidth > 400 ? 300 : 250,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginPage()),
                                ); // Navigate to Login Page
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: screenWidth > 400 ? 300 : 250,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ChooseRolePage()),
                                ); // Navigate to Sign-Up Page
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.orange.shade700, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  color: Colors.orange.shade700,
                                ),
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
    );
  }
}
