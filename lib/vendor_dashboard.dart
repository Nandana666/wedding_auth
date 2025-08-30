import 'package:flutter/material.dart';
import 'auth_service.dart';

class VendorDashboard extends StatelessWidget {
  const VendorDashboard({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleSignOut(context),
          )
        ],
      ),
      body: const Center(child: Text("Welcome Vendor")),
    );
  }
}
