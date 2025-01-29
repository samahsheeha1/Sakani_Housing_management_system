import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart'; // Add this package
import 'dart:convert';
import '../config.dart';
import '../services/api_service.dart';
import 'ConfirmationPage.dart';
import 'RoommateDetailsPage.dart'; // Import the new details page

class RoommateMatchingPage extends StatefulWidget {
  final bool requiresRoommates;
  final Map<String, dynamic> selectedRoom;
  final String token;
  final VoidCallback onSkip;

  const RoommateMatchingPage({
    super.key,
    required this.requiresRoommates,
    required this.selectedRoom,
    required this.token,
    required this.onSkip,
  });

  @override
  _RoommateMatchingPageState createState() => _RoommateMatchingPageState();
}

class _RoommateMatchingPageState extends State<RoommateMatchingPage> {
  List<dynamic> potentialRoommates = [];
  List<dynamic> filteredRoommates = [];
  List<dynamic> selectedRoommates = [];
  List<String> assignedRoommateIds = [];
  int requiredRoommates = 0;
  String? selectedInterest;
  String? userId; // User ID fetched from the profile
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() => isLoading = true);
    await _fetchUserId();
    _calculateRequiredRoommates();
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

  void _calculateRequiredRoommates() {
    final beds = widget.selectedRoom['beds'] ?? 0; // Access beds field
    requiredRoommates =
        (beds > 1) ? (beds - 1) : 0; // Calculate roommates needed
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

          assignedRoommateIds = potentialRoommates
              .where((roommate) => roommate['status'] == 'Matched')
              .map<String>((roommate) => roommate['_id'])
              .toList();
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

  Future<void> _assignSelectedRoommates() async {
    for (var roommate in selectedRoommates) {
      await _assignRoommate(roommate['_id']);
    }
  }

  Future<void> _assignRoommate(String roommateId) async {
    if (userId == null) {
      print('User ID is not available.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/roommates/assign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'roommateId': roommateId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('Roommate assigned successfully');
      } else {
        print('Failed to assign roommate');
      }
    } catch (e) {
      print('Error assigning roommate: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.requiresRoommates) {
      Future.microtask(() => widget.onSkip());
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roommate Matching'),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade200, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Page Header and Filter
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Find the Perfect Roommate',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
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
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  hint: const Text('Filter by Interest'),
                                  items: [
                                    'Music',
                                    'Sports',
                                    'Reading',
                                    'Travel'
                                  ].map((interest) {
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
                  ),
                  // Roommate List
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredRoommates.length,
                      itemBuilder: (context, index) {
                        final roommate = filteredRoommates[index];
                        final isSelected = selectedRoommates
                            .any((r) => r['_id'] == roommate['_id']);

                        return _buildRoommateCard(
                            context, roommate, isSelected);
                      },
                    ),
                  ),
                  // Next Button
                  ElevatedButton(
                    onPressed: selectedRoommates.length == requiredRoommates
                        ? () async {
                            await _assignSelectedRoommates();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConfirmationPage(
                                  roomType: widget.selectedRoom['type'] ??
                                      'Room', // Pass roomType
                                  reservationId:
                                      'R${DateTime.now().millisecondsSinceEpoch}', // Generate reservationId
                                  roomId: widget.selectedRoom[
                                      '_id'], // Pass roomId (assuming '_id' is the field for roomId)
                                  token: widget.token, // Pass token
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedRoommates.length == requiredRoommates
                              ? Colors.orange.shade700
                              : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      selectedRoommates.length == requiredRoommates
                          ? 'Next'
                          : 'Select $requiredRoommates roommate(s) to continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRoommateCard(
      BuildContext context, dynamic roommate, bool isSelected) {
    final isAlreadyMatched = assignedRoommateIds.contains(roommate['_id']);

    // Construct the URL
    final imageUrl = '${getBaseUrl()}/${roommate['photo']}';
    print('Roommate Image URL: $imageUrl'); // Print the image URL for debugging

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoommateDetailsPage(
                      roommate: roommate,
                      token: widget.token, // Pass the token here
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 40,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roommate['fullName'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Status: ${roommate['status']}',
                    style: TextStyle(
                      color: roommate['status'] == 'Available'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (!isAlreadyMatched)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (isSelected) {
                      selectedRoommates
                          .removeWhere((r) => r['_id'] == roommate['_id']);
                    } else {
                      selectedRoommates.add(roommate);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.grey : Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isSelected ? 'Unmatch' : 'Match',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
