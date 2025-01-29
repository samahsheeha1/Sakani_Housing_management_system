import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package
import 'dart:math';
import 'room_reservation_page.dart';
import '../config.dart'; // Ensure this is imported for getBaseUrl()

class RoomDetailsPage extends StatelessWidget {
  final Map<String, dynamic> room;
  final String token; // Add token as a required parameter

  const RoomDetailsPage({super.key, required this.room, required this.token});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          room['type'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Stack(
        children: [
          // Bubble Animation Background
          const BubbleAnimationBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Room Type Title
                  Text(
                    room['type'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Image Slider with Dots Indicator
                  SizedBox(
                    width: isWeb ? 600 : screenWidth * 0.9,
                    child: Column(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 300,
                            enlargeCenterPage: true,
                            enableInfiniteScroll: true,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 4),
                            viewportFraction: 0.8,
                            aspectRatio: 16 / 9,
                          ),
                          items: (room['images'] as List<dynamic>)
                              .map<Widget>((image) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: '${getBaseUrl()}/${image.toString()}',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        // Dots Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: (room['images'] as List<dynamic>)
                              .asMap()
                              .entries
                              .map(
                            (entry) {
                              return Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange
                                      .withOpacity(entry.key == 0 ? 1.0 : 0.3),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Room Details
                  SizedBox(
                    width: isWeb ? 500 : screenWidth * 0.9,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.attach_money,
                                  color: Colors.orange),
                              title: const Text(
                                'Price',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                room['price'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(
                                room['availability'] == 'Available'
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: room['availability'] == 'Available'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: const Text(
                                'Availability',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                room['availability'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.location_on,
                                  color: Colors.orange),
                              title: const Text(
                                'Location',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                room['address'] ?? 'Location not specified',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const Divider(),
                            const ListTile(
                              leading: Icon(Icons.info, color: Colors.orange),
                              title: Text(
                                'Additional Info',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Contact administration for more details about this room.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reserve Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to RoomReservationPage with token
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomReservationPage(
                            room: room,
                            token: token, // Pass the token
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.book_online),
                    label: const Text('Proceed'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      backgroundColor: Colors.orange.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bubble Animation Background Widget
class BubbleAnimationBackground extends StatelessWidget {
  const BubbleAnimationBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(15, (index) {
        final random = Random();
        return AnimatedPositioned(
          duration: Duration(seconds: random.nextInt(5) + 5),
          curve: Curves.easeInOut,
          top: random.nextDouble() * MediaQuery.of(context).size.height,
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          child: Container(
            width: random.nextDouble() * 50 + 20,
            height: random.nextDouble() * 50 + 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orangeAccent.withOpacity(0.2),
            ),
          ),
        );
      }),
    );
  }
}
