import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'add_room_page.dart';
import '../services/api_service.dart'; // Import the ApiService

class ManageRoomsPage extends StatefulWidget {
  final String token; // Add token parameter

  const ManageRoomsPage({Key? key, required this.token}) : super(key: key);

  @override
  _ManageRoomsPageState createState() => _ManageRoomsPageState();
}

class _ManageRoomsPageState extends State<ManageRoomsPage> {
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> filteredRooms = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String searchBy = 'type'; // Default search criteria
  bool isSearchExpanded = false; // For mobile search bar animation
  String userRole = ''; // Store user role
  String userId = ''; // Store user ID

  @override
  void initState() {
    super.initState();
    fetchUserProfile(); // Fetch user profile to get role and ID
  }

  // Fetch user profile to determine role and ID
  Future<void> fetchUserProfile() async {
    try {
      final profile = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        userRole = profile['role'];
        userId = profile['_id'];
      });
      fetchRooms(); // Fetch rooms after getting user role and ID
    } catch (e) {
      print('Error fetching user profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch rooms with optional search query
  Future<void> fetchRooms({String? query}) async {
    try {
      String url;
      if (userRole == 'Admin') {
        url = query != null
            ? '${getBaseUrl()}/api/rooms/all/search?query=$query&searchBy=$searchBy'
            : '${getBaseUrl()}/api/rooms/all';
      } else if (userRole == 'Room Owner') {
        url = query != null
            ? '${getBaseUrl()}/api/rooms/all/search?query=$query&searchBy=$searchBy&owner=$userId'
            : '${getBaseUrl()}/api/rooms/all?owner=$userId';
      } else {
        throw Exception('Unauthorized access');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}', // Pass the token here
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          rooms = List<Map<String, dynamic>>.from(json.decode(response.body));
          filteredRooms =
              List.from(rooms); // Initialize filteredRooms with all rooms
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch rooms');
      }
    } catch (e) {
      print('Error fetching rooms: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Delete a room
  Future<void> deleteRoom(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${getBaseUrl()}/api/rooms/$id'),
        headers: {
          'Authorization': 'Bearer ${widget.token}', // Pass the token here
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          rooms.removeWhere((room) => room['_id'] == id);
          filteredRooms.removeWhere((room) => room['_id'] == id);
        });
      } else {
        throw Exception('Failed to delete room');
      }
    } catch (e) {
      print('Error deleting room: $e');
    }
  }

  // Edit a room
  void _editRoom(Map<String, dynamic> room) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController typeController =
        TextEditingController(text: room['type']);
    final TextEditingController priceController =
        TextEditingController(text: room['price']);
    final TextEditingController addressController =
        TextEditingController(text: room['address']);
    final TextEditingController bedsController =
        TextEditingController(text: room['beds'].toString());
    String availability = room['availability'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Room - ${room['type']}'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: typeController,
                    decoration: InputDecoration(labelText: 'Room Type'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the room type';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the price';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Address'),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: bedsController,
                    decoration: InputDecoration(labelText: 'Number of Beds'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: availability,
                    decoration: InputDecoration(labelText: 'Availability'),
                    items: ["Available", "Fully Booked"]
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      availability = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Update room in the backend
                  try {
                    final response = await http.put(
                      Uri.parse('${getBaseUrl()}/api/rooms/${room['_id']}'),
                      headers: {
                        'Authorization':
                            'Bearer ${widget.token}', // Pass the token here
                        'Content-Type': 'application/json',
                      },
                      body: json.encode({
                        "type": typeController.text,
                        "price": priceController.text,
                        "availability": availability,
                        "address": addressController.text,
                        "latitude": room['latitude'],
                        "longitude": room['longitude'],
                        "images": room['images'], // Existing images
                        "beds": int.parse(bedsController.text),
                      }),
                    );

                    if (response.statusCode == 200) {
                      final updatedRoom = json.decode(response.body);
                      setState(() {
                        final index = rooms
                            .indexWhere((r) => r['_id'] == updatedRoom['_id']);
                        if (index != -1) {
                          rooms[index] = updatedRoom;
                          filteredRooms[index] = updatedRoom;
                        }
                      });

                      Navigator.pop(context);
                      fetchRooms(); // Refresh the room list
                    } else {
                      throw Exception('Failed to update room');
                    }
                  } catch (e) {
                    print('Error updating room: $e');
                  }
                }
              },
              child: Text('Update'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // View room details
  void _viewRoomDetails(Map<String, dynamic> room) {
    int currentImageIndex = 0; // Track the current image index

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width > 600 ? 600 : null,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (room['images'].isNotEmpty)
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: room['images'].length,
                        onPageChanged: (index) {
                          setState(() {
                            currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                '${getBaseUrl()}/${room['images'][index]}',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            room['images'].length,
                            (index) => Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentImageIndex == index
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 10),
              Text(
                '${room['type']} - \$${room['price']}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                  SizedBox(width: 5),
                  Text(
                    'Availability: ${room['availability']}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Address: ${room['address']}',
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.visible, // Allow text to wrap
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.bed, size: 16, color: Colors.green),
                  SizedBox(width: 5),
                  Text(
                    'Beds: ${room['beds']}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter rooms based on search query
  void _filterRooms(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredRooms = List.from(rooms);
      });
    } else {
      setState(() {
        filteredRooms = rooms.where((room) {
          final value = room[searchBy].toString().toLowerCase();
          return value.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  // Clear search
  void _clearSearch() {
    searchController.clear();
    _filterRooms('');
  }

  // Build the web layout
  Widget _buildWebLayout() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Search Bar for Web
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                    ),
                    onChanged: _filterRooms,
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: searchBy,
                  onChanged: (value) {
                    setState(() {
                      searchBy = value!;
                      _filterRooms(searchController.text);
                    });
                  },
                  items: ['type', 'price', 'availability']
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text('Search by $value'),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          // List of Rooms in Grid
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            room['images'].isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(15)),
                                    child: Image.network(
                                      '${getBaseUrl()}/${room['images'][0]}',
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image, size: 100),
                                  ),
                            ListTile(
                              title: Text(
                                '${room['type']} - ${room['price']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Availability: ${room['availability']}\nAddress: ${room['address']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editRoom(room),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => deleteRoom(room['_id']),
                                  ),
                                ],
                              ),
                              onTap: () => _viewRoomDetails(room),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Build the mobile layout
  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Wrap the AnimatedContainer in a SingleChildScrollView
          SingleChildScrollView(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height:
                  isSearchExpanded ? 120 : 60, // Adjusted height for dropdown
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: _clearSearch,
                            ),
                          ),
                          onChanged: _filterRooms,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                            isSearchExpanded ? Icons.close : Icons.filter_list),
                        onPressed: () {
                          setState(() {
                            isSearchExpanded = !isSearchExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                  if (isSearchExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DropdownButton<String>(
                        value: searchBy,
                        onChanged: (value) {
                          setState(() {
                            searchBy = value!;
                            _filterRooms(searchController.text);
                          });
                        },
                        items: ['type', 'price', 'availability'].map((filter) {
                          return DropdownMenuItem<String>(
                            value: filter,
                            child: Text('Search by $filter'),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Add space between the search criteria and the first room
          SizedBox(height: 16), // Adjust the height as needed
          // List of Rooms
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 10),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            room['images'].isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(15)),
                                    child: Image.network(
                                      '${getBaseUrl()}/${room['images'][0]}',
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image, size: 100),
                                  ),
                            ListTile(
                              title: Text(
                                '${room['type']} - ${room['price']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Availability: ${room['availability']}\nAddress: ${room['address']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editRoom(room),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => deleteRoom(room['_id']),
                                  ),
                                ],
                              ),
                              onTap: () => _viewRoomDetails(room),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Rooms'),
        actions: [
          // Add Room Button
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddRoomPage(token: widget.token), // Pass the token here
                ),
              );
              fetchRooms(); // Refresh the room list after adding a new room
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Web layout
            return _buildWebLayout();
          } else {
            // Mobile layout
            return _buildMobileLayout();
          }
        },
      ),
    );
  }
}
