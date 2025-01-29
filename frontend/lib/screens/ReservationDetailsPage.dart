import 'package:flutter/material.dart';

class ReservationDetailsPage extends StatelessWidget {
  final String reservationId;
  final String status;
  final String date;
  final String roomDetails;

  const ReservationDetailsPage({
    super.key,
    required this.reservationId,
    required this.status,
    required this.date,
    required this.roomDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width:
              MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
          padding: const EdgeInsets.all(20.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Icon
              Center(
                child: Icon(
                  status == 'Approved'
                      ? Icons.check_circle
                      : status == 'Rejected'
                          ? Icons.cancel
                          : Icons.hourglass_empty,
                  size: 80,
                  color: status == 'Approved'
                      ? Colors.green
                      : status == 'Rejected'
                          ? Colors.red
                          : Colors.orange,
                ),
              ),
              const SizedBox(height: 20),

              // Reservation Details
              _buildDetailRow(
                  Icons.assignment, 'Reservation ID:', reservationId),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.date_range, 'Date Reserved:', date),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.info_outline,
                'Status:',
                status,
                color: status == 'Approved'
                    ? Colors.green
                    : status == 'Rejected'
                        ? Colors.red
                        : Colors.orange,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.hotel, 'Room Details:', roomDetails),
              const SizedBox(height: 30),

              // Back Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Back to Reservations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildDetailRow(IconData icon, String title, String value,
      {Color color = Colors.black87}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text at the top
      children: [
        Icon(icon, color: Colors.orange.shade700),
        const SizedBox(width: 10),
        Expanded(
          flex: 1, // Allow title to occupy fixed space
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          flex: 2, // Allow value to occupy more space
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
            ),
            softWrap: true, // Allow text to wrap to the next line
            overflow: TextOverflow.visible, // Ensure full text is visible
          ),
        ),
      ],
    );
  }
}
