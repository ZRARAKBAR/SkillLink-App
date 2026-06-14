import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skilllink_app/services/location_service.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    final position = await LocationService.getCurrentLocation();

    if (position == null) {
      setState(() => _loading = false);
      return;
    }

    _currentLocation = LocationService.toLatLng(position);

    await _loadWorkers();

    setState(() => _loading = false);
  }

  Future<void> _loadWorkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "worker")
        .where("isVerified", isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data["lat"] != null && data["lng"] != null) {
        final LatLng position = LatLng(data["lat"], data["lng"]);

        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(
              title: data["fullName"] ?? "Worker",
              snippet: (data["services"] ?? []).toString(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map"),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: const Color(0xFFC6FF00),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null
          ? const Center(child: Text("Location not available"))
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation!,
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}