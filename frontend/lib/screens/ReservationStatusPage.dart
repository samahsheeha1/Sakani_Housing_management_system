import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'ReservationDetailsPage.dart';

class ReservationStatusPage extends StatefulWidget {
  final String token;

  const ReservationStatusPage({super.key, required this.token});

  @override
  _ReservationStatusPageState createState() => _ReservationStatusPageState();
}

class _ReservationStatusPageState extends State<ReservationStatusPage> {
  late Future<List<Map<String, dynamic>>> _reservations;
  final String _baseUrl = '${getBaseUrl()}/api';
  String? _notificationMessage;

  Future<List<Map<String, dynamic>>> fetchReservations() async {
    final url = Uri.parse('$_baseUrl/reservations');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((reservation) {
        final room = reservation['roomId'];
        return {
          '_id': reservation['_id'], // Use '_id'
          'date': reservation['createdAt'].substring(0, 10),
          'status': reservation['status'],
          'roomType': reservation['roomType'],
          'roomDetails': room != null
              ? '${room['type']}, ${room['price']}, ${room['availability']}, ${room['address']}'
              : 'Room details unavailable',
        };
      }).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    final url = Uri.parse('$_baseUrl/reservations/$reservationId/cancel');
    final response = await http.patch(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _reservations = fetchReservations();
        _notificationMessage = 'Reservation canceled successfully.';
      });
    } else {
      throw Exception('Failed to cancel reservation');
    }
  }

  void _handleCancel(String reservationId, String status) {
    if (status == 'Pending') {
      cancelReservation(reservationId);
    } else {
      setState(() {
        _notificationMessage =
            'You can only cancel reservations that are in "Pending" status.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _reservations = fetchReservations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Reservations'),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_notificationMessage != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _notificationMessage!,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.orange),
                    onPressed: () {
                      setState(() {
                        _notificationMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _reservations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No reservations found.'));
                } else {
                  final reservations = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            reservation['status'] == 'Approved'
                                ? Icons.check_circle
                                : reservation['status'] == 'Rejected'
                                    ? Icons.cancel
                                    : reservation['status'] == 'Canceled'
                                        ? Icons.cancel
                                        : Icons.hourglass_empty,
                            color: reservation['status'] == 'Approved'
                                ? Colors.green
                                : reservation['status'] == 'Rejected'
                                    ? Colors.red
                                    : reservation['status'] == 'Canceled'
                                        ? Colors.red
                                        : Colors.orange,
                          ),
                          title: Text(
                              'Reservation ID: ${reservation['_id']}'), // Use '_id'
                          subtitle: Text('Date: ${reservation['date']}'),
                          trailing: reservation['status'] == 'Pending'
                              ? IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.orange),
                                  onPressed: () {
                                    _handleCancel(reservation['_id'],
                                        reservation['status']); // Use '_id'
                                  },
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReservationDetailsPage(
                                  reservationId:
                                      reservation['_id'], // Use '_id'
                                  status: reservation['status'],
                                  date: reservation['date'],
                                  roomDetails: reservation['roomDetails'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
