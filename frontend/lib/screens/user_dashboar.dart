import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:firebase_messaging/firebase_messaging.dart'; // For FCM
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // For local notifications

import '../config.dart';
import '../services/api_service.dart';
import 'ChatBotPage.dart';
import 'ChatUsersPage.dart';
import 'NotificationsListPage.dart';
import 'ReservationStatusPage.dart';
import 'housing_guidelines_page.dart';
import 'profilePage.dart';

// Initialize Firebase Messaging
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

// Initialize Local Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background Notification Handler (must be a top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background notification: ${message.notification?.title}');
  // Show local notification
  await _showLocalNotification({
    'title': message.notification?.title ?? 'No Title',
    'message': message.notification?.body ?? 'No Message',
  });
}

// Show Local Notification
Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'sakni_notifications_channel', // Channel ID
    'Sakni Notifications', // Channel Name
    importance: Importance
        .max, // Importance level (max will show a heads-up notification)
    priority: Priority
        .high, // Priority level (high will make the notification more prominent)
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    notification['title'],
    notification['message'],
    platformChannelSpecifics,
  );
}

class UserDashboard extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String token; // Token for API calls

  const UserDashboard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.token,
  });

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<dynamic> notifications = []; // List to store notifications
  Timer? _notificationTimer; // Timer to fetch notifications periodically

  @override
  void initState() {
    super.initState();
    _startNotificationTimer(); // Start the timer to fetch notifications
    _initializeFirebaseMessaging(); // Initialize Firebase Messaging
    _initializeLocalNotifications(); // Initialize Local Notifications
  }

  @override
  void dispose() {
    _notificationTimer
        ?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Start a timer to fetch notifications every second
  void _startNotificationTimer() {
    _notificationTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _fetchUnreadNotifications();
    });
  }

  // Fetch unread notifications from the backend
  Future<void> _fetchUnreadNotifications() async {
    final userProfile = await ApiService.fetchUserProfile(widget.token);

    try {
      final response = await http.get(
        Uri.parse(
            '${getBaseUrl()}/api/notifications/unread/${userProfile['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = data;
        });

        // Mark notifications as read after displaying
        for (var notification in notifications) {
          await _markNotificationAsRead(notification['_id']);
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  // Mark a notification as read
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${getBaseUrl()}/api/notifications/mark-read/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Initialize Firebase Messaging
  void _initializeFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification: ${message.notification?.title}');
      // Display the notification in the UI
      setState(() {
        notifications.add({
          'title': message.notification?.title ?? 'No Title',
          'message': message.notification?.body ?? 'No Message',
        });
      });

      // Show local notification
      _showLocalNotification({
        'title': message.notification?.title ?? 'No Title',
        'message': message.notification?.body ?? 'No Message',
      });
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialize Local Notifications
  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 600;

    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              backgroundColor: Colors.orange.shade700,
              title: const Text(
                'Dashboard',
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
                    child: Stack(
                      children: [
                        GridView.count(
                          crossAxisCount: isWeb ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildDashboardCard(
                              context,
                              title: 'Profile',
                              icon: Icons.person,
                              color: Colors.deepOrange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfilePage(
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              context,
                              title: 'Applications',
                              icon: Icons.assignment,
                              color: Colors.teal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ApplicationGuidelinesPage(
                                            token: widget.token),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              context,
                              title: 'Track Reservations',
                              icon: Icons.track_changes,
                              color: Colors.blueAccent,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReservationStatusPage(
                                        token: widget.token),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              context,
                              title: 'Notifications',
                              icon: Icons.notifications,
                              color: Colors.amber,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationListPage(
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              context,
                              title: 'Messages',
                              icon: Icons.message,
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChatUsersPage(token: widget.token),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              context,
                              title: 'Support',
                              icon: Icons.support_agent,
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatBotPage(
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        if (notifications.isNotEmpty)
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: _buildNotificationPopup(),
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

  // Build the notification popup
  Widget _buildNotificationPopup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notifications.map((notification) {
          return ListTile(
            title: Text(notification['title'] ?? 'No Title'),
            subtitle: Text(notification['message'] ?? 'No Message'),
          );
        }).toList(),
      ),
    );
  }

  // Rest of the existing methods (_buildHeader, _buildSidebarMenu, etc.) go here
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
              children: [
                Text(
                  'Welcome, ${widget.userName}!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  widget.userEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
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
            children: [
              Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.userEmail,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        _buildMenuItem(
          context,
          icon: Icons.person,
          title: 'Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfilePage(token: widget.token),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.assignment,
          title: 'Applications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ApplicationGuidelinesPage(token: widget.token),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.track_changes,
          title: 'Track Reservations',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReservationStatusPage(token: widget.token),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.notifications,
          title: 'Notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationListPage(
                  token: widget.token,
                ),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.message,
          title: 'Messages',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatUsersPage(token: widget.token),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.support_agent,
          title: 'Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatBotPage(
                  token: widget.token,
                ),
              ),
            );
          },
        ),
        const Divider(),
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
