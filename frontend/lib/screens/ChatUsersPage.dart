import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart'; // Add this package
import 'dart:convert';
import '../config.dart';
import '../services/api_service.dart';
import 'Chat.dart';
import 'RoommateDetailsPage.dart';

class ChatUsersPage extends StatefulWidget {
  final String token;

  const ChatUsersPage({
    super.key,
    required this.token,
  });

  @override
  _ChatUsersPageState createState() => _ChatUsersPageState();
}

class _ChatUsersPageState extends State<ChatUsersPage> {
  List<dynamic> potentialRoommates = [];
  List<dynamic> filteredRoommates = [];
  String? selectedInterest;
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() => isLoading = true);
    await _fetchUserId();
    await _fetchRoommates();
    setState(() => isLoading = false);
  }

  Future<void> _fetchUserId() async {
    try {
      final userProfile = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        userId = userProfile['_id'];
      });
    } catch (e) {
      print('Error fetching user ID: $e');
    }
  }

  Future<void> _fetchRoommates() async {
    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/api/roommates'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          potentialRoommates = data.where((roommate) {
            // Exclude roommates with the same ID as the user or with roles "Admin" or "Room Owner"
            return roommate['_id'] != userId &&
                roommate['role'] != 'Admin' &&
                roommate['role'] != 'Room Owner';
          }).toList();

          filteredRoommates = List.from(potentialRoommates);
        });

        // Preload images for all roommates
        for (var roommate in potentialRoommates) {
          if (roommate['photo'] != null && roommate['photo'].isNotEmpty) {
            final imageUrl = '${getBaseUrl()}/${roommate['photo']}';
            precacheImage(CachedNetworkImageProvider(imageUrl), context);
          }
        }
      } else {
        print('Failed to fetch roommates');
      }
    } catch (e) {
      print('Error fetching roommates: $e');
    }
  }

  void _filterRoommatesByInterest(String? interest) {
    setState(() {
      if (interest == null || interest.isEmpty) {
        filteredRoommates = List.from(potentialRoommates);
      } else {
        filteredRoommates = potentialRoommates
            .where((roommate) =>
                roommate['interests'] != null &&
                roommate['interests'].contains(interest))
            .toList();
      }
      selectedInterest = interest;
    });
  }

  void _clearSearch() {
    setState(() {
      selectedInterest = null;
      filteredRoommates = List.from(potentialRoommates);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Users'),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : kIsWeb
              ? _buildWebDesign()
              : _buildMobileDesign(),
    );
  }

  // Professional and Creative Web Design
  Widget _buildWebDesign() {
    return Container(
      color: Colors.orange.shade100, // Light orange background
      child: Center(
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(2, 5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chat, color: Colors.orange, size: 32),
                  SizedBox(width: 10),
                  Text(
                    'Welcome to Chat Users',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSearchFilter(),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: filteredRoommates.length,
                  itemBuilder: (context, index) {
                    final roommate = filteredRoommates[index];
                    return _buildRoommateCard(context, roommate);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile Design
  Widget _buildMobileDesign() {
    return Container(
      color: Colors.orange.shade100, // Light orange background
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildSearchFilter(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filteredRoommates.length,
              itemBuilder: (context, index) {
                final roommate = filteredRoommates[index];
                return _buildRoommateCard(context, roommate);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search,
                  color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 10),
              Text(
                'Find and Contact Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: DropdownButtonFormField<String>(
                    value: selectedInterest,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    hint: const Text('Filter by Interest'),
                    items: ['Music', 'Sports', 'Reading', 'Travel']
                        .map((interest) {
                      return DropdownMenuItem<String>(
                        value: interest,
                        child: Text(interest),
                      );
                    }).toList(),
                    onChanged: _filterRoommatesByInterest,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  Widget _buildRoommateCard(BuildContext context, dynamic roommate) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoommateDetailsPage(
                      roommate: roommate,
                      token: widget.token,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 40,
                child: CachedNetworkImage(
                  imageUrl: '${getBaseUrl()}/${roommate['photo']}',
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
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              roommate['fullName'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      userId: userId!,
                      roommateId: roommate['_id'],
                      roommateName: roommate['fullName'],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Chat', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
