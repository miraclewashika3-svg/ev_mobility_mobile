import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

// Sits between check-in and logging a swap: a rider can't log a swap
// without a completed payment (the backend enforces this, not just this
// screen). `method` is always 'simulated' for now -- there's no live
// payment gateway account behind this yet -- so the badge below is not
// decoration, it's the one thing standing between this screen and looking
// like it actually charges someone.
class PaymentScreen extends StatefulWidget {
  final ApiService apiService;
  final Station station;
  final int? swapCheckinId;

  const PaymentScreen({
    super.key,
    required this.apiService,
    required this.station,
    this.swapCheckinId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Future<Payment> _startFuture;
  bool _isConfirming = false;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _startFuture = widget.apiService.startPayment(
      stationId: widget.station.id,
      swapCheckinId: widget.swapCheckinId,
    );
  }

  Future<void> _handlePayNow(Payment pending) async {
    setState(() {
      _isConfirming = true;
      _confirmError = null;
    });

    try {
      final confirmed = await widget.apiService.confirmPayment(pending.id);
      if (!mounted) return;
      Navigator.pop(context, confirmed);
    } catch (error) {
      setState(() {
        _confirmError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
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
          'Pay for swap',
          style: TextStyle(
            color: context.colors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Payment>(
          future: _startFuture,
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
                    snapshot.error
                        .toString()
                        .replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }

            final payment = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.warningSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SIMULATED PAYMENT — no real charge is made',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: context.colors.warningDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    widget.station.providerName,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount due',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'KES ${payment.amountKes.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: context.colors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_confirmError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _confirmError!,
                      style: TextStyle(
                        color: context.colors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isConfirming
                          ? null
                          : () => _handlePayNow(payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        _isConfirming
                            ? 'Confirming…'
                            : 'Pay now (simulated)',
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
