import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skilllink_app/worker/worker_task_details_screen.dart';

class AvailableTasksScreen extends StatefulWidget {
  const AvailableTasksScreen({Key? key}) : super(key: key);

  @override
  State<AvailableTasksScreen> createState() => _AvailableTasksScreenState();
}

class _AvailableTasksScreenState extends State<AvailableTasksScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Handyman',
    'Electrician',
    'Plumbing',
    'Tech',
    'Cleaning',
    'Mason',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Query tasksQuery = FirebaseFirestore.instance.collection('tasks');

    if (_selectedCategory != 'All') {
      tasksQuery = tasksQuery.where(
        'categoryLower',
        isEqualTo: _selectedCategory.toLowerCase(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Available Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for tasks...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // ================= CATEGORY =================
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.only(left: 16),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ================= TASK LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: tasksQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurple,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final title =
                  (data['title'] ?? '').toString().toLowerCase();
                  final category =
                  (data['category'] ?? '').toString().toLowerCase();

                  final isLocked = data['isLocked'] ?? false;

                  return !isLocked &&
                      (title.contains(_searchQuery) ||
                          category.contains(_searchQuery));
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No tasks available matching your criteria.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final taskData =
                    filteredDocs[index].data() as Map<String, dynamic>;
                    final taskId = filteredDocs[index].id;

                    return _buildTaskCard(taskData, taskId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= TASK CARD =================
  Widget _buildTaskCard(Map<String, dynamic> task, String taskId) {
    final List<dynamic> rawTags = task['tags'] ?? [];
    final List<String> tags =
    rawTags.map((e) => e.toString()).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerTaskDetailsScreen(
                taskId: taskId,
                taskData: task,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CATEGORY + TIME
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task['category'] ?? 'General',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    task['postedTime'] ?? 'Just now',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // TITLE
              Text(
                task['title'] ?? 'Untitled Task',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // LOCATION + TYPE (SAFE GEOPOINT HANDLING)
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    task['location'] is GeoPoint
                        ? "${task['location'].latitude}, ${task['location'].longitude}"
                        : task['location']?.toString() ?? 'Remote',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.work_outline,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    task['type'] ?? 'Fixed',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Divider(color: Colors.grey[200]),

              const SizedBox(height: 12),

              // TAGS + BUDGET
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags
                          .map((tag) => Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Colors.grey[200],
                      ))
                          .toList(),
                    ),
                  ),

                  Text(
                    "Rs. ${task['budget'] ?? 0}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}