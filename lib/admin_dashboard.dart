import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'admin_tabs/vendors_tab.dart';
import 'admin_tabs/users_tab.dart';
import 'admin_tabs/reviews_tab.dart';
import 'admin_tabs/statistics_tab.dart';
import 'home_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _bottomNavIndex = 3; // Default: Statistics

  @override
  Widget build(BuildContext context) {
    Widget mainContent;

    switch (_bottomNavIndex) {
      case 0:
        mainContent = const UsersTab();
        break;
      case 1:
        // This is now correct.
        mainContent = const VendorsTab();
        break;
      case 2:
        mainContent = ReviewsTab();
        break;
      case 3:
      default:
        mainContent = StatisticsTab();
    }

    // ... rest of the widget is unchanged ...
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/admin_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(color: Colors.black.withOpacity(0.2)),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await AuthService().signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
              Expanded(child: mainContent),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Vendors'),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }

  String _getTitle() {
    switch (_bottomNavIndex) {
      case 0:
        return 'Users';
      case 1:
        return 'Vendors';
      case 2:
        return 'Reviews';
      case 3:
      default:
        return 'Statistics';
    }
  }
}
