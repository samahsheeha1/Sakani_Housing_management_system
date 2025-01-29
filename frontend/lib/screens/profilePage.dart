import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this import
import '../config.dart';
import '../services/api_service.dart';
import 'editProfilePage.dart';
import 'changePassword.dart'; // Import the ChangePasswordPage

class UserProfilePage extends StatefulWidget {
  final String token; // Token passed from UserDashboard

  const UserProfilePage({super.key, required this.token});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;

  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Gradient animation setup
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _gradientColor1 = ColorTween(
      begin: Colors.orange.shade300,
      end: Colors.deepOrange.shade500,
    ).animate(_controller);

    _gradientColor2 = ColorTween(
      begin: Colors.orange.shade100,
      end: Colors.orangeAccent.shade400,
    ).animate(_controller);

    // Load user profile
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gradientColor1.value!, _gradientColor2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildProfileContent(context),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    if (userProfile == null) {
      return const Center(
        child: Text(
          'No profile data available',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width:
              MediaQuery.of(context).size.width > 800 ? 600 : double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Updated CircleAvatar widget with CachedNetworkImage
              CircleAvatar(
                radius: 50,
                backgroundImage: userProfile!['photo'] != null &&
                        userProfile!['photo'].isNotEmpty
                    ? CachedNetworkImageProvider(
                        '${getBaseUrl()}/${userProfile!['photo']}')
                    : null,
                backgroundColor: Colors.orange.shade200,
                child: userProfile!['photo'] == null ||
                        userProfile!['photo'].isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                userProfile!['fullName'] ?? 'No Name',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 30),
              _buildProfileItem(
                  Icons.email, 'Email', userProfile!['email'] ?? ''),
              _buildProfileItem(Icons.phone, 'Phone',
                  userProfile!['phone'] ?? 'Not provided'),
              _buildProfileItem(Icons.location_on, 'Address',
                  userProfile!['address'] ?? 'Not provided'),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfilePage(token: widget.token),
                    ),
                  ).then((_) => _loadUserProfile()); // Reload profile on return
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordPage(
                        token: widget.token, // Pass the token here
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.lock, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                label: const Text(
                  'Change Password',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Text(
            '$title:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Preload the image before navigating to the profile page
Future<void> navigateToProfilePage(BuildContext context, String token) async {
  try {
    final profile = await ApiService.fetchUserProfile(token);
    if (profile['photo'] != null && profile['photo'].isNotEmpty) {
      final imageUrl = '${getBaseUrl()}/${profile['photo']}';
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(token: token),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load profile')),
    );
  }
}
