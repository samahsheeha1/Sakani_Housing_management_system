import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'room_selection_page.dart'; // Updated RoomSelectionPage

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Map<String, dynamic>>> fetchRooms(String endpoint) async {
    final url = Uri.parse('${getBaseUrl()}/api/$endpoint');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((room) => Map<String, dynamic>.from(room)).toList();
      } else {
        print('Failed to load rooms: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load rooms');
      }
    } catch (e) {
      print('Error fetching rooms: $e');
      throw Exception('Failed to load rooms');
    }
  }

  void navigateToSelectionPage(BuildContext context, String endpoint) async {
    try {
      final rooms = await fetchRooms(endpoint);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomSelectionPage(
            token: widget.token,
            rooms: rooms,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to selection page: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rooms: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600; // Check if the screen is web or mobile

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Colors.orange,
        elevation: 0, // Remove shadow
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isWeb)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // All Rooms Section
                  Flexible(
                    child: SectionButton(
                      title: 'All Rooms',
                      image: 'assets/images/room1_1.jpg', // Add your image path
                      statement: 'Explore all available rooms for your stay.',
                      onPressed: () {
                        navigateToSelectionPage(context, 'rooms');
                      },
                    ),
                  ),
                  // Featured Deals Section (Image shifted to the right)
                  Flexible(
                    child: SectionButton(
                      title: 'Featured Deals',
                      image:
                          'assets/images/featured_deals.jpg', // Add your image path
                      statement: 'Discover exclusive deals on featured rooms.',
                      onPressed: () {
                        navigateToSelectionPage(context, 'rooms/featured');
                      },
                      shiftImageToRight: true, // Add this parameter
                    ),
                  ),
                  // Visited Rooms Section
                  Flexible(
                    child: SectionButton(
                      title: 'Visited Rooms',
                      image:
                          'assets/images/visited-room.png', // Add your image path
                      statement:
                          'Check out the most visited rooms by other users.',
                      onPressed: () {
                        navigateToSelectionPage(context, 'rooms/most-visited');
                      },
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  // All Rooms Section
                  SectionButton(
                    title: 'All Rooms',
                    image: 'assets/images/room1_1.jpg', // Add your image path
                    statement: 'Explore all available rooms for your stay.',
                    onPressed: () {
                      navigateToSelectionPage(context, 'rooms');
                    },
                  ),
                  const SizedBox(height: 20),
                  // Featured Deals Section
                  SectionButton(
                    title: 'Featured Deals',
                    image:
                        'assets/images/featured_deals.jpg', // Add your image path
                    statement: 'Discover exclusive deals on featured rooms.',
                    onPressed: () {
                      navigateToSelectionPage(context, 'rooms/featured');
                    },
                  ),
                  const SizedBox(height: 20),
                  // Visited Rooms Section
                  SectionButton(
                    title: 'Visited Rooms',
                    image:
                        'assets/images/visited-room.png', // Add your image path
                    statement:
                        'Check out the most visited rooms by other users.',
                    onPressed: () {
                      navigateToSelectionPage(context, 'rooms/most-visited');
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class SectionButton extends StatelessWidget {
  final String title;
  final String image;
  final String statement;
  final VoidCallback onPressed;
  final bool shiftImageToRight; // New parameter to shift the image

  const SectionButton({
    required this.title,
    required this.image,
    required this.statement,
    required this.onPressed,
    this.shiftImageToRight = false, // Default is false
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600; // Check if the screen is web or mobile

    return GestureDetector(
      onTap: onPressed,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Statement
            Text(
              statement,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            // Image Container (Responsive Square Shape)
            if (shiftImageToRight)
              Padding(
                padding: const EdgeInsets.only(
                    left: 50.0), // Shift image to the right
                child: Container(
                  width: isWeb
                      ? screenWidth * 0.25
                      : screenWidth * 0.8, // Responsive width
                  height: isWeb
                      ? screenWidth * 0.25
                      : screenWidth * 0.8, // Responsive height (square)
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage(image),
                      fit: BoxFit.cover, // Ensures the full image is visible
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: isWeb
                    ? screenWidth * 0.25
                    : screenWidth * 0.8, // Responsive width
                height: isWeb
                    ? screenWidth * 0.25
                    : screenWidth * 0.8, // Responsive height (square)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(image),
                    fit: BoxFit.cover, // Ensures the full image is visible
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
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
