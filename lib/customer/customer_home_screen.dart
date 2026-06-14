// ======================= PROFESSIONAL CUSTOMER HOME SCREEN =======================
// Replace your full CustomerHomeScreen.dart with this code
// Modern inDrive-inspired UI
// Clean + Professional + Minimal Design

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:skilllink_app/auth/login_screen.dart';
import 'package:skilllink_app/customer/post_task_screen.dart';
import 'package:skilllink_app/customer/nearby_workers_screen.dart';
import 'package:skilllink_app/models/user_model.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {

  // ================= COLORS =================

  final Color primaryColor = const Color(0xFFC6FF00);
  final Color darkColor = const Color(0xFF121212);
  final Color backgroundColor = const Color(0xFFF7F7F7);

  // ================= VARIABLES =================

  int _bottomIndex = 0;

  UserModel? _currentUser;

  String _userName = "User";
  String _userEmail = "user@email.com";

  LatLng? _currentLocation;

  GoogleMapController? _mapController;

  bool _isLoading = true;

  List<Map<String, dynamic>> _nearbyWorkers = [];

  final List<Map<String, dynamic>> _services = [
    {"name": "Electrician", "icon": Icons.bolt},
    {"name": "Plumber", "icon": Icons.water_drop},
    {"name": "Painter", "icon": Icons.format_paint},
    {"name": "Cleaner", "icon": Icons.cleaning_services},
    {"name": "AC Repair", "icon": Icons.ac_unit},
    {"name": "Carpenter", "icon": Icons.handyman},
  ];

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentLocation();
    await _loadUserData();
    await _loadNearbyWorkers();
  }

  // ================= LOCATION =================

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ================= USER =================

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {

          _currentUser =
              UserModel.fromMap(doc.data() as Map<String, dynamic>);

          setState(() {
            _userName = _currentUser!.fullName;
            _userEmail = _currentUser!.email;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ================= WORKERS =================

  Future<void> _loadNearbyWorkers() async {

    if (_currentLocation == null) return;

    try {

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .limit(10)
          .get();

      List<Map<String, dynamic>> workers = [];

      for (var doc in snapshot.docs) {

        Map<String, dynamic> data =
        doc.data() as Map<String, dynamic>;

        GeoPoint? geo = data['location'];

        if (geo != null) {

          double distance = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            geo.latitude,
            geo.longitude,
          );

          workers.add({
            'fullName': data['fullName'] ?? 'Worker',
            'distance': distance,
            'rating': data['rating'] ?? 4.5,
          });
        }
      }

      workers.sort((a, b) =>
          (a['distance'] as double)
              .compareTo(b['distance'] as double));

      setState(() {
        _nearbyWorkers = workers;
      });

    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ================= LOGOUT =================

  Future<void> _logout() async {

    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: backgroundColor,

      drawer: _buildDrawer(),

      floatingActionButton: FloatingActionButton(
        backgroundColor: darkColor,
        child: Icon(Icons.my_location, color: primaryColor),
        onPressed: _getCurrentLocation,
      ),

      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      )
          : IndexedStack(
        index: _bottomIndex,
        children: [
          _buildHomeTab(),
          _buildServicesTab(),
          _buildTasksTab(),
          _buildProfileTab(),
        ],
      ),

      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ================= HOME =================

  Widget _buildHomeTab() {

    return Stack(

      children: [

        // MAP

        _currentLocation == null
            ? Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        )
            : GoogleMap(

          initialCameraPosition: CameraPosition(
            target: _currentLocation!,
            zoom: 15,
          ),

          myLocationEnabled: true,

          myLocationButtonEnabled: false,

          zoomControlsEnabled: false,

          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),

        // TOP PANEL

        SafeArea(

          child: Padding(

            padding: const EdgeInsets.all(20),

            child: Column(

              children: [

                // HEADER

                Container(

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(24),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Row(

                    children: [

                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: primaryColor,
                            child: Icon(
                              Icons.menu,
                              color: darkColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(

                        child: Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Text(
                              "Hello $_userName",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "Find nearby workers instantly",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.notifications_none,
                          color: darkColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // SEARCH BAR

                _buildSearchBar(),

                const SizedBox(height: 20),

                // WORKERS

                Expanded(

                  child: Align(

                    alignment: Alignment.bottomCenter,

                    child: Container(

                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(

                        color: Colors.white,

                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),

                      child: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Nearby Workers",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          NearbyWorkersScreen(
                                            initialLocation:
                                            _currentLocation,
                                            initialAddress:
                                            "Your Location",
                                          ),
                                    ),
                                  );
                                },
                                child: Text(
                                  "See All",
                                  style: TextStyle(
                                    color: darkColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Expanded(
                            child: ListView.builder(

                              scrollDirection: Axis.horizontal,

                              itemCount: _nearbyWorkers.length,

                              itemBuilder: (context, index) {

                                return _buildWorkerCard(
                                  _nearbyWorkers[index],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= SEARCH =================

  Widget _buildSearchBar() {

    return Container(

      height: 58,

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: TextField(

        readOnly: true,

        decoration: InputDecoration(

          border: InputBorder.none,

          hintText: "Search workers nearby",

          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
          ),

          suffixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune,
                color: darkColor,
              ),
            ),
          ),
        ),

        onTap: () {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NearbyWorkersScreen(
                initialLocation: _currentLocation,
                initialAddress: "Your Location",
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= WORKER CARD =================

  Widget _buildWorkerCard(Map<String, dynamic> worker) {

    return Container(

      width: 220,

      margin: const EdgeInsets.only(right: 16),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: backgroundColor,

        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              CircleAvatar(
                radius: 25,
                backgroundColor: primaryColor.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  color: darkColor,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Online",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            worker['fullName'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                worker['rating'].toString(),
              ),
            ],
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(

              onPressed: () {},

              style: ElevatedButton.styleFrom(
                backgroundColor: darkColor,
                foregroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                const EdgeInsets.symmetric(vertical: 14),
              ),

              child: const Text("Hire Worker"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SERVICES =================

  Widget _buildServicesTab() {

    return SafeArea(

      child: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Services",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            Expanded(

              child: GridView.builder(

                itemCount: _services.length,

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),

                itemBuilder: (context, index) {

                  var service = _services[index];

                  return Container(

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: Column(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            service['icon'],
                            size: 34,
                            color: darkColor,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          service['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TASKS =================

  Widget _buildTasksTab() {

    return SafeArea(

      child: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Tasks",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(30),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),

              child: Column(

                children: [

                  Icon(
                    Icons.task_alt,
                    size: 80,
                    color: primaryColor,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Post New Task",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Get bids from nearby workers",
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(

                    width: double.infinity,

                    child: ElevatedButton(

                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const PostTaskScreen(),
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkColor,
                        foregroundColor: primaryColor,
                        elevation: 0,
                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                      ),

                      child: const Text(
                        "POST TASK",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PROFILE =================

  Widget _buildProfileTab() {

    return SafeArea(

      child: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            const SizedBox(height: 20),

            CircleAvatar(
              radius: 55,
              backgroundColor: primaryColor,
              child: Icon(
                Icons.person,
                size: 60,
                color: darkColor,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              _userName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _userEmail,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 40),

            _buildProfileTile(Icons.location_on, "Update Location"),
            _buildProfileTile(Icons.history, "Task History"),
            _buildProfileTile(Icons.support_agent, "Support"),
            _buildProfileTile(Icons.settings, "Settings"),

            const Spacer(),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed: _logout,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: const Text("LOGOUT"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PROFILE TILE =================

  Widget _buildProfileTile(IconData icon, String title) {

    return Container(

      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: ListTile(

        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: darkColor,
          ),
        ),

        title: Text(title),

        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  // ================= DRAWER =================

  Widget _buildDrawer() {

    return Drawer(

      child: Column(

        children: [

          UserAccountsDrawerHeader(

            decoration: BoxDecoration(
              color: darkColor,
            ),

            currentAccountPicture: CircleAvatar(
              backgroundColor: primaryColor,
              child: Icon(
                Icons.person,
                color: darkColor,
              ),
            ),

            accountName: Text(_userName),
            accountEmail: Text(_userEmail),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _bottomIndex = 0);
            },
          ),

          ListTile(
            leading: const Icon(Icons.build),
            title: const Text("Services"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _bottomIndex = 1);
            },
          ),

          ListTile(
            leading: const Icon(Icons.task),
            title: const Text("Tasks"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _bottomIndex = 2);
            },
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _bottomIndex = 3);
            },
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM BAR =================

  Widget _buildBottomBar() {

    return BottomNavigationBar(

      currentIndex: _bottomIndex,

      selectedItemColor: darkColor,

      unselectedItemColor: Colors.grey,

      backgroundColor: Colors.white,

      elevation: 10,

      type: BottomNavigationBarType.fixed,

      onTap: (index) {
        setState(() {
          _bottomIndex = index;
        });
      },

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.build),
          label: "Services",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.task_alt),
          label: "Tasks",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}