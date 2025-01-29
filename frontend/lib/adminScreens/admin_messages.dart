import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/Chat.dart';
import '../services/api_service.dart';
import '../config.dart';

class AdminMessagePage extends StatefulWidget {
  final String token;

  const AdminMessagePage({
    super.key,
    required this.token,
  });

  @override
  _AdminMessagePageState createState() => _AdminMessagePageState();
}

class _AdminMessagePageState extends State<AdminMessagePage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? adminUserId;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() => isLoading = true);
    try {
      final userProfile = await ApiService.fetchUserProfile(widget.token);
      adminUserId = userProfile['_id'];

      if (adminUserId != null) {
        users = await ApiService.fetchUsersWhoChattedWithUser(adminUserId!);

        // Precache images after the initial build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (var user in users) {
            final imageUrl = '${getBaseUrl()}/${user['photo']}';
            precacheImage(CachedNetworkImageProvider(imageUrl), context);
          }
        });
      }
    } catch (e) {
      print('Error initializing page: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _refreshPage() async {
    await _initializePage();
  }

  @override
  Widget build(BuildContext context) {
    final maxContentWidth = 800.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Messages'),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : users.isEmpty
                  ? Center(child: Text('No users found'))
                  : RefreshIndicator(
                      onRefresh: _refreshPage,
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final hasUnreadMessages =
                              user['hasUnreadMessages'] ?? false;

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            elevation: 2.0,
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '${getBaseUrl()}/${user['photo']}',
                                        placeholder: (context, url) =>
                                            Image.asset(
                                                'assets/placeholder.png'),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (hasUnreadMessages)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    user['fullName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (hasUnreadMessages)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                        Icons.notifications_active,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                user['role'],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      userId: adminUserId!,
                                      roommateId: user['_id'],
                                      roommateName: user['fullName'],
                                    ),
                                  ),
                                ).then((_) {
                                  _refreshPage();
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
