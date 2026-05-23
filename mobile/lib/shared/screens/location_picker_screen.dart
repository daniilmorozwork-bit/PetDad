import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Екран вибору географічної точки.
/// Користувач натискає на карту та підтверджує вибране місце.
class LocationPickerScreen extends StatefulWidget {
  final LatLng initialPoint;
  final String title;
  final String instructionText;

  const LocationPickerScreen({
    super.key,
    required this.initialPoint,
    required this.title,
    required this.instructionText,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  /// Оновлює вибрану точку після натискання на карту.
  void _selectPoint(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPoint = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initialPoint,
              initialZoom: 15,
              onTap: _selectPoint,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.petdad.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 54,
                    height: 54,
                    child: const Icon(
                      Icons.location_pin,
                      size: 54,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.instructionText,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Вибране місце',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedPoint.latitude.toStringAsFixed(6)}, '
                      '${_selectedPoint.longitude.toStringAsFixed(6)}',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(_selectedPoint);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Підтвердити точку'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}