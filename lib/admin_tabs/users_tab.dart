import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersTab extends StatefulWidget {
  @override
  _UsersTabState createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference vendorsCollection = FirebaseFirestore.instance.collection('vendors');

  String searchQuery = '';

  /// Fetch common users + vendors who haven't requested admin approval
  Future<List<QueryDocumentSnapshot>> _getCombinedUsers() async {
    final usersSnapshot = await usersCollection.where('role', isEqualTo: 'user').get();
    final vendorsSnapshot = await vendorsCollection.get();

    final nonRequestedVendors = vendorsSnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?; 
      return data == null || data['requestToAdmin'] != true;
    }).toList();

    return [...usersSnapshot.docs, ...nonRequestedVendors];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, email, or role',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        // Users + non-requested vendors
        Expanded(
          child: FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _getCombinedUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final filteredDocs = snapshot.data!.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final role = (data['role'] ?? (!data.containsKey('requestToAdmin') ? 'vendor' : 'user'))
                    .toString()
                    .toLowerCase();
                return name.contains(searchQuery) ||
                    email.contains(searchQuery) ||
                    role.contains(searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) return const Center(child: Text('No users found'));

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  if (isMobile) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) => _userCard(filteredDocs[index], isMobile: true),
                    );
                  } else {
                    final crossAxisCount = (constraints.maxWidth / 350).floor();
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) => _userCard(filteredDocs[index]),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _userCard(QueryDocumentSnapshot doc, {bool isMobile = false}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? 'No Name';
    final email = data['email'] ?? '';
    final role = data['role'] ?? (!data.containsKey('requestToAdmin') ? 'vendor' : 'user');
    final avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final cardContent = isMobile
        ? ListTile(
            leading: CircleAvatar(radius: 24, child: Text(avatarLetter)),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _roleBadge(role),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                _viewDetailsButton(doc),
                _deleteButton(doc, role),
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(radius: 28, child: Text(avatarLetter, style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _roleBadge(role),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _viewDetailsButton(doc),
                  _deleteButton(doc, role),
                ],
              ),
            ],
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: cardContent,
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color color = Colors.grey;
    if (role.toLowerCase() == 'user') color = Colors.green;
    if (role.toLowerCase() == 'vendor') color = Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _viewDetailsButton(QueryDocumentSnapshot doc) {
    return IconButton(
      icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
      tooltip: 'View Details',
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('User Details'),
            content: _userDetailsContent(doc),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      },
    );
  }

  Widget _userDetailsContent(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';
    final phone = data['phone'] ?? 'N/A';
    final address = data['address'] ?? 'N/A';
    final role = data['role'] ?? (!data.containsKey('requestToAdmin') ? 'vendor' : 'user');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Name', name),
          _detailRow('Email', email),
          _detailRow('Phone', phone),
          _detailRow('Address', address),
          _detailRow('Role', role),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _deleteButton(QueryDocumentSnapshot doc, String role) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete'),
            content: const Text('Are you sure you want to delete this user/vendor?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );

        if (confirm == true) {
          try {
            if (role.toLowerCase() == 'user') {
              await usersCollection.doc(doc.id).delete();
            } else {
              await vendorsCollection.doc(doc.id).delete();
            }
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
            setState(() {});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
          }
        }
      },
    );
  }
}
