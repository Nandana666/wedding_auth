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

    // Assign main content based on selected tab
    switch (_bottomNavIndex) {
      case 0:
        mainContent = const UsersTab(); // const constructor available
        break;
      case 1:
        mainContent = const VendorsTab(); // const constructor available
        break;
      case 2:
        mainContent = ReviewsTab(); // cannot be const
        break;
      case 3:
      default:
        mainContent = StatisticsTab(); // cannot be const
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/admin_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark overlay for readability
          Container(color: const Color.fromARGB(102, 0, 0, 0)), // 40% opacity

          Column(
            children: [
              // Gradient AppBar with status bar padding
              Container(
                padding: const EdgeInsets.only(top: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(97, 0, 0, 0),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
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
                ),
              ),
              // Main content container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(243), // 95% opacity
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(66, 0, 0, 0),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: mainContent, // dynamic, cannot be const
                ),
              ),
            ],
          ),
        ],
      ),
      // Gradient BottomNavigationBar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(66, 0, 0, 0),
              blurRadius: 8,
              offset: Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Users'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Vendors'),
            BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'Reviews'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
          ],
          onTap: (index) {
            setState(() {
              _bottomNavIndex = index;
            });
          },
        ),
      ),
    );
  }
}
