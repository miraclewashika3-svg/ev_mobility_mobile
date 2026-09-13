import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/swap_log.dart';
import '../services/api_service.dart';
import '../services/data_refresh_signal.dart';
import '../widgets/bike_selector.dart';
import '../widgets/empty_state.dart';
import 'add_bike_screen.dart';
import 'settings_screen.dart';
import '../theme/app_colors.dart';

class BikeProfileScreen extends StatefulWidget {
  final ApiService apiService;

  const BikeProfileScreen({super.key, required this.apiService});

  @override
  State<BikeProfileScreen> createState() => _BikeProfileScreenState();
}

class _BikeProfileScreenState extends State<BikeProfileScreen> {
  late Future<List<Bike>> _bikesFuture;
  final Map<int, Future<List<SwapLog>>> _swapLogFutures = {};
  // Which bike's profile/history is showing, for a rider with more than
  // one. Null until the first successful load picks a default (see
  // _resolveSelectedBike) -- there's no bike to default to before then.
  int? _selectedBikeId;

  @override
  void initState() {
    super.initState();
    _bikesFuture = widget.apiService.getBikes();
    // Covers the gap pull-to-refresh alone leaves: a swap logged from the
    // Stations tab while this screen sits inactive behind HomeScreen's
    // IndexedStack, with nothing prompting the rider to manually refresh.
    dataRefreshSignal.addListener(_handleRefresh);
  }

  @override
  void dispose() {
    dataRefreshSignal.removeListener(_handleRefresh);
    super.dispose();
  }

  Future<void> _openAddBikeScreen() async {
    final newBikeId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBikeScreen(apiService: widget.apiService),
      ),
    );

    if (newBikeId != null && mounted) {
      setState(() {
        _bikesFuture = widget.apiService.getBikes();
        // Jump straight to the bike just added rather than leaving
        // whichever one was selected before -- the rider's attention is
        // already on the new one.
        _selectedBikeId = newBikeId;
      });
    }
  }

  // Bikes load in whatever order the backend returns them, and the
  // previously-selected id may no longer be in the list (e.g. after a
  // refresh). Falls back to the first bike rather than crashing on
  // firstWhere's "no element" if that ever happens.
  Bike _resolveSelectedBike(List<Bike> bikes) {
    return bikes.firstWhere(
      (bike) => bike.id == _selectedBikeId,
      orElse: () => bikes.first,
    );
  }

  // This screen's data is cached and kept alive across tab switches (see
  // HomeScreen). Pull-to-refresh re-fetches on demand, and so does
  // dataRefreshSignal firing while this screen is inactive.
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

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(apiService: widget.apiService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(
          'My bike',
          style: TextStyle(
            color: context.colors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Previously only reachable from the empty state, so a rider who
          // already had one bike had no way to ever register a second --
          // the backend has always supported it (Bike hasMany per Rider),
          // the UI just never exposed it.
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: context.colors.accent),
            tooltip: 'Add another bike',
            onPressed: _openAddBikeScreen,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.colors.inkMuted),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: FutureBuilder<List<Bike>>(
        future: _bikesFuture,
        builder: (context, bikesSnapshot) {
          if (bikesSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.accent),
            );
          }

          if (bikesSnapshot.hasError) {
            return RefreshIndicator(
              color: context.colors.accent,
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load your bike. Confirm the API server is running.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.inkMuted),
                    ),
                  ),
                ],
              ),
            );
          }

          final bikes = bikesSnapshot.data ?? [];

          if (bikes.isEmpty) {
            return RefreshIndicator(
              color: context.colors.accent,
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 40),
                  EmptyState(
                    icon: Icons.electric_moped_outlined,
                    title: 'No bike registered yet',
                    message:
                        'Add your bike to start logging swaps and tracking how much you\'re saving versus petrol.',
                    actionLabel: 'Add your bike',
                    onAction: _openAddBikeScreen,
                  ),
                ],
              ),
            );
          }

          final bike = _resolveSelectedBike(bikes);

          _swapLogFutures.putIfAbsent(
            bike.id,
            () => widget.apiService.getSwapLogsForBike(bike.id),
          );

          return RefreshIndicator(
            color: context.colors.accent,
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Only rendered once there's more than one bike to choose
                // between -- a rider with the usual single bike sees
                // exactly the same screen as before.
                BikeSelector(
                  bikes: bikes,
                  selectedBikeId: bike.id,
                  onSelected: (selected) =>
                      setState(() => _selectedBikeId = selected.id),
                ),
                if (bikes.length > 1) const SizedBox(height: 16),

                // Bike profile card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.colors.accentSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.electric_moped_outlined,
                              color: context.colors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bike.model,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.ink,
                                  ),
                                ),
                                Text(
                                  bike.registrationNumber,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24, color: context.colors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Home network',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.colors.inkMuted,
                            ),
                          ),
                          Text(
                            bike.homeNetwork,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Swap history',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.ink,
                  ),
                ),
                const SizedBox(height: 10),

                FutureBuilder<List<SwapLog>>(
                  future: _swapLogFutures[bike.id],
                  builder: (context, logsSnapshot) {
                    if (logsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: context.colors.accent,
                          ),
                        ),
                      );
                    }

                    if (logsSnapshot.hasError) {
                      return Text(
                        'Could not load swap history.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.inkMuted,
                        ),
                      );
                    }

                    final logs = logsSnapshot.data ?? [];

                    if (logs.isEmpty) {
                      return Text(
                        'No swaps logged yet for this bike.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.inkMuted,
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
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.battery_charging_full,
                                    size: 18,
                                    color: context.colors.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(log.swappedAt),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'KES ${log.costKes.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.warning,
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
