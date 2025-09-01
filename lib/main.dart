// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import the generated Firebase options

// Import all the pages for your routes
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'vendor_dashboard.dart';
import 'admin_dashboard.dart';
import 'auth_gate.dart'; // Import your AuthGate

void main() async {
  // Ensure Flutter is ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();
  // Modern Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wedding Planner', // A more descriptive title
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // A color that matches your design
        visualDensity: VisualDensity.adaptivePlatformDensity,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Text color for ElevatedButton
          ),
        ),
      ),
      
      // The AuthGate handles the initial screen logic.
      // It shows the login page if logged out, or the correct home page if logged in.
      home: const AuthGate(),
      
      // The routes map is used for named navigation from within the app.
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/adminHome': (context) => const AdminDashboard(),
        // FIX: Renamed '/vendorHome' to '/vendorDashboard' to match the login screen
        '/vendorDashboard': (context) => const VendorDashboard(), 
      },
    );
  }
}