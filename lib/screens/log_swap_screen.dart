import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/payment.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import 'add_bike_screen.dart';

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
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF7),
        elevation: 0,
        title: const Text(
          'Log a swap',
          style: TextStyle(
            color: Color(0xFF1A2620),
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
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B8A4A)),
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
                      const Text(
                        'Add your bike first so swaps can be logged against it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF6B786F)),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2620),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.station.providerName} · for ${bike.model} (${bike.registrationNumber})',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B786F),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F0E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF1B8A4A),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paid KES ${widget.payment.amountKes.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F5C30),
                                ),
                              ),
                              if (widget.payment.providerReference != null)
                                Text(
                                  'Ref ${widget.payment.providerReference}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF4C7A56),
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
                      style: const TextStyle(
                        color: Color(0xFFB45309),
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
                        backgroundColor: const Color(0xFF1B8A4A),
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
