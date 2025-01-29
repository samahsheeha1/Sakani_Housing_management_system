import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:math';
import '../config.dart';
import '../services/api_service.dart'; // Import the centralized ApiService
import 'user_dashboar.dart'; // Import the UserDashboard page
import 'package:http/http.dart' as http;

class ConfirmationPage extends StatelessWidget {
  final String roomType;
  final String reservationId;
  final String roomId; // Add roomId
  final String token;

  const ConfirmationPage({
    super.key,
    required this.roomType,
    required this.reservationId,
    required this.roomId, // Include roomId
    required this.token,
  });

  Future<void> saveReservation(BuildContext context) async {
    final url = Uri.parse('${getBaseUrl()}/api/reservations');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reservationId': reservationId,
          'roomType': roomType,
          'roomId': roomId, // Pass roomId
        }),
      );

      if (response.statusCode == 201) {
        print('Reservation saved successfully!');
      } else {
        throw Exception('Failed to save reservation');
      }
    } catch (error) {
      print('Error saving reservation: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reservation: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    // Save reservation when the page is loaded
    Future.microtask(() => saveReservation(context));

    return WillPopScope(
      onWillPop: () async {
        // Return false to disable the back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reservation Confirmed'),
          backgroundColor: Colors.orange,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            const AnimatedBalloonBackground(),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 100,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Reservation Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your reservation for a $roomType has been confirmed.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: isWeb ? 400 : screenWidth * 0.9,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              title: 'Reservation ID:',
                              value: reservationId,
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              title: 'Room Type:',
                              value: roomType,
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              title: 'Room ID:',
                              value: roomId, // Display roomId
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              title: 'Status:',
                              value: 'Confirmed',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final userProfile =
                              await ApiService.fetchUserProfile(token);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDashboard(
                                userName: userProfile['fullName'],
                                userEmail: userProfile['email'],
                                token: token,
                              ),
                            ),
                          );
                        } catch (error) {
                          print('Failed to navigate to dashboard: $error');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to fetch user data: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
                        'Go to Dashboard',
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String title, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Animated Balloons Background Widget
class AnimatedBalloonBackground extends StatelessWidget {
  const AnimatedBalloonBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(20, (index) {
        final random = Random();
        final startDelay = random.nextInt(5);
        final duration = random.nextInt(5) + 5;

        return Positioned(
          bottom: random.nextDouble() * MediaQuery.of(context).size.height,
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          child: AnimatedBalloon(
            delay: Duration(seconds: startDelay),
            duration: Duration(seconds: duration),
          ),
        );
      }),
    );
  }
}

class AnimatedBalloon extends StatefulWidget {
  final Duration delay;
  final Duration duration;

  const AnimatedBalloon({
    super.key,
    required this.delay,
    required this.duration,
  });

  @override
  State<AnimatedBalloon> createState() => _AnimatedBalloonState();
}

class _AnimatedBalloonState extends State<AnimatedBalloon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..addListener(() {
        if (_controller.status == AnimationStatus.completed) {
          _controller.repeat();
        }
      });

    _animation = Tween<double>(begin: 1.0, end: -0.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset:
              Offset(0, _animation.value * MediaQuery.of(context).size.height),
          child: child,
        );
      },
      child: Icon(
        Icons.circle,
        size: Random().nextDouble() * 30 + 20,
        color: Colors.orangeAccent.withOpacity(0.5),
      ),
    );
  }
}
