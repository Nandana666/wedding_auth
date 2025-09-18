// lib/admin_dashboard.dart

import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'admin_tabs/vendors_tab.dart';
import 'admin_tabs/users_tab.dart';
import 'admin_tabs/reviews_tab.dart';
import 'admin_tabs/statistics_tab.dart';
import 'admin_tabs/history_page.dart'; // Import the History tab
import 'login_screen.dart'; // Assuming login screen is the root for logout

enum DateFilter { today, thisWeek, thisMonth, all }

DateTimeRange getDateRange(DateFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case DateFilter.today:
      return DateTimeRange(
          start: DateTime(now.year, now.month, now.day), end: now);
    case DateFilter.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: now);
    case DateFilter.thisMonth:
      return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    case DateFilter.all:
      return DateTimeRange(start: DateTime(2000), end: now);
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _bottomNavIndex = 0; // Default to the first tab: Users

  // A list of the widgets to display in the body
  static final List<Widget> _widgetOptions = <Widget>[
    const UsersTab(),
    const VendorsTab(),
    ReviewsTab(),
    StatisticsTab(),
    const HistoryPage(), // History Tab
  ];

  // Titles for each tab
  static const List<String> _widgetTitles = <String>[
    'User Management',
    'Vendor Management',
    'Reviews',
    'Statistics',
    'History', // History tab title
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // --- Custom Gradient Header ---
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _widgetTitles.elementAt(_bottomNavIndex),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Log Out',
                  onPressed: () async {
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),

          // --- Main Content Area ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _widgetOptions.elementAt(_bottomNavIndex),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6A11CB),
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 10.0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Vendors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
