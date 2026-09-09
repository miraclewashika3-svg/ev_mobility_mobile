import 'package:flutter/material.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import 'log_swap_screen.dart';
import 'login_screen.dart';

class StationFinderScreen extends StatefulWidget {
  final ApiService apiService;

  const StationFinderScreen({super.key, required this.apiService});

  @override
  State<StationFinderScreen> createState() => _StationFinderScreenState();
}

class _StationFinderScreenState extends State<StationFinderScreen> {
  late Future<List<Station>> _stationsFuture;

  @override
  void initState() {
    super.initState();
    _stationsFuture = widget.apiService.getStations();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _stationsFuture = widget.apiService.getStations();
    });
    await _stationsFuture;
  }

  Future<void> _openLogSwapScreen(Station station) async {
    final wasLogged = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LogSwapScreen(apiService: widget.apiService, station: station),
      ),
    );

    if (wasLogged == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap logged — check My Bike and Savings.'),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await widget.apiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(apiService: widget.apiService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF7),
        elevation: 0,
        title: const Text(
          'Nearby stations',
          style: TextStyle(
            color: Color(0xFF1A2620),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF6B786F)),
            tooltip: 'Sign out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<List<Station>>(
        future: _stationsFuture,
        builder: (context, snapshot) {
          // Three distinct states, each with its own real UI — no blank
          // screen while loading, no silent failure on error.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B8A4A)),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              color: const Color(0xFF1B8A4A),
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load stations. Confirm the API server is running.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            );
          }

          final stations = snapshot.data ?? [];

          if (stations.isEmpty) {
            return RefreshIndicator(
              color: const Color(0xFF1B8A4A),
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No stations found yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B786F)),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF1B8A4A),
            onRefresh: _handleRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openLogSwapScreen(station),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8E4)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.stationName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A2620),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  station.providerName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B786F),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'KES ${station.swapPriceKes.toStringAsFixed(0)} / swap',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF6B786F),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
