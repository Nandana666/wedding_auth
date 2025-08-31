import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_requests_tab.dart';
import 'declined_vendors_tab.dart';

class VendorsTab extends StatefulWidget {
  const VendorsTab({super.key});

  @override
  State<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends State<VendorsTab> {
  // FIX: Set default view to 'Accepted' (index 0)
  int _currentSubIndex = 0;
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
                // FIX: Reordered the navigation buttons
                _buildNavButton('Accepted', 0),
                _buildNavButton('Requests', 1),
                _buildNavButton('Declined', 2),
              ],
            ),
          ),

          // FIX: Updated condition to show search bar when 'Accepted' is selected
          if (_currentSubIndex == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
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

          // Content Area
          Expanded(
            child: IndexedStack(
              index: _currentSubIndex,
              // FIX: Reordered the children to match the new tab indices
              children: [
                _buildAcceptedVendorsList(), // Index 0
                VendorRequestsTab(), // Index 1
                DeclinedVendorsTab(), // Index 2
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom Navigation Button Widget (No changes needed here)
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

  // Redesigned Accepted Vendors List (No changes needed here)
  Widget _buildAcceptedVendorsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: vendors.where('status', isEqualTo: 'approved').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allVendors = snapshot.data!.docs.where((vendor) {
          final name = (vendor['name'] ?? '').toString().toLowerCase();
          final email = (vendor['email'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery) || email.contains(searchQuery);
        }).toList();

        if (allVendors.isEmpty) {
          return const Center(
            child: Text(
              'No accepted vendors found.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allVendors.length,
          itemBuilder: (context, index) {
            final vendor = allVendors[index].data() as Map<String, dynamic>;
            final vendorId = allVendors[index].id;
            final name = vendor['name'] ?? 'No Name';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'V',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(vendor['email'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async => await vendors.doc(vendorId).delete(),
                  tooltip: 'Delete Vendor',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
