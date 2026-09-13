import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/payment.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../services/data_refresh_signal.dart';
import '../widgets/bike_selector.dart';
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
  // Which bike this swap is being logged against, for a rider with more
  // than one. Null until the first successful load picks a default.
  int? _selectedBikeId;
  // Defaults to right now (the common case: logging a swap as it happens),
  // but is editable -- Help screen has always told riders "you can pick
  // any past date and time" for a swap they forgot to log at the time,
  // and the backend has always allowed it (StoreSwapLogRequest only
  // requires before_or_equal:now); this screen just never actually
  // offered a way to change it until now.
  DateTime _swappedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _bikesFuture = widget.apiService.getBikes();
  }

  Future<void> _pickSwappedAt() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _swappedAt,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_swappedAt),
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    // A date-only picker plus a time-only picker can together land after
    // "now" (e.g. today's date with a time later than the current one) --
    // clamp rather than let the backend's before_or_equal:now reject it
    // with a confusing error after the rider already picked both.
    setState(() => _swappedAt = combined.isAfter(now) ? now : combined);
  }

  String _formatSwappedAt(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} ${months[dateTime.month - 1]}, $hour:$minute';
  }

  Future<void> _openAddBikeScreen() async {
    final newBikeId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBikeScreen(apiService: widget.apiService),
      ),
    );

    // Previously fired-and-forgot: adding a bike from this screen's empty
    // state never refreshed _bikesFuture, so the rider stayed stuck on
    // "add your bike first" until they backed out and re-entered.
    if (newBikeId != null && mounted) {
      setState(() {
        _bikesFuture = widget.apiService.getBikes();
        _selectedBikeId = newBikeId;
      });
    }
  }

  Bike _resolveSelectedBike(List<Bike> bikes) {
    return bikes.firstWhere(
      (bike) => bike.id == _selectedBikeId,
      orElse: () => bikes.first,
    );
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
        swappedAt: _swappedAt,
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
                        onPressed: _openAddBikeScreen,
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

            final bike = _resolveSelectedBike(bikes);

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
                    // The common case (one bike) keeps the exact single-line
                    // subtitle this screen always had; only a rider with a
                    // choice to make gets the extra "which bike" prompt and
                    // picker below instead of it being named inline here.
                    bikes.length > 1
                        ? widget.station.providerName
                        : '${widget.station.providerName} · for ${bike.model} (${bike.registrationNumber})',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.inkMuted,
                    ),
                  ),
                  if (bikes.length > 1) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Log this swap for',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.colors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BikeSelector(
                      bikes: bikes,
                      selectedBikeId: bike.id,
                      onSelected: (selected) =>
                          setState(() => _selectedBikeId = selected.id),
                    ),
                  ],
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickSwappedAt,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 18,
                            color: context.colors.inkMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Swapped at ${_formatSwappedAt(_swappedAt)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colors.ink,
                              ),
                            ),
                          ),
                          Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: context.colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
