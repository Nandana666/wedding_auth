import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_requests_tab.dart'; // This import will now work correctly
import 'declined_vendors_tab.dart';

class VendorsTab extends StatefulWidget {
  const VendorsTab({super.key});

  @override
  State<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends State<VendorsTab> {
  int _currentSubIndex = 2; // 0=Request, 1=Declined, 2=Accepted
  String searchQuery = '';
  final CollectionReference vendors = FirebaseFirestore.instance.collection(
    'vendors',
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavButton('Requests', 0),
              const SizedBox(width: 16),
              _buildNavButton('Declined', 1),
              const SizedBox(width: 16),
              _buildNavButton('Accepted', 2),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_currentSubIndex == 2)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search accepted vendors by name or email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _currentSubIndex == 0
              // This line will now be valid.
              ? VendorRequestsTab()
              : _currentSubIndex == 1
              ? DeclinedVendorsTab()
              : _buildAcceptedVendorsList(),
        ),
      ],
    );
  }

  // ... (rest of the file is unchanged) ...
  Widget _buildNavButton(String title, int index) {
    bool isSelected = _currentSubIndex == index;
    return ElevatedButton(
      onPressed: () => setState(() => _currentSubIndex = index),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

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
          return const Center(child: Text('No accepted vendors found'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return ListView.builder(
                itemCount: allVendors.length,
                itemBuilder: (context, index) {
                  final vendor = allVendors[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    child: ListTile(
                      title: Text(vendor['name'] ?? 'No Name'),
                      subtitle: Text(vendor['email'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async =>
                            await vendors.doc(vendor.id).delete(),
                      ),
                    ),
                  );
                },
              );
            } else {
              final crossAxisCount = (constraints.maxWidth / 300).floor();
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: allVendors.length,
                itemBuilder: (context, index) {
                  final vendor = allVendors[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text(vendor['name'] ?? 'No Name'),
                      subtitle: Text(vendor['email'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async =>
                            await vendors.doc(vendor.id).delete(),
                      ),
                    ),
                  );
                },
              );
            }
          },
        );
      },
    );
  }
}
