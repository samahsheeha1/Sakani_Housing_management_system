import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../config.dart';
import 'edit_room_owner_page.dart'; // Import the edit page

class ManageRoomOwnerPage extends StatefulWidget {
  @override
  _ManageRoomOwnerPageState createState() => _ManageRoomOwnerPageState();
}

class _ManageRoomOwnerPageState extends State<ManageRoomOwnerPage> {
  List<dynamic> roomOwners = [];
  List<dynamic> filteredRoomOwners = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRoomOwners();
  }

  Future<void> fetchRoomOwners() async {
    final response =
        await http.get(Uri.parse('${getBaseUrl()}/api/users/room-owners'));
    if (response.statusCode == 200) {
      setState(() {
        roomOwners = json.decode(response.body);
        filteredRoomOwners = roomOwners; // Initialize filtered list
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load room owners');
    }
  }

  Future<void> deleteRoomOwner(String id) async {
    final response = await http
        .delete(Uri.parse('${getBaseUrl()}/api/users/room-owners/$id'));
    if (response.statusCode == 200) {
      fetchRoomOwners(); // Refresh the list
    } else {
      throw Exception('Failed to delete room owner');
    }
  }

  void showRoomOwnerDetails(BuildContext context, dynamic owner) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.orange.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              'Room Owner Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.person, 'Full Name', owner['fullName']),
              _buildDetailRow(Icons.email, 'Email', owner['email']),
              _buildDetailRow(Icons.phone, 'Phone', owner['phone']),
              _buildDetailRow(Icons.location_on, 'Address', owner['address']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditRoomOwnerPage(owner: owner),
                  ),
                );
                if (result == true) {
                  fetchRoomOwners(); // Refresh the list after update
                }
              },
              child: Text(
                'Edit',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade700),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _filterRoomOwners(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredRoomOwners =
            roomOwners; // Show all room owners if query is empty
      } else {
        filteredRoomOwners = roomOwners
            .where((owner) =>
                owner['fullName'].toLowerCase().contains(query.toLowerCase()) ||
                owner['email'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb =
        MediaQuery.of(context).size.width > 600; // Check if running on web

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Room Owners'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Center(
        child: Container(
          width: isWeb
              ? 800
              : double.infinity, // Fixed width for web, full width for mobile
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon:
                        Icon(Icons.search, color: Colors.orange.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.orange.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.orange.shade700),
                    ),
                  ),
                  onChanged: _filterRoomOwners,
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredRoomOwners.isEmpty
                        ? Center(
                            child: Text(
                              'No matching room owners found.',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredRoomOwners.length,
                            itemBuilder: (context, index) {
                              final owner = filteredRoomOwners[index];
                              return Card(
                                margin: EdgeInsets.all(8.0),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading:
                                      Icon(Icons.person, color: Colors.orange),
                                  title: Text(
                                    owner['fullName'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(owner['email']),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditRoomOwnerPage(
                                                      owner: owner),
                                            ),
                                          );
                                          if (result == true) {
                                            fetchRoomOwners(); // Refresh the list after update
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            deleteRoomOwner(owner['_id']),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    showRoomOwnerDetails(context,
                                        owner); // Show details in a dialog
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
