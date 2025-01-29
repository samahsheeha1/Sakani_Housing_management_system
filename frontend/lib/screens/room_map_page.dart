import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'room_details_page.dart';

class RoomMapPage extends StatefulWidget {
  final List<Map<String, dynamic>> rooms;
  final String token;

  const RoomMapPage({super.key, required this.rooms, required this.token});

  @override
  _RoomMapPageState createState() => _RoomMapPageState();
}

class _RoomMapPageState extends State<RoomMapPage> {
  late final MapController mapController;
  late List<Map<String, dynamic>> sortedRooms;
  final TextEditingController searchController = TextEditingController();
  LatLng? searchedLocation;

  final LatLng haramAlQadeemLocation = LatLng(32.220112, 35.244285);
  final LatLng haramAlJadeedLocation = LatLng(32.228266, 35.222254);

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    sortedRooms = List<Map<String, dynamic>>.from(widget.rooms);
    calculateDistances();
  }

  void calculateDistances() {
    const Distance distance = Distance();

    for (var room in sortedRooms) {
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

  Future<void> searchAndZoom(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location name')),
      );
      return;
    }

    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query, Nablus&format=json&addressdetails=1&limit=1');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final double lat = double.parse(results[0]['lat']);
          final double lon = double.parse(results[0]['lon']);

          setState(() {
            searchedLocation = LatLng(lat, lon);
          });

          mapController.move(LatLng(lat, lon), 16.0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching location data')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred while searching')),
      );
    }
  }

  Widget _buildCustomMarker(Map<String, dynamic> room) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                '\$${room['price']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'To Al-Qadeem: ${room['distanceToHaramAlQadeem']} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
              Text(
                'To Al-Jadeed: ${room['distanceToHaramAlJadeed']} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 30.0,
        ),
      ],
    );
  }

  Widget _buildUniversityMarker(String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Icon(
          icon,
          color: color,
          size: 30.0,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Map'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for a location...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchAndZoom(searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: sortedRooms.isEmpty
                ? const Center(
                    child: Text(
                      "No rooms available",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: sortedRooms.isNotEmpty
                          ? LatLng(
                              sortedRooms[0]['latitude'],
                              sortedRooms[0]['longitude'],
                            )
                          : haramAlQadeemLocation,
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      ),
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 120,
                          size: const Size(40, 40),
                          markers: [
                            ...sortedRooms.map((room) {
                              return Marker(
                                point:
                                    LatLng(room['latitude'], room['longitude']),
                                width: 100,
                                height: 100,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RoomDetailsPage(
                                        room: room,
                                        token: widget.token,
                                      ),
                                    ),
                                  ),
                                  child: _buildCustomMarker(room),
                                ),
                              );
                            }),
                            Marker(
                              point: haramAlQadeemLocation,
                              width: 100,
                              height: 100,
                              child: _buildUniversityMarker(
                                'جامعة النجاح الحرم القديم',
                                Colors.blue,
                                Icons.school,
                              ),
                            ),
                            Marker(
                              point: haramAlJadeedLocation,
                              width: 100,
                              height: 100,
                              child: _buildUniversityMarker(
                                'جامعة النجاح الحرم الجديد',
                                Colors.green,
                                Icons.school,
                              ),
                            ),
                            if (searchedLocation != null)
                              Marker(
                                point: searchedLocation!,
                                width: 100,
                                height: 100,
                                child: _buildUniversityMarker(
                                  'Searched Location',
                                  Colors.purple,
                                  Icons.location_on,
                                ),
                              ),
                          ],
                          builder: (context, markers) {
                            return Container(
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                markers.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
