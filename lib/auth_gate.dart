// lib/auth_gate.dart

import 'package:flutter/material.dart'; // This line will work after the fix
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import all possible destination screens
import 'login_screen.dart';
import 'home_screen.dart';
import 'vendor_dashboard.dart';
import 'admin_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return FutureBuilder<String?>(
          future: _getRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            switch (roleSnapshot.data) {
              case 'user':
                return const HomeScreen();
              case 'vendor_approved':
              case 'vendor_pending':
                return const VendorDashboard();
              case 'admin':
                return const AdminDashboard();
              default:
                return const LoginScreen();
            }
          },
        );
      },
    );
  }

  Future<String?> _getRole(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (userDoc.exists) return 'user';

    final adminDoc = await FirebaseFirestore.instance
        .collection('Admin')
        .doc(uid)
        .get();
    if (adminDoc.exists) return 'admin';

    final vendorDoc = await FirebaseFirestore.instance
        .collection('vendors')
        .doc(uid)
        .get();
    if (vendorDoc.exists) {
      final status = (vendorDoc.data() as Map<String, dynamic>)['status'];
      switch (status) {
        case 'approved':
          return 'vendor_approved';
        case 'incomplete':
        case 'pending_approval':
          return 'vendor_pending';
        case 'declined':
          return 'vendor_declined';
      }
    }

    return null;
  }
}
