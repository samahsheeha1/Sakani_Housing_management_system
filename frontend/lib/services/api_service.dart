import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static Future<Map<String, dynamic>> fetchUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/api/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    required String fullName,
    required String email,
    required String phone,
    required String address,
  }) async {
    final response = await http.put(
      Uri.parse('${getBaseUrl()}/api/users/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Updated user profile
    } else {
      // Log unexpected responses
      print('Response body: ${response.body}');
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to update profile',
      );
    }
  }

  // Add Change Password Method
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/api/users/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Password updated successfully
    } else {
      // Handle errors and log them
      print('Response body: ${response.body}');
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to change password',
      );
    }
  }

  static Future<List<dynamic>> fetchNotifications(String userId) async {
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/api/notifications/$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<List<dynamic>> fetchUsersWhoChattedWithUser(
      String userId) async {
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/api/users/$userId/chats'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch users who chatted with the user');
    }
  }
}
