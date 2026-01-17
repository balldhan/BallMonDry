import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class OSMPickerPage extends StatefulWidget {
  final double? lat;
  final double? lng;
  final bool isViewOnly;

  const OSMPickerPage({super.key, this.lat, this.lng, this.isViewOnly = false});

  @override
  State<OSMPickerPage> createState() => _OSMPickerPageState();
}

class _OSMPickerPageState extends State<OSMPickerPage> {
  LatLng _currentPosition = const LatLng(-6.2000, 106.8166); // Default Jakarta
  String _address = "Geser peta untuk memilih lokasi";

  @override
  void initState() {
    super.initState();
    if (widget.lat != null && widget.lng != null) {
      _currentPosition = LatLng(widget.lat!, widget.lng!);
      if (widget.isViewOnly) {
         _address = "Lokasi User"; 
         // Optional: _getAddress(_currentPosition) if we want to reverse geocode again
      }
    }
  }

  Future<void> _getAddress(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _address = "${place.street}, ${place.subLocality}, ${place.locality}";
      });
    } catch (e) {
      print("Error Geocoding: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isViewOnly ? "Lokasi User" : "Pilih Lokasi (OSM)")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15,
              onTap: widget.isViewOnly ? null : (tapPosition, point) {
                setState(() => _currentPosition = point);
                _getAddress(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ballmondry.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_address, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    if (!widget.isViewOnly)
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, {
                          'lat': _currentPosition.latitude,
                          'lng': _currentPosition.longitude,
                          'address': _address,
                        }),
                        child: const Text("Gunakan Alamat Ini"),
                      )
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