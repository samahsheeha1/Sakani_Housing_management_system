import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart'; // For charts
import '../config.dart'; // For base URL

class ReportsAndStatisticsPage extends StatefulWidget {
  const ReportsAndStatisticsPage({super.key});

  @override
  _ReportsAndStatisticsPageState createState() =>
      _ReportsAndStatisticsPageState();
}

class _ReportsAndStatisticsPageState extends State<ReportsAndStatisticsPage> {
  Map<String, dynamic> userStats = {};
  Map<String, dynamic> roomStats = {};
  Map<String, dynamic> reservationStats = {};

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final baseUrl = getBaseUrl(); // Get the base URL dynamically

    try {
      final userResponse =
          await http.get(Uri.parse('$baseUrl/api/stats/users'));
      final roomResponse =
          await http.get(Uri.parse('$baseUrl/api/stats/rooms'));
      final reservationResponse =
          await http.get(Uri.parse('$baseUrl/api/stats/reservations'));

      if (userResponse.statusCode == 200 &&
          roomResponse.statusCode == 200 &&
          reservationResponse.statusCode == 200) {
        setState(() {
          userStats = json.decode(userResponse.body)['data'] ?? {};
          roomStats = json.decode(roomResponse.body)['data'] ?? {};
          reservationStats =
              json.decode(reservationResponse.body)['data'] ?? {};
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Statistics'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildUserStatistics(),
            const SizedBox(height: 20),
            _buildRoomStatistics(),
            const SizedBox(height: 20),
            _buildReservationStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Text(
        'System Overview',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserStatistics() {
    final List<_UserType> userData = [
      _UserType(
          'Students', userStats['students']?.toDouble() ?? 0, Colors.blue),
      _UserType('Room Owners', userStats['roomOwners']?.toDouble() ?? 0,
          Colors.green),
      _UserType('Admins', userStats['admins']?.toDouble() ?? 0, Colors.purple),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            _buildStatisticItem(
                'Total Users', userStats['totalUsers']?.toString() ?? '0'),
            _buildStatisticItem(
                'Matched Users', userStats['matchedUsers']?.toString() ?? '0'),
            _buildStatisticItem('Available Users',
                userStats['availableUsers']?.toString() ?? '0'),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  PieSeries<_UserType, String>(
                    dataSource: userData,
                    xValueMapper: (_UserType userType, _) => userType.type,
                    yValueMapper: (_UserType userType, _) => userType.count,
                    pointColorMapper: (_UserType userType, _) => userType.color,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomStatistics() {
    final List<_RoomType> roomData = [
      _RoomType('Available', roomStats['availableRooms']?.toDouble() ?? 0,
          Colors.green),
      _RoomType(
          'Occupied', roomStats['occupiedRooms']?.toDouble() ?? 0, Colors.red),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Room Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            _buildStatisticItem(
                'Total Rooms', roomStats['totalRooms']?.toString() ?? '0'),
            _buildStatisticItem('Available Rooms',
                roomStats['availableRooms']?.toString() ?? '0'),
            _buildStatisticItem('Occupied Rooms',
                roomStats['occupiedRooms']?.toString() ?? '0'),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  PieSeries<_RoomType, String>(
                    dataSource: roomData,
                    xValueMapper: (_RoomType roomType, _) => roomType.type,
                    yValueMapper: (_RoomType roomType, _) => roomType.count,
                    pointColorMapper: (_RoomType roomType, _) => roomType.color,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationStatistics() {
    final List<_ReservationStatus> reservationData = [
      _ReservationStatus(
          'Pending',
          reservationStats['pendingReservations']?.toDouble() ?? 0,
          Colors.blue),
      _ReservationStatus(
          'Confirmed',
          reservationStats['confirmedReservations']?.toDouble() ?? 0,
          Colors.green),
      _ReservationStatus(
          'Canceled',
          reservationStats['canceledReservations']?.toDouble() ?? 0,
          Colors.red),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reservation Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            _buildStatisticItem('Total Reservations',
                reservationStats['totalReservations']?.toString() ?? '0'),
            _buildStatisticItem('Pending Reservations',
                reservationStats['pendingReservations']?.toString() ?? '0'),
            _buildStatisticItem('Confirmed Reservations',
                reservationStats['confirmedReservations']?.toString() ?? '0'),
            _buildStatisticItem('Canceled Reservations',
                reservationStats['canceledReservations']?.toString() ?? '0'),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  PieSeries<_ReservationStatus, String>(
                    dataSource: reservationData,
                    xValueMapper: (_ReservationStatus status, _) =>
                        status.status,
                    yValueMapper: (_ReservationStatus status, _) =>
                        status.count,
                    pointColorMapper: (_ReservationStatus status, _) =>
                        status.color,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Data models
class _UserType {
  final String type;
  final double count;
  final Color color;

  _UserType(this.type, this.count, this.color);
}

class _RoomType {
  final String type;
  final double count;
  final Color color;

  _RoomType(this.type, this.count, this.color);
}

class _ReservationStatus {
  final String status;
  final double count;
  final Color color;

  _ReservationStatus(this.status, this.count, this.color);
}
