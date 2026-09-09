import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/swap_log.dart';
import '../services/api_service.dart';
import 'add_bike_screen.dart';
import 'login_screen.dart';

class BikeProfileScreen extends StatefulWidget {
  final ApiService apiService;

  const BikeProfileScreen({super.key, required this.apiService});

  @override
  State<BikeProfileScreen> createState() => _BikeProfileScreenState();
}

class _BikeProfileScreenState extends State<BikeProfileScreen> {
  late Future<List<Bike>> _bikesFuture;
  final Map<int, Future<List<SwapLog>>> _swapLogFutures = {};

  @override
  void initState() {
    super.initState();
    _bikesFuture = widget.apiService.getBikes();
  }

  Future<void> _openAddBikeScreen() async {
    final wasAdded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBikeScreen(apiService: widget.apiService),
      ),
    );

    if (wasAdded == true && mounted) {
      setState(() {
        _bikesFuture = widget.apiService.getBikes();
      });
    }
  }

  // This screen's data is cached and kept alive across tab switches (see
  // HomeScreen), so a swap logged from the Stations tab wouldn't otherwise
  // show up here without a full app restart. Pull-to-refresh re-fetches on
  // demand instead.
  Future<void> _handleRefresh() async {
    setState(() {
      _bikesFuture = widget.apiService.getBikes();
      _swapLogFutures.clear();
    });
    await _bikesFuture;
  }

  // Formats a DateTime as e.g. "5 Sep, 08:30" — enough detail for a rider
  // to recognize which visit it was, without a full timestamp's clutter.
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]}, $hour:$minute';
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
          'My bike',
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
      body: FutureBuilder<List<Bike>>(
        future: _bikesFuture,
        builder: (context, bikesSnapshot) {
          if (bikesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B8A4A)),
            );
          }

          if (bikesSnapshot.hasError) {
            return RefreshIndicator(
              color: const Color(0xFF1B8A4A),
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load your bike. Confirm the API server is running.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            );
          }

          final bikes = bikesSnapshot.data ?? [];

          if (bikes.isEmpty) {
            return RefreshIndicator(
              color: const Color(0xFF1B8A4A),
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'No bike registered to your account yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6B786F)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _openAddBikeScreen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B8A4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text('Add your bike'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Most riders have exactly one bike, so this screen focuses on
          // that bike's profile card plus its history — if a rider ever
          // had more than one, this still won't crash, it just shows the
          // first bike registered to them.
          final bike = bikes.first;

          _swapLogFutures.putIfAbsent(
            bike.id,
            () => widget.apiService.getSwapLogsForBike(bike.id),
          );

          return RefreshIndicator(
            color: const Color(0xFF1B8A4A),
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Bike profile card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8E4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF5EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.electric_moped_outlined,
                              color: Color(0xFF1B8A4A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bike.model,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A2620),
                                  ),
                                ),
                                Text(
                                  bike.registrationNumber,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B786F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8E4)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Home network',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B786F),
                            ),
                          ),
                          Text(
                            bike.homeNetwork,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A2620),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Swap history',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2620),
                  ),
                ),
                const SizedBox(height: 10),

                FutureBuilder<List<SwapLog>>(
                  future: _swapLogFutures[bike.id],
                  builder: (context, logsSnapshot) {
                    if (logsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1B8A4A),
                          ),
                        ),
                      );
                    }

                    if (logsSnapshot.hasError) {
                      return const Text(
                        'Could not load swap history.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B786F),
                        ),
                      );
                    }

                    final logs = logsSnapshot.data ?? [];

                    if (logs.isEmpty) {
                      return const Text(
                        'No swaps logged yet for this bike.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B786F),
                        ),
                      );
                    }

                    return Column(
                      children: logs.map((log) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8E4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.battery_charging_full,
                                    size: 18,
                                    color: Color(0xFF1B8A4A),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(log.swappedAt),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1A2620),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'KES ${log.costKes.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
