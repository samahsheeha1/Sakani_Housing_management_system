import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package
import 'package:sakani/config.dart';
import '../services/api_service.dart';
import 'Chat.dart';

class RoommateDetailsPage extends StatefulWidget {
  final Map<String, dynamic> roommate;
  final String token;

  const RoommateDetailsPage({
    super.key,
    required this.roommate,
    required this.token,
  });

  @override
  _RoommateDetailsPageState createState() => _RoommateDetailsPageState();
}

class _RoommateDetailsPageState extends State<RoommateDetailsPage> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _preloadImage(); // Preload the roommate's image
  }

  void _fetchUserId() async {
    try {
      final profile = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        userId =
            profile['_id']; // Assuming the API returns the user's ID as 'id'
      });
      print('User ID: $userId');
    } catch (e) {
      print('Failed to fetch user ID: $e');
    }
  }

  void _preloadImage() async {
    if (widget.roommate['photo'] != null &&
        widget.roommate['photo'].isNotEmpty) {
      final imageUrl = '${getBaseUrl()}/${widget.roommate['photo']}';
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    }
  }

  void _navigateToChat(BuildContext context) {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userId: userId!, // Using the fetched user ID
            roommateId: widget.roommate['_id'], // Roommate's ID
            roommateName:
                widget.roommate['fullName'], // Roommate's name for chat
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to load user details. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roommate['fullName']}\'s Details'),
        backgroundColor: Colors.orange.shade700,
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
            child: Card(
              elevation: 5,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Updated CircleAvatar with CachedNetworkImage
                    CircleAvatar(
                      radius: 50,
                      child: CachedNetworkImage(
                        imageUrl: widget.roommate['photo'] != null &&
                                widget.roommate['photo'].isNotEmpty
                            ? '${getBaseUrl()}/${widget.roommate['photo']}'
                            : '', // Fallback to empty string if no photo
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.roommate['fullName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Email: ${widget.roommate['email'] ?? 'Not specified'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Age: ${widget.roommate['age'] ?? 'Not specified'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Interests: ${widget.roommate['interests'] != null ? widget.roommate['interests'].join(', ') : 'Not specified'}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Status: ${widget.roommate['status'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.roommate['status'] == 'Available'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToChat(context),
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
