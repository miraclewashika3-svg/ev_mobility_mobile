import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'station_finder_screen.dart';
import 'savings_screen.dart';
import 'bike_profile_screen.dart';

// HomeScreen wraps all three post-login screens in a bottom tab bar, so the
// rider can move between finding a station, checking savings, and viewing
// their bike/history without logging in again or losing their place.
class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({super.key, required this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Built once here rather than inside the IndexedStack's children list,
    // so each screen's own state (like fetched data) survives tab switches
    // instead of being rebuilt from scratch every time.
    final screens = [
      StationFinderScreen(apiService: widget.apiService),
      SavingsScreen(apiService: widget.apiService),
      BikeProfileScreen(apiService: widget.apiService),
    ];

    return Scaffold(
      // IndexedStack keeps all three screens alive in memory, just hiding
      // the inactive ones — switching tabs doesn't re-trigger API calls.
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1B8A4A),
        unselectedItemColor: const Color(0xFF6B786F),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.ev_station_outlined),
            label: 'Stations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.electric_moped_outlined),
            label: 'My Bike',
          ),
        ],
      ),
    );
  }
}
