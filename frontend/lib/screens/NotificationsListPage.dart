import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Adjust the import according to your project structure
import 'NotificationDetailsPage.dart'; // Import your NotificationDetailsPage

class NotificationListPage extends StatefulWidget {
  final String token;

  NotificationListPage({required this.token});

  @override
  _NotificationListPageState createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchUserProfileAndNotifications();
  }

  Future<void> fetchUserProfileAndNotifications() async {
    try {
      // Step 1: Fetch user profile
      final userProfile = await ApiService.fetchUserProfile(widget.token);
      final userId =
          userProfile['_id']; // Assuming the user ID is stored in '_id'

      // Step 2: Fetch notifications for the user
      final fetchedNotifications = await ApiService.fetchNotifications(userId);

      setState(() {
        this.userId = userId;
        notifications = fetchedNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints:
              const BoxConstraints(maxWidth: 800), // Limit width for web
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
                  ? const Center(child: Text('No notifications found.'))
                  : ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12), // Spacing between items
                      itemBuilder: (context, index) {
                        return _buildNotificationItem(
                            context, notifications[index]);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, dynamic notification) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.orange.shade300, // Light orange border
          width: 1, // Border width
        ),
        borderRadius: BorderRadius.circular(8), // Rounded corners
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(8), // Rounded corners for tap effect
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationDetailsPage(
                title: notification['title'],
                message: notification['message'],
                date: notification['createdAt'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Notification Icon
              Icon(
                Icons.notifications,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 16), // Spacing between icon and text
              // Notification Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      notification['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Spacing between title and date
                    // Date
                    Text(
                      notification['createdAt'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
