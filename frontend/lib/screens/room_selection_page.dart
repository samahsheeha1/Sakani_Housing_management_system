import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'room_card.dart';
import 'room_map_page.dart';
import 'room_details_page.dart';
import 'room_reservation_page.dart';

class RoomSelectionPage extends StatefulWidget {
  final String token; // Token for authentication
  final List<Map<String, dynamic>> rooms; // Rooms passed from HomePage

  const RoomSelectionPage({
    super.key,
    required this.token,
    required this.rooms,
  });

  @override
  _RoomSelectionPageState createState() => _RoomSelectionPageState();
}

class _RoomSelectionPageState extends State<RoomSelectionPage> {
  final LatLng haramAlQadeemLocation = LatLng(32.220112, 35.244285);
  final LatLng haramAlJadeedLocation = LatLng(32.228266, 35.222254);

  List<Map<String, dynamic>> filteredRooms = [];
  String searchQuery = "";
  String selectedFilter = "All";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use the rooms passed from HomePage
    filteredRooms = List<Map<String, dynamic>>.from(widget.rooms);
    calculateDistances();
  }

  void calculateDistances() {
    const Distance distance = Distance();
    for (var room in filteredRooms) {
      room['distanceToHaramAlQadeem'] = distance
          .as(
            LengthUnit.Kilometer,
            LatLng(room['latitude'], room['longitude']),
            haramAlQadeemLocation,
          )
          .toStringAsFixed(2);

      room['distanceToHaramAlJadeed'] = distance
          .as(
            LengthUnit.Kilometer,
            LatLng(room['latitude'], room['longitude']),
            haramAlJadeedLocation,
          )
          .toStringAsFixed(2);
    }
  }

  void _recommendRooms(String filter) {
    if (filter == "Closest to An-Najah University Old Campus") {
      filteredRooms.sort((a, b) {
        final distanceA = double.parse(a['distanceToHaramAlQadeem']);
        final distanceB = double.parse(b['distanceToHaramAlQadeem']);
        return distanceA.compareTo(distanceB);
      });
    } else if (filter == "Closest to An-Najah University New Campus") {
      filteredRooms.sort((a, b) {
        final distanceA = double.parse(a['distanceToHaramAlJadeed']);
        final distanceB = double.parse(b['distanceToHaramAlJadeed']);
        return distanceA.compareTo(distanceB);
      });
    } else if (filter == "Cheapest") {
      filteredRooms.sort((a, b) {
        final priceA = int.parse(a['price'].replaceAll('\$', ''));
        final priceB = int.parse(b['price'].replaceAll('\$', ''));
        return priceA.compareTo(priceB);
      });
    } else {
      filteredRooms = List<Map<String, dynamic>>.from(widget.rooms);
    }
    setState(() {
      selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Selection'),
        backgroundColor: Colors.orange,
        actions: [
          DropdownButton<String>(
            value: selectedFilter,
            items: const [
              DropdownMenuItem(value: "All", child: Text("All")),
              DropdownMenuItem(
                  value: "Closest to An-Najah University Old Campus",
                  child: Text("Closest to An-Najah University Old Campus")),
              DropdownMenuItem(
                  value: "Closest to An-Najah University New Campus",
                  child: Text("Closest to An-Najah University New Campus")),
              DropdownMenuItem(value: "Cheapest", child: Text("Cheapest")),
            ],
            onChanged: (value) {
              if (value != null) {
                _recommendRooms(value);
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade200, Colors.orange.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search by Type
              Center(
                child: SizedBox(
                  width: isWeb ? 400 : screenWidth * 0.9,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filteredRooms = widget.rooms.where((room) {
                          return searchQuery.isEmpty ||
                              room['type']
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase());
                        }).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by room type...',
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.orange),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // View Rooms on Map Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomMapPage(
                          rooms: filteredRooms,
                          token: widget.token, // Pass token to map page
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('View Rooms on Map'),
                ),
              ),
              const SizedBox(height: 20),

              // Room Cards
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWeb ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredRooms.length,
                itemBuilder: (context, index) {
                  final room = filteredRooms[index];
                  return RoomCard(
                    room: room,
                    additionalInfo:
                        'To Al-Qadeem: ${room['distanceToHaramAlQadeem']} km\n'
                        'To Al-Jadeed: ${room['distanceToHaramAlJadeed']} km',
                    onDetailsPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailsPage(
                            room: room,
                            token: widget.token, // Pass token
                          ),
                        ),
                      );
                    },
                    onSelectPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomReservationPage(
                            room: room,
                            token: widget.token, // Pass token
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
