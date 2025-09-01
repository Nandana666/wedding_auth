// lib/admin_tabs/vendors_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_request_detail_page.dart'; // Still needed for navigation

class VendorsTab extends StatefulWidget {
  const VendorsTab({super.key});

  @override
  State<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends State<VendorsTab> {
  int _currentSubIndex = 0; // Default: Accepted
  String searchQuery = '';
  final CollectionReference vendors = FirebaseFirestore.instance.collection(
    'vendors',
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          // Custom Styled Tab Bar
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavButton('Accepted', 0),
                _buildNavButton('Requests', 1),
                _buildNavButton('Declined', 2),
              ],
            ),
          ),

          // Search bar (now only shown for the 'Accepted' tab)
          if (_currentSubIndex == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search accepted vendors...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) =>
                    setState(() => searchQuery = value.toLowerCase()),
              ),
            ),

          // Content Area using a single, dynamic list builder
          Expanded(
            child: IndexedStack(
              index: _currentSubIndex,
              children: [
                _buildVendorsList(status: 'approved'), // Index 0
                _buildVendorsList(status: 'pending_approval'), // Index 1
                _buildVendorsList(status: 'declined'), // Index 2
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildNavButton(String title, int index) {
    bool isSelected = _currentSubIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentSubIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFF472B6), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // A single, reusable method to build the list for any status
  Widget _buildVendorsList({required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: vendors.where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var vendorDocs = snapshot.data!.docs;

        // Apply search query only for the 'approved' list
        if (status == 'approved' && searchQuery.isNotEmpty) {
          vendorDocs = vendorDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) || email.contains(searchQuery);
          }).toList();
        }

        if (vendorDocs.isEmpty) {
          return Center(
            child: Text(
              'No vendors found with status: $status',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendorDocs.length,
          itemBuilder: (context, index) {
            final vendor = vendorDocs[index];
            final vendorData = vendor.data() as Map<String, dynamic>;
            final vendorId = vendor.id;
            final name = vendorData['name'] ?? 'No Name';

            // Customize the card based on the status
            return _buildVendorCard(
              context: context,
              vendorId: vendorId,
              vendorData: vendorData,
              status: status,
              name: name,
            );
          },
        );
      },
    );
  }

  Widget _buildVendorCard({
    required BuildContext context,
    required String vendorId,
    required Map<String, dynamic> vendorData,
    required String status,
    required String name,
  }) {
    Color cardColor = Colors.white;
    Color iconColor = Colors.blue.shade100;
    Color iconTextColor = Colors.blue.shade800;
    Widget trailingWidget;

    switch (status) {
      case 'pending_approval':
        cardColor = Colors.amber.shade50;
        iconColor = Colors.amber.shade100;
        iconTextColor = Colors.amber.shade800;
        trailingWidget = ElevatedButton(
          child: const Text('Review'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorRequestDetailPage(
                vendorId: vendorId,
                vendorData: vendorData,
              ),
            ),
          ),
        );
        break;
      case 'declined':
        cardColor = Colors.red.shade50;
        iconColor = Colors.red.shade100;
        iconTextColor = Colors.red.shade800;
        trailingWidget = IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () async => await vendors.doc(vendorId).delete(),
          tooltip: 'Delete Permanently',
        );
        break;
      case 'approved':
      default:
        trailingWidget = IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async => await vendors.doc(vendorId).delete(),
          tooltip: 'Delete Vendor',
        );
        break;
    }

    return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'V',
            style: TextStyle(color: iconTextColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(vendorData['email'] ?? ''),
        trailing: trailingWidget,
      ),
    );
  }
}
