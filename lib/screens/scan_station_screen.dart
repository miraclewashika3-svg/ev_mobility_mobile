import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Every station QR code encodes this prefix + the station's numeric id --
// e.g. "evmobility:station:3" -- so a scan can never be mistaken for some
// unrelated QR code (a WiFi password, a URL) a rider might point the
// camera at by accident.
const _stationCodePrefix = 'evmobility:station:';

// Returns the scanned station's id, or null if the rider backs out without
// a successful scan.
class ScanStationScreen extends StatefulWidget {
  const ScanStationScreen({super.key});

  @override
  State<ScanStationScreen> createState() => _ScanStationScreenState();
}

class _ScanStationScreenState extends State<ScanStationScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.startsWith(_stationCodePrefix)) {
        final idString = value.substring(_stationCodePrefix.length);
        final id = int.tryParse(idString);
        if (id != null) {
          _handled = true;
          Navigator.pop(context, id);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan station code'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1B8A4A), width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const Positioned(
            bottom: 48,
            child: Text(
              'Point your camera at the station\'s QR code',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
