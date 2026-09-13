import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/payment.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../services/data_refresh_signal.dart';
import 'add_bike_screen.dart';
import '../theme/app_colors.dart';

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

    try {
      // The backend derives both the actual cost and the petrol-equivalent
      // figure itself from this swap log's own (payment-verified) cost --
      // this app no longer computes or sends them, so there's nothing here
      // for a tampered client to fabricate. See
      // CostEntryController::store's comment for why that matters.
      final swapLog = await widget.apiService.createSwapLog(
        bikeId: bike.id,
        stationId: widget.station.id,
        paymentId: widget.payment.id,
        swappedAt: DateTime.now(),
      );
      await widget.apiService.createCostEntry(swapLogId: swapLog.id);

      // My Bike and Savings each cache their own fetched data so switching
      // tabs doesn't re-hit the API — but that means neither one otherwise
      // finds out about a swap just logged from this (Stations tab) screen
      // until the rider manually pulls to refresh. Bumping this tells both
      // to refetch even while sitting inactive behind HomeScreen's
      // IndexedStack.
      dataRefreshSignal.notifyChanged();

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
                    style: TextStyle(color: context.colors.inkMuted),
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
