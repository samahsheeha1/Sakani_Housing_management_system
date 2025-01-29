import 'package:flutter/material.dart';

import 'ManageRequestsPage.dart';
import 'ReportsAndStatisticsPage.dart';
import 'admin_messages.dart';
import 'manage_room_owner_page.dart';
import 'manage_rooms_page.dart';
import 'manage_students.dart';

class AdminDashboard extends StatelessWidget {
  final String token; // Accept token as a parameter

  const AdminDashboard(
      {super.key,
      required this.token}); // Update constructor to accept the token

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
                'Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
      drawer: isWeb
          ? null
          : Drawer(
              child: _buildSidebarMenu(context),
            ),
      body: Row(
        children: [
          if (isWeb)
            Container(
              width: 250,
              color: Colors.orange.shade50,
              child: _buildSidebarMenu(context),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade100, Colors.orange.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: isWeb ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildDashboardCard(
                          context,
                          title: 'Manage Requests',
                          icon: Icons.request_page,
                          color: Colors.deepOrange,
                          onTap: () {
                            // Pass the token to ManageRequestsPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageRequestsPage(
                                  token: token, // Pass the token here
                                ),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          context,
                          title: 'Manage Rooms',
                          icon: Icons.meeting_room,
                          color: Colors.blueAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageRoomsPage(
                                  token: token, // Pass the token here
                                ),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          context,
                          title: 'Manage Students',
                          icon: Icons.person,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageStudents(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          context,
                          title: 'Messages',
                          icon: Icons.notifications,
                          color: Colors.amber,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminMessagePage(
                                  token: token, // Pass the token here
                                ),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          context,
                          title: 'Reports & Statistics',
                          icon: Icons.bar_chart,
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReportsAndStatisticsPage(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          context,
                          title: 'Manage Room Owner',
                          icon: Icons.home_work,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageRoomOwnerPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              children: const [
                Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  'Manage your dashboard efficiently.',
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

  Widget _buildSidebarMenu(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade300, Colors.orange.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'admin@example.com',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        _buildMenuItem(
          context,
          icon: Icons.request_page,
          title: 'Manage Requests',
          onTap: () {
            // Pass the token to ManageRequestsPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageRequestsPage(
                  token: token, // Pass the token here
                ),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.meeting_room,
          title: 'Manage Rooms',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageRoomsPage(
                  token: token, // Pass the token here
                ),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.person,
          title: 'Manage Students',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageStudents(),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.notifications,
          title: 'Messages',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminMessagePage(
                  token: token, // Pass the token here
                ),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.bar_chart,
          title: 'Reports & Statistics',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportsAndStatisticsPage(),
              ),
            );
          },
        ),
        // Replace "Manage Room Owner" with "Log Out" in the sidebar menu
        _buildMenuItem(
          context,
          icon: Icons.logout,
          title: 'Log Out',
          onTap: () {
            Navigator.pushNamed(context, '/');
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
            padding: const EdgeInsets.all(16),
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
