import 'package:flutter/material.dart';
// This import is what's failing at the project level.
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsTab extends StatelessWidget {
  StatisticsTab({super.key});

  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference vendors = FirebaseFirestore.instance.collection(
    'vendors',
  );
  final CollectionReference reviews = FirebaseFirestore.instance.collection(
    'reviews',
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _fetchCounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final counts = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard('Users', counts[0], Colors.blue),
              const SizedBox(height: 16),
              _buildStatCard('Approved Vendors', counts[1], Colors.green),
              const SizedBox(height: 16),
              _buildStatCard('Declined Vendors', counts[2], Colors.red),
              const SizedBox(height: 16),
              _buildStatCard('Reviews', counts[3], Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Future<List<int>> _fetchCounts() async {
    final userCount =
        (await users.where('role', isEqualTo: 'user').get()).docs.length;
    final approvedVendors =
        (await vendors.where('status', isEqualTo: 'approved').get())
            .docs
            .length;
    final declinedVendors =
        (await vendors.where('status', isEqualTo: 'declined').get())
            .docs
            .length;
    final reviewCount = (await reviews.get()).docs.length;
    return [userCount, approvedVendors, declinedVendors, reviewCount];
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      color: color.withAlpha((255 * 0.2).round()),
      child: ListTile(
        leading: Icon(Icons.bar_chart, color: color, size: 40),
        title: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          count.toString(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
