import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddBikeScreen extends StatefulWidget {
  final ApiService apiService;

  const AddBikeScreen({super.key, required this.apiService});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final _modelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _homeNetworkController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleSave() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.apiService.createBike(
        model: _modelController.text.trim(),
        registrationNumber: _registrationController.text.trim(),
        homeNetwork: _homeNetworkController.text.trim(),
      );

      if (!mounted) return;
      // Signal the caller (BikeProfileScreen) that a bike was added, so it
      // knows to re-fetch its bike list rather than showing stale data.
      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _registrationController.dispose();
    _homeNetworkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF7),
        elevation: 0,
        title: const Text(
          'Add your bike',
          style: TextStyle(
            color: Color(0xFF1A2620),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Bike model',
                  hintText: 'e.g. Roam Air',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _registrationController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Registration number',
                  hintText: 'e.g. KMEV001A',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _homeNetworkController,
                decoration: const InputDecoration(
                  labelText: 'Home network',
                  hintText: 'e.g. Roam',
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
                  onPressed: _isSubmitting ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(_isSubmitting ? 'Saving…' : 'Save bike'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
