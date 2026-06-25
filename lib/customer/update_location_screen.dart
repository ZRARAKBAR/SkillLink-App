import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UpdateLocationScreen extends StatefulWidget {
  const UpdateLocationScreen({super.key});

  @override
  State<UpdateLocationScreen> createState() =>
      _UpdateLocationScreenState();
}

class _UpdateLocationScreenState
    extends State<UpdateLocationScreen> {
  bool _loading = false;
  String? _address;
  double? _lat;
  double? _lng;

  final Color primary = const Color(0xFFC6FF00);
  final Color dark = const Color(0xFF121212);

  Future<void> _getLocation() async {
    setState(() => _loading = true);

    try {
      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw "Location services are disabled";
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw "Location permission permanently denied";
      }

      Position position =
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lat = position.latitude;
      _lng = position.longitude;

      List<Placemark> placemarks =
      await placemarkFromCoordinates(
        _lat!,
        _lng!,
      );

      Placemark place = placemarks.first;

      _address =
      "${place.street}, ${place.locality}, ${place.country}";

      await _saveToFirestore();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _loading = false);
  }

  Future<void> _saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({
      "location": {
        "lat": _lat,
        "lng": _lng,
        "address": _address,
        "updatedAt": FieldValue.serverTimestamp(),
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: dark,
        title: const Text("Update Location"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Current Location",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _address ?? "No location fetched yet",
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (_lat != null && _lng != null)
                    Text(
                      "Lat: $_lat\nLng: $_lng",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
                    : const Icon(Icons.my_location),

                label: Text(
                  _loading
                      ? "Fetching..."
                      : "Get Current Location",
                ),

                onPressed:
                _loading ? null : _getLocation,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Your location will be used to show nearby jobs and workers",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}