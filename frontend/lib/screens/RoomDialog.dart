import 'package:flutter/material.dart';

class RoomDialog extends StatelessWidget {
  final Function(
          String, String, String, String, double, double, List<String>, int)
      onSubmit;

  RoomDialog({required this.onSubmit});

  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _bedsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add/Edit Room'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
                controller: _typeController,
                decoration: InputDecoration(labelText: 'Type')),
            TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price')),
            TextField(
                controller: _availabilityController,
                decoration: InputDecoration(labelText: 'Availability')),
            TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address')),
            TextField(
                controller: _latitudeController,
                decoration: InputDecoration(labelText: 'Latitude')),
            TextField(
                controller: _longitudeController,
                decoration: InputDecoration(labelText: 'Longitude')),
            TextField(
                controller: _bedsController,
                decoration: InputDecoration(labelText: 'Beds')),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Submit'),
          onPressed: () {
            onSubmit(
              _typeController.text,
              _priceController.text,
              _availabilityController.text,
              _addressController.text,
              double.parse(_latitudeController.text),
              double.parse(_longitudeController.text),
              [], // Images can be handled separately
              int.parse(_bedsController.text),
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
