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

        GeoPoint? location;
        if (data['location'] is GeoPoint) {
          location = data['location'];
        }

        if (location != null && _currentLocation != null) {
          double distance = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            location.latitude,
            location.longitude,
          ) /
              1000;

          if (distance <= 10) {
            workers.add({
              'id': doc.id,
              'name': data['fullName'] ?? 'Unknown Worker',
              'email': data['email'] ?? '',
              'phoneNumber': data['phoneNumber'] ?? '',
              'services': List<String>.from(data['services'] ?? []),
              'rating': (data['rating'] ?? 0).toDouble(),
              'isVerified': data['isVerified'] ?? false,
              'distance': distance,
              'address': data['address'] ?? '',
            });
          }
        }
      }

      workers.sort(
            (a, b) => (a['distance'] as double)
            .compareTo(b['distance'] as double),
      );

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
      appBar: AppBar(
        title: Text('Nearby Workers (${_nearbyWorkers.length})'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _fetchNearbyWorkers,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search workers...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value),
            ),
          ),

          // LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWorkers.isEmpty
                ? const Center(
              child: Text("No workers found"),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredWorkers.length,
              itemBuilder: (context, index) {
                final worker = _filteredWorkers[index];
                return _buildWorkerCard(worker);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CARD ----------------
  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(worker['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "⭐ ${worker['rating']}",
            ),
            Text(
              "${(worker['distance'] as double).toStringAsFixed(1)} km away",
            ),
          ],
        ),
        trailing: worker['isVerified']
            ? const Icon(Icons.verified, color: Colors.green)
            : const Icon(Icons.work_outline),

         onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewWorkerProfileScreen(
                workerId: worker['id'],
              ),
            ),
          );
        },
      ),
    );
  }
}