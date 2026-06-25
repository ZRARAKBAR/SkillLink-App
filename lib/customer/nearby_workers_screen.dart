import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skilllink_app/customer/view_worker_profile_screen.dart';

class NearbyWorkersScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final List<Map<String, dynamic>>? nearbyWorkers;

  const NearbyWorkersScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
    this.nearbyWorkers,
  });

  @override
  State<NearbyWorkersScreen> createState() => _NearbyWorkersScreenState();
}

class _NearbyWorkersScreenState extends State<NearbyWorkersScreen> {
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _nearbyWorkers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // ---------------- LOCATION ----------------
  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = widget.initialLocation ??
          LatLng(position.latitude, position.longitude);

      await _fetchNearbyWorkers();
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- FETCH WORKERS ----------------
  Future<void> _fetchNearbyWorkers() async {
    try {
      if (widget.nearbyWorkers != null &&
          widget.nearbyWorkers!.isNotEmpty) {
        setState(() => _nearbyWorkers = widget.nearbyWorkers!);
        return;
      }

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .where('isVerified', isEqualTo: true)
          .where('isOnline', isEqualTo: true)
          .where('isBanned', isEqualTo: false)
          .get();

      List<Map<String, dynamic>> workers = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        GeoPoint? location = data['location'] as GeoPoint?;

        if (location != null && _currentLocation != null) {
          double distanceKm = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            location.latitude,
            location.longitude,
          ) /
              1000;

          if (distanceKm <= 10) {
            workers.add({
              'id': doc.id,
              'name': data['fullName'] ?? 'Unknown Worker',
              'email': data['email'] ?? '',
              'phoneNumber': data['phoneNumber'] ?? '',
              'services': List<String>.from(data['services'] ?? []),
              'rating': (data['rating'] ?? 4.5).toDouble(),
              'isVerified': data['isVerified'] ?? false,
              'distance': distanceKm,
              'address': data['address'] ?? '',
            });
          }
        }
      }

      workers.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      if (mounted) {
        setState(() => _nearbyWorkers = workers);
      }
    } catch (e) {
      debugPrint("Firestore error: $e");
    }
  }

  // ---------------- FILTER ----------------
  List<Map<String, dynamic>> get _filteredWorkers {
    if (_searchQuery.isEmpty) return _nearbyWorkers;

    return _nearbyWorkers.where((worker) {
      final name = worker['name'].toString().toLowerCase();
      final services = (worker['services'] as List)
          .map((e) => e.toString().toLowerCase())
          .toList();

      return name.contains(_searchQuery.toLowerCase()) ||
          services.any((s) => s.contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        title: Text(
          'Nearby Workers (${_nearbyWorkers.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchNearbyWorkers,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),

      body: Column(
        children: [

          // 🔍 MODERN SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search workers or services...",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWorkers.isEmpty
                ? _emptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredWorkers.length,
              itemBuilder: (context, index) {
                return _buildWorkerCard(
                    _filteredWorkers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- EMPTY STATE ----------------
  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No workers found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Try different search or expand location",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ---------------- MODERN CARD ----------------
  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final double distance = worker['distance'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // TOP ROW
          Row(
            children: [

              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.person, color: Colors.blue),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        if (worker['isVerified'] == true)
                          const Icon(Icons.verified,
                              color: Colors.green, size: 18),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      worker['address'] ?? "Service Provider",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // CHIPS
          Wrap(
            spacing: 8,
            children: [
              _chip(Icons.star, worker['rating'].toString(),
                  Colors.orange),
              _chip(Icons.location_on,
                  "${distance.toStringAsFixed(1)} km",
                  Colors.blue),
              _chip(Icons.circle, "Online", Colors.green),
            ],
          ),

          const SizedBox(height: 10),

          // SERVICES
          if ((worker['services'] as List).isNotEmpty)
            Wrap(
              spacing: 6,
              children: (worker['services'] as List)
                  .take(3)
                  .map((s) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.toString(),
                  style: const TextStyle(fontSize: 11),
                ),
              ))
                  .toList(),
            ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewWorkerProfileScreen(
                      workerId: worker['id'],
                    ),
                  ),
                );
              },
              child: const Text("View Profile"),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CHIP WIDGET ----------------
  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}