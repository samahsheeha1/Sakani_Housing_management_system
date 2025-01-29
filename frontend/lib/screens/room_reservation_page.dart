import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package
import '../services/api_service.dart'; // Import your ApiService
import 'ConfirmationPage.dart';
import 'roommate_matching.dart'; // Import RoommateMatchingPage
import '../config.dart'; // Ensure this is imported for getBaseUrl()

class RoomReservationPage extends StatefulWidget {
  final Map<String, dynamic> room;
  final String token; // Add token as a required parameter

  const RoomReservationPage(
      {super.key, required this.room, required this.token});

  @override
  _RoomReservationPageState createState() => _RoomReservationPageState();
}

class _RoomReservationPageState extends State<RoomReservationPage> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails(); // Fetch user details on page load
  }

  Future<void> fetchUserDetails() async {
    try {
      final user = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        userDetails = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching user details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirm Reservation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade200, Colors.orange.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Room Summary Section
                      SizedBox(
                        width: isWeb ? 600 : screenWidth * 0.9,
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      '${getBaseUrl()}/${widget.room['images'][0]}',
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 50),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.room['type'],
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Price: ${widget.room['price']}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Availability: ${widget.room['availability']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: widget.room['availability'] ==
                                                'Available'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Location: ${widget.room['address'] ?? 'Not specified'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'You are about to reserve this room. Please review the details below and confirm your reservation.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // User Details Section
                      SizedBox(
                        width: isWeb ? 600 : screenWidth * 0.9,
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildDetailRow(Icons.person, 'Name:',
                                    userDetails?['fullName'] ?? 'N/A'),
                                const Divider(),
                                _buildDetailRow(Icons.email, 'Email:',
                                    userDetails?['email'] ?? 'N/A'),
                                const Divider(),
                                _buildDetailRow(Icons.phone, 'Phone:',
                                    userDetails?['phone'] ?? 'N/A'),
                                const Divider(),
                                _buildDetailRow(Icons.location_on, 'Address:',
                                    userDetails?['address'] ?? 'N/A'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (widget.room['type'] == 'Single Room') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ConfirmationPage(
                                      roomType: widget
                                          .room['type'], // Pass the room type
                                      reservationId:
                                          'RSV${DateTime.now().millisecondsSinceEpoch}', // Generate reservationId
                                      roomId: widget.room[
                                          '_id'], // Pass the roomId (assuming '_id' is the field for roomId)
                                      token: widget.token, // Pass the token
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoommateMatchingPage(
                                      requiresRoommates: true,
                                      selectedRoom: widget.room,
                                      token: widget.token,
                                      onSkip: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ConfirmationPage(
                                              roomType: widget.room[
                                                  'type'], // Pass the room type
                                              reservationId:
                                                  'RSV${DateTime.now().millisecondsSinceEpoch}', // Generate reservationId
                                              roomId: widget.room[
                                                  '_id'], // Pass the roomId (assuming '_id' is the field for roomId)
                                              token: widget
                                                  .token, // Pass the token
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 30),
                              backgroundColor: Colors.orange.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 30),
                              side: BorderSide(
                                  color: Colors.orange.shade700, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$title $value',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
