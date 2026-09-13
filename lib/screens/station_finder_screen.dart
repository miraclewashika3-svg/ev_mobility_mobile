import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/payment.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../utils/maps_launcher.dart';
import 'log_swap_screen.dart';
import 'payment_screen.dart';
import 'scan_station_screen.dart';
import 'settings_screen.dart';
import '../theme/app_colors.dart';

// Nairobi CBD — used as the map's starting center before any stations have
// loaded, and as a sane fallback if a rider's station list is ever empty.
const LatLng _nairobiCenter = LatLng(-1.2864, 36.8172);

class StationFinderScreen extends StatefulWidget {
  final ApiService apiService;

  const StationFinderScreen({super.key, required this.apiService});

  @override
  State<StationFinderScreen> createState() => _StationFinderScreenState();
}

class _StationFinderScreenState extends State<StationFinderScreen> {
  late Future<List<Station>> _stationsFuture;
  bool _showMap = false;

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

  // Scans a station's QR code and jumps straight to logging a swap there --
  // the "tap and go" flow real swap networks use, instead of finding the
  // station in a list by hand.
  Future<void> _openScanStation() async {
    final stationId = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const ScanStationScreen()),
    );

    if (stationId == null || !mounted) return;

    final stations = await _stationsFuture;
    Station? match;
    for (final s in stations) {
      if (s.id == stationId) {
        match = s;
        break;
      }
    }

    if (match == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That station code isn\'t recognized.')),
      );
      return;
    }

    // Best-effort: the check-in is an accountability record, not a
    // requirement to proceed, so a failed request here (e.g. no signal at
    // the station) never blocks the rider from still logging their swap.
    try {
      await widget.apiService.checkInAtStation(stationId);
    } catch (_) {
      // Nothing to show the rider — logging the swap itself still works.
    }

    if (!mounted) return;
    await _openPaymentThenLogSwap(match);
  }

  // Payment always comes first now -- a swap can't be logged without a
  // completed one, so there's nothing to gain by letting a rider reach
  // LogSwapScreen without paying first.
  Future<void> _openPaymentThenLogSwap(Station station) async {
    final payment = await Navigator.push<Payment>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaymentScreen(apiService: widget.apiService, station: station),
      ),
    );

    if (payment == null || !mounted) return;
    await _openLogSwapScreen(station, payment);
  }

  Future<void> _openLogSwapScreen(Station station, Payment payment) async {
    final wasLogged = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LogSwapScreen(
          apiService: widget.apiService,
          station: station,
          payment: payment,
        ),
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

  Future<void> _handleGetDirections(Station station) async {
    final opened = await openDirectionsTo(
      latitude: station.latitude,
      longitude: station.longitude,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
        ),
      );
    }
  }

  // A station's details, reached the same way whether tapped from the list
  // or from a map pin — one bottom sheet, one place to keep it consistent.
  void _showStationSheet(Station station) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                station.stationName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                station.providerName,
                style: TextStyle(fontSize: 13, color: context.colors.inkMuted),
              ),
              const SizedBox(height: 10),
              Text(
                'KES ${station.swapPriceKes.toStringAsFixed(0)} / swap',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.warning,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _handleGetDirections(station);
                      },
                      icon: Icon(
                        Icons.directions,
                        color: context.colors.accent,
                      ),
                      label: const Text('Get directions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.accent,
                        side: BorderSide(color: context.colors.accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _openPaymentThenLogSwap(station);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Log a swap'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(apiService: widget.apiService),
      ),
    );
  }

  Widget _buildMapView(BuildContext context, List<Station> stations) {
    final center = stations.isNotEmpty
        ? LatLng(stations.first.latitude, stations.first.longitude)
        : _nairobiCenter;

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12.5),
      children: [
        // OpenStreetMap tiles — free, no API key, no billing account. This
        // is what makes the map itself possible at zero cost; Google Maps
        // is used only for the one-tap "Get directions" hand-off below,
        // via a plain URL, not the paid Maps SDK/Directions API.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.evmobility.ev_mobility_mobile',
        ),
        MarkerLayer(
          markers: stations.map((station) {
            return Marker(
              point: LatLng(station.latitude, station.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showStationSheet(station),
                child: Icon(
                  Icons.location_on,
                  color: context.colors.accent,
                  size: 40,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          'Nearby stations',
          style: TextStyle(
            color: context.colors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner_outlined,
              color: context.colors.accent,
            ),
            tooltip: 'Scan station code',
            onPressed: _openScanStation,
          ),
          IconButton(
            icon: Icon(
              _showMap ? Icons.view_list : Icons.map_outlined,
              color: context.colors.inkMuted,
            ),
            tooltip: _showMap ? 'Show list' : 'Show map',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.colors.inkMuted),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: FutureBuilder<List<Station>>(
        future: _stationsFuture,
        builder: (context, snapshot) {
          // Three distinct states, each with its own real UI — no blank
          // screen while loading, no silent failure on error.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.accent),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              color: context.colors.accent,
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
              color: context.colors.accent,
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No stations found yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.inkMuted),
                    ),
                  ),
                ],
              ),
            );
          }

          if (_showMap) {
            return _buildMapView(context, stations);
          }

          return RefreshIndicator(
            color: context.colors.accent,
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
                    onTap: () => _openPaymentThenLogSwap(station),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.stationName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  station.providerName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.colors.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'KES ${station.swapPriceKes.toStringAsFixed(0)} / swap',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.directions,
                              color: context.colors.accent,
                            ),
                            tooltip: 'Get directions',
                            onPressed: () => _handleGetDirections(station),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: context.colors.inkMuted,
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
