import 'package:flutter/material.dart';
import 'package:sakani/adminScreens/manage_rooms_page.dart';
import 'package:sakani/adminScreens/ManageRequestsPage.dart';
import 'package:sakani/adminScreens/edit_room_owner_page.dart';
import 'package:sakani/screens/editProfilePage.dart';

import '../services/api_service.dart';

class RoomOwnerDashboard extends StatelessWidget {
  final String token; // Accept token as a parameter

  const RoomOwnerDashboard({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              backgroundColor: Colors.orange.shade700,
              title: const Text(
                'Room Owner Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    Navigator.pushNamed(context, '/');
                  },
                ),
              ],
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.orange.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: ApiService.fetchUserProfile(token), // Fetch user profile
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(), // Show loading indicator
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child:
                        Text('Error: ${snapshot.error}'), // Show error message
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No user data found'), // Handle no data case
                  );
                } else {
                  final userProfile = snapshot.data!;
                  final fullName = userProfile['fullName']; // Access fullName
                  return _buildHeader(context, fullName); // Pass fullName
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: isWeb ? 3 : 1, // 1 column for mobile, 3 for web
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'Manage Rooms',
                    icon: Icons.meeting_room,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageRoomsPage(token: token),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Manage Reservations',
                    icon: Icons.list_alt,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ManageRequestsPage(token: token),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Edit Profile',
                    icon: Icons.person,
                    color: Colors.purple,
                    onTap: () async {
                      try {
                        // Fetch the user profile data
                        final userProfile =
                            await ApiService.fetchUserProfile(token);

                        // Navigate to the EditRoomOwnerPage with the fetched data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditRoomOwnerPage(owner: userProfile),
                          ),
                        );
                      } catch (e) {
                        // Handle any errors that occur during fetching
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to fetch profile: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isWeb
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              child: const Icon(Icons.logout),
              backgroundColor: Colors.red,
            )
          : null, // Show FAB only on web
    );
  }

  Widget _buildHeader(BuildContext context, String fullName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $fullName!', // Use the fetched fullName
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage your rooms and reservations efficiently.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600; // Check if it's web or mobile
    final buttonHeight = isWeb ? 120.0 : 100.0; // Adjust height dynamically
    final buttonWidth =
        isWeb ? screenWidth / 4 : screenWidth * 0.9; // Suitable width

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            width: buttonWidth, // Adjust width dynamically
            height: buttonHeight, // Adjust height dynamically
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
