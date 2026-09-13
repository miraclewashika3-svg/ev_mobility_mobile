import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/payment.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import 'add_bike_screen.dart';
import '../theme/app_colors.dart';

// The real-world ~2.4x purchase-price/running-cost gap the seeded demo data
// uses (see DatabaseSeeder) — applied here too, so a swap logged live from
// the app produces a savings figure consistent with the seeded history it
// sits alongside, rather than an arbitrarily different one.
const double _petrolEquivalentMultiplier = 2.4;
const double _freeSwapPetrolEquivalentKes = 430;

class LogSwapScreen extends StatefulWidget {
  final ApiService apiService;
  final Station station;
  final Payment payment;

  const LogSwapScreen({
    super.key,
    required this.apiService,
    required this.station,
    required this.payment,
  });

  @override
  State<LogSwapScreen> createState() => _LogSwapScreenState();
}

class _LogSwapScreenState extends State<LogSwapScreen> {
  late Future<List<Bike>> _bikesFuture;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bikesFuture = widget.apiService.getBikes();
  }

  Future<void> _handleLogSwap(Bike bike) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final cost = widget.payment.amountKes;
    final petrolEquivalent = cost > 0
        ? double.parse((cost * _petrolEquivalentMultiplier).toStringAsFixed(2))
        : _freeSwapPetrolEquivalentKes;

    try {
      await widget.apiService.createSwapLog(
        bikeId: bike.id,
        stationId: widget.station.id,
        paymentId: widget.payment.id,
        swappedAt: now,
      );
      await widget.apiService.createCostEntry(
        bikeId: bike.id,
        petrolEquivalentKes: petrolEquivalent,
        actualCostKes: cost,
        entryDate: now,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(
          'Log a swap',
          style: TextStyle(
            color: context.colors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Bike>>(
          future: _bikesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: context.colors.accent),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load your bike. Confirm the API server is running.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }

            final bikes = snapshot.data ?? [];

            if (bikes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add your bike first so swaps can be logged against it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.inkMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddBikeScreen(apiService: widget.apiService),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.accent,
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
              );
            }

            final bike = bikes.first;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.station.stationName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.station.providerName} · for ${bike.model} (${bike.registrationNumber})',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.accentSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: context.colors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paid KES ${widget.payment.amountKes.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.accentDark,
                                ),
                              ),
                              if (widget.payment.providerReference != null)
                                Text(
                                  'Ref ${widget.payment.providerReference}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.colors.accentMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: context.colors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleLogSwap(bike),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        _isSubmitting ? 'Logging swap…' : 'Log this swap',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
