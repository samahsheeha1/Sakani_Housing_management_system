import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';
import '../services/api_service.dart'; // Import your ApiService

class ManageRequestsPage extends StatefulWidget {
  final String token; // Accept the token as a parameter

  const ManageRequestsPage({Key? key, required this.token}) : super(key: key);

  @override
  _ManageRequestsPageState createState() => _ManageRequestsPageState();
}

class _ManageRequestsPageState extends State<ManageRequestsPage> {
  List<dynamic> _requests = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  String? _searchQuery;
  String? _filterStatus;
  Map<String, dynamic>? _userProfile;
  List<String> _roomIds = []; // Store room IDs for Room Owner

  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    _baseUrl = '${getBaseUrl()}/api'; // Dynamically determine the base URL
    _fetchUserProfile(); // Fetch user profile first
  }

  // Fetch user profile to determine role
  Future<void> _fetchUserProfile() async {
    try {
      final userProfile = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        _userProfile = userProfile;
      });

      // If user is a Room Owner, fetch their rooms
      if (_userProfile!['role'] == 'Room Owner') {
        await _fetchRoomsByOwner(_userProfile!['_id']);
      }

      // Fetch reservations after determining role
      _fetchRequests();
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user profile: $error')),
      );
    }
  }

  Future<void> _fetchRoomsByOwner(String ownerId) async {
    try {
      final uri = Uri.parse('$_baseUrl/rooms/by-owner/$ownerId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final rooms = jsonDecode(response.body);
        print('Fetched Rooms for Owner: $rooms');
        setState(() {
          _roomIds =
              rooms.map<String>((room) => room['_id'].toString()).toList();
        });
        print('Room IDs: $_roomIds');
      } else {
        throw Exception(
            'Failed to fetch rooms. Status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching rooms: $error');
      throw Exception('Error: $error');
    }
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final queryParameters = {
        'page': _currentPage.toString(),
        'limit': '10',
        if (_searchQuery != null && _searchQuery!.isNotEmpty)
          'search': _searchQuery,
        if (_filterStatus != null && _filterStatus!.isNotEmpty)
          'status': _filterStatus,
        if (_userProfile != null && _userProfile!['role'] == 'Room Owner')
          'roomIds': _roomIds.join(','),
      };

      print('Query Parameters: $queryParameters');

      final uri = Uri.parse('$_baseUrl/rreservations')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched Reservations: ${jsonEncode(data)}');
        setState(() {
          _requests = data['reservations'];
          _currentPage = data['currentPage'];
          _totalPages = data['totalPages'];
          _isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to fetch requests. Status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching requests: $error');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  // Update reservation status
  Future<void> _updateStatus(String reservationId, String status) async {
    try {
      final uri = Uri.parse('$_baseUrl/reservations/$reservationId');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchRequests(); // Refresh the list after updating
      } else {
        throw Exception(
            'Failed to update status. Status: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _updateRoomAvailability(String roomId) async {
    try {
      final uri = Uri.parse('$_baseUrl/rooms/$roomId/availability');

      print('Updating room availability for roomId: $roomId'); // Debug log

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Room availability updated successfully'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room availability updated to Fully Booked'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print(
            'Failed to update room availability. Status: ${response.statusCode}'); // Debug log
        throw Exception(
            'Failed to update room availability. Status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating room availability: $error'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  // Delete reservation
  Future<void> _deleteReservation(String reservationId) async {
    try {
      final uri = Uri.parse('$_baseUrl/reservations/$reservationId');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchRequests(); // Refresh the list after deletion
      } else {
        throw Exception(
            'Failed to delete reservation. Status: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  // Fetch user details by userId
  Future<Map<String, dynamic>> _fetchUserDetails(String userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/users/details/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fetch user details. Status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  void _showRequestDetails(
      BuildContext context, Map<String, dynamic> request) async {
    try {
      // Debug: Print the entire reservation data
      print('Reservation Data: $request');

      // Ensure userId is present and not null
      final user = request['user']; // Access the user object
      if (user == null) {
        throw Exception('User data is missing in the reservation data');
      }

      // Extract the userId from the user object
      final userId = user['_id']; // Access the _id field
      if (userId == null) {
        throw Exception('User ID is missing in the reservation data');
      }

      // Debug: Print userId and its type
      print('User ID: $userId (Type: ${userId.runtimeType})');

      // Fetch user details
      final userDetails = await _fetchUserDetails(userId.toString());

      // Debug: Print user details
      print('User Details: $userDetails');

      // Show details in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Request & User Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reservation ID: ${request['reservationId']}'),
                Text('Room Type: ${request['roomType']}'),
                Text('Status: ${request['status']}'),
                const SizedBox(height: 16),
                const Text(
                  'User Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Full Name: ${userDetails['fullName']}'),
                Text('Email: ${userDetails['email']}'),
                Text('Phone: ${userDetails['phone'] ?? 'N/A'}'),
                Text('Address: ${userDetails['address'] ?? 'N/A'}'),
                Text('Age: ${userDetails['age'] ?? 'N/A'}'),
                Text(
                    'Interests: ${userDetails['interests']?.join(', ') ?? 'N/A'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user details: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Requests'),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.orange.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 1200, // Set a maximum width for the container
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Search and Filter Section
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) {
                                      _searchQuery = value;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search by ID or User',
                                      prefixIcon: const Icon(Icons.search),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.filter_list),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: const Text('Pending'),
                                            onTap: () {
                                              _filterStatus = 'Pending';
                                              Navigator.pop(context);
                                              _fetchRequests();
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Approved'),
                                            onTap: () {
                                              _filterStatus = 'Approved';
                                              Navigator.pop(context);
                                              _fetchRequests();
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Rejected'),
                                            onTap: () {
                                              _filterStatus = 'Rejected';
                                              Navigator.pop(context);
                                              _fetchRequests();
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Clear Filters'),
                                            onTap: () {
                                              _filterStatus = null;
                                              Navigator.pop(context);
                                              _fetchRequests();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _requests.length,
                            itemBuilder: (context, index) {
                              final request = _requests[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.shade200,
                                    child: Icon(
                                      Icons.request_page,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                  title: Text(
                                      'Reservation ID: ${request['reservationId']}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Status: ${request['status']}'),
                                      Text('User ID: ${request['user']}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check,
                                            color: Colors.green),
                                        onPressed: () async {
                                          print(
                                              'Updating reservation status and room availability'); // Debug log
                                          print(
                                              'Reservation ID: ${request['reservationId']}'); // Debug log
                                          print(
                                              'Room ID: ${request['roomId']['_id']}'); // Debug log

                                          // Update reservation status to "Approved"
                                          await _updateStatus(
                                              request['reservationId'],
                                              'Approved');

                                          // Update room availability to "Fully Booked"
                                          await _updateRoomAvailability(request[
                                                  'roomId'][
                                              '_id']); // Extract _id from roomId
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () {
                                          _updateStatus(
                                              request['reservationId'],
                                              'Rejected');
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.grey),
                                        onPressed: () {
                                          _deleteReservation(
                                              request['reservationId']);
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    _showRequestDetails(context, request);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        if (_totalPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: _currentPage > 1
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                        _fetchRequests();
                                      }
                                    : null,
                              ),
                              Text('Page $_currentPage of $_totalPages'),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: _currentPage < _totalPages
                                    ? () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                        _fetchRequests();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
