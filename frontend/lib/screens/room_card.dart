import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../config.dart';

class RoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onDetailsPressed;
  final VoidCallback onSelectPressed;
  final String? additionalInfo; // Add this parameter for extra information

  const RoomCard({
    super.key,
    required this.room,
    required this.onDetailsPressed,
    required this.onSelectPressed,
    this.additionalInfo, // Make it optional
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CarouselSlider(
                options: CarouselOptions(
                  height: double.infinity,
                  aspectRatio: 1.0,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  viewportFraction: 1.0,
                ),
                items: (room['images'] as List<dynamic>).map<Widget>((image) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
            ),
            const SizedBox(height: 10),
            Text(
              room['type'] ?? 'Unknown Room',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              room['price'] != null
                  ? '${room['price']}/month'
                  : 'Price not specified',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Availability: ${room['availability'] ?? 'Unknown'}',
              style: TextStyle(
                fontSize: 12,
                color: room['availability'] == 'Available'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Location: ${room['address'] ?? 'Not specified'}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
            if (additionalInfo !=
                null) // Display additional information if available
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  additionalInfo!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onSelectPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Select',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                OutlinedButton(
                  onPressed: onDetailsPressed,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    side: BorderSide(color: Colors.orange.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
