import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart'; // For map integration
import 'package:latlong2/latlong.dart'; // For LatLng

import '../config.dart';

class AddRoomPage extends StatefulWidget {
  final String token; // Add token parameter

  const AddRoomPage({Key? key, required this.token}) : super(key: key);

  @override
  _AddRoomPageState createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController bedsController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  String? availability = "Available";
  List<File> selectedImages = []; // Store multiple images (for mobile)
  List<Uint8List> selectedImageBytes = []; // Store image bytes (for web)
  LatLng? selectedLocation; // Store selected location from the map
  bool _isUploading = false; // Track upload status

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images.map((image) => File(image.path)).toList());
      });

      // Convert images to Uint8List for web compatibility
      for (var image in images) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          selectedImageBytes.add(bytes); // Store Uint8List for display
        });
      }
    }
  }

  Future<List<String>> uploadImages(List<Uint8List> images) async {
    List<String> imagePaths = [];

    for (var imageBytes in images) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${getBaseUrl()}/api/upload'),
        );
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          imageBytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        final response = await request.send();

        if (response.statusCode == 201) {
          final responseData = await response.stream.bytesToString();
          final jsonResponse = json.decode(responseData);
          final List<dynamic> dynamicPaths = jsonResponse['imagePaths'];
          imagePaths.addAll(dynamicPaths.cast<String>());
        } else {
          throw Exception('Failed to upload image');
        }
      } catch (e) {
        print('Image upload error: $e');
      }
    }

    return imagePaths;
  }

  Future<void> addRoom(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true; // Show loading indicator
    });

    List<String> imageUrls = [];
    if (selectedImageBytes.isNotEmpty) {
      imageUrls = await uploadImages(selectedImageBytes);
    }

    final roomData = {
      "type": typeController.text,
      "price": priceController.text,
      "availability": availability,
      "address": addressController.text,
      "latitude":
          selectedLocation?.latitude ?? double.parse(latitudeController.text),
      "longitude":
          selectedLocation?.longitude ?? double.parse(longitudeController.text),
      "images": imageUrls,
      "beds": int.parse(bedsController.text),
    };
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/rooms'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}", // Pass the token here
        },
        body: json.encode(roomData),
      );

      print('Response status: ${response.statusCode}'); // Debugging
      print('Response body: ${response.body}'); // Debugging

      if (response.statusCode == 201) {
        Navigator.pop(
            context, true); // Return true to refresh the list on success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room added successfully!')),
        );
      } else {
        throw Exception('Failed to add room');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding room: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false; // Hide loading indicator
      });
    }
  }

  // Function to open a map for location selection
  Future<void> _openMapForLocationSelection() async {
    final LatLng? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionPage(),
      ),
    );

    if (selected != null) {
      setState(() {
        selectedLocation = selected;
        latitudeController.text = selected.latitude.toString();
        longitudeController.text = selected.longitude.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Room'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Container(
          width: 600, // Set a fixed width for the form
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Enter Room Details',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: typeController,
                  decoration: InputDecoration(
                    labelText: 'Room Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
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
                  decoration: InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
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
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: bedsController,
                  decoration: InputDecoration(
                    labelText: 'Number of Beds',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bed),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null) {
                      return 'Please enter a valid number of beds';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: availability,
                  decoration: InputDecoration(
                    labelText: 'Availability',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_available),
                  ),
                  items: ["Available", "Fully Booked"]
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      availability = value!;
                    });
                  },
                ),
                SizedBox(height: 20),
                // Latitude and Longitude Input Fields
                TextFormField(
                  controller: latitudeController,
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter latitude';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: longitudeController,
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter longitude';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Button to open map for location selection
                ElevatedButton.icon(
                  onPressed: _openMapForLocationSelection,
                  icon: Icon(Icons.map),
                  label: Text('Select Location on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                if (selectedImageBytes.isNotEmpty)
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImageBytes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(
                            selectedImageBytes[index],
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: pickImages,
                  icon: Icon(Icons.image),
                  label: Text('Select Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : () => addRoom(context),
                  icon: _isUploading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Icon(Icons.add),
                  label: Text('Add Room'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MapSelectionPage extends StatefulWidget {
  @override
  _MapSelectionPageState createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  LatLng? selectedLocation;
  final TextEditingController searchController = TextEditingController();
  final MapController mapController = MapController(); // Add MapController

  // Initial location: An-Najah National University's New Campus
  final LatLng initialLocation = LatLng(32.228852, 35.225242);

  Future<void> searchAndZoom(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location name')),
      );
      return;
    }

    try {
      // Search within Nablus city
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query, Nablus&format=json&addressdetails=1&limit=1');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final double lat = double.parse(results[0]['lat']);
          final double lon = double.parse(results[0]['lon']);
          final LatLng newLocation = LatLng(lat, lon);

          setState(() {
            selectedLocation = newLocation;
          });

          // Zoom and move the map to the new location
          mapController.move(
              newLocation, 16.0); // Zoom level 16 for a closer view
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found in Nablus')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for a location in Nablus...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchAndZoom(searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) =>
                  searchAndZoom(value), // Search on pressing Enter
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController, // Pass the MapController
              options: MapOptions(
                initialCenter: initialLocation, // Set initial location
                initialZoom: 16.0, // Zoom in closer
                onTap: (tapPosition, point) {
                  setState(() {
                    selectedLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                if (selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLocation!,
                        width: 80,
                        height: 80,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedLocation != null) {
            Navigator.pop(context, selectedLocation);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select a location on the map.')),
            );
          }
        },
        backgroundColor: Colors.orange,
        child: Icon(Icons.check),
      ),
    );
  }
}
