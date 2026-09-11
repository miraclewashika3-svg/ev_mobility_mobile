import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/savings_summary.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';

class SavingsScreen extends StatefulWidget {
  final ApiService apiService;

  const SavingsScreen({super.key, required this.apiService});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  late Future<List<Bike>> _bikesFuture;
  // Maps bikeId -> its own savings summary, fetched once bikes are known —
  // same pattern as the Vue dashboard, so both surfaces stay consistent.
  final Map<int, Future<SavingsSummary>> _summaryFutures = {};

  @override
  void initState() {
    super.initState();
    _bikesFuture = widget.apiService.getBikes();
  }

  // Bikes and their savings summaries are cached in this screen's state and
  // kept alive across tab switches (see HomeScreen), so a swap logged from
  // the Stations tab wouldn't otherwise show up here without a full app
  // restart. Pull-to-refresh re-fetches everything on demand instead.
  Future<void> _handleRefresh() async {
    setState(() {
      _bikesFuture = widget.apiService.getBikes();
      _summaryFutures.clear();
    });
    await _bikesFuture;
  }

  String _formatKes(double value) {
    // Simple thousands-separator formatting without pulling in a full intl
    // package dependency just for this one thing.
    final wholeNumber = value.round();
    final str = wholeNumber.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
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
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF7),
        elevation: 0,
        title: const Text(
          'Your savings',
          style: TextStyle(
            color: Color(0xFF1A2620),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF6B786F)),
            tooltip: 'Settings',
            onPressed: _openSettings,
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
                      'Could not load your bikes. Confirm the API server is running.',
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
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No bikes registered yet. Savings appear once your bike has logged swaps or cost entries.',
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
              itemCount: bikes.length,
              itemBuilder: (context, index) {
                final bike = bikes[index];

                // Only fetch each bike's summary once, cached in the map,
                // rather than re-fetching on every rebuild of the list.
                _summaryFutures.putIfAbsent(
                  bike.id,
                  () => widget.apiService.getSavingsSummary(bike.id),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8E4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.model,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2620),
                        ),
                      ),
                      Text(
                        '${bike.registrationNumber} · ${bike.homeNetwork}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B786F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<SavingsSummary>(
                        future: _summaryFutures[bike.id],
                        builder: (context, summarySnapshot) {
                          if (summarySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(
                                color: Color(0xFF1B8A4A),
                              ),
                            );
                          }

                          if (summarySnapshot.hasError ||
                              !summarySnapshot.hasData) {
                            return const Text(
                              'No cost entries logged yet for this bike.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B786F),
                              ),
                            );
                          }

                          final summary = summarySnapshot.data!;

                          return Column(
                            children: [
                              _SavingsRow(
                                label: 'Petrol-equivalent cost',
                                value:
                                    'KES ${_formatKes(summary.totalPetrolEquivalentKes)}',
                              ),
                              const SizedBox(height: 4),
                              _SavingsRow(
                                label: 'Actual cost paid',
                                value:
                                    'KES ${_formatKes(summary.totalActualCostKes)}',
                              ),
                              const Divider(
                                height: 20,
                                color: Color(0xFFE2E8E4),
                              ),
                              _SavingsRow(
                                label: 'Total saved',
                                value:
                                    'KES ${_formatKes(summary.totalSavingsKes)}',
                                isHighlighted: true,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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

// A small, reusable row widget for a label/value pair — used three times
// per card above, so pulling it into its own widget avoids repeating the
// same Row/Text structure three times inline.
class _SavingsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _SavingsRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 13 : 12,
            color: const Color(0xFF6B786F),
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 12,
            fontWeight: FontWeight.w600,
            color: isHighlighted
                ? const Color(0xFFB45309)
                : const Color(0xFF1A2620),
          ),
        ),
      ],
    );
  }
}
