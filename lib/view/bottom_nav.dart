import 'package:flutter/material.dart';
import 'package:taskova_shopkeeper/view/dashboard.dart';
import 'package:taskova_shopkeeper/view/driverspage.dart';
import 'package:taskova_shopkeeper/view/profile.dart';


class HomePageWithBottomNav extends StatefulWidget {
  const HomePageWithBottomNav({super.key});

  @override
  State<HomePageWithBottomNav> createState() => _HomePageWithBottomNavState();
}

class _HomePageWithBottomNavState extends State<HomePageWithBottomNav> {
  int _currentIndex = 0;

  // List of pages
  final List<Widget> _pages = [Dashboard(), ProfilePage(), DriverListScreen()];

  // On tap handler
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.personal_injury),
            label: 'Drivers',
          ),
        ],
      ),
    );
  }
}
