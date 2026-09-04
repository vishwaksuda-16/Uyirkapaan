import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/location_formatter.dart';
import '../../controllers/location_controller.dart';

/// Screen for manual location adjustment and emergency pickup confirmation.
class LocationPickerScreen extends StatefulWidget {
  final LocationController locationController;

  const LocationPickerScreen({
    super.key,
    required this.locationController,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late double _selectedLat;
  late double _selectedLng;
  final TextEditingController _landmarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentLoc = widget.locationController.emergencyLocation;
    _selectedLat = currentLoc?.latitude ?? 13.0827;
    _selectedLng = currentLoc?.longitude ?? 80.2707;
  }

  @override
  void dispose() {
    _landmarkController.dispose();
    super.dispose();
  }

  void _adjustCoordinates(double latDelta, double lngDelta) {
    setState(() {
      _selectedLat += latDelta;
      _selectedLng += lngDelta;
    });
  }

  void _confirmLocation() {
    widget.locationController.setManualEmergencyLocation(
      latitude: _selectedLat,
      longitude: _selectedLng,
      address: _landmarkController.text.trim().isNotEmpty
          ? _landmarkController.text.trim()
          : 'Near Pinpointed Marker (${_selectedLat.toStringAsFixed(4)}, ${_selectedLng.toStringAsFixed(4)})',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency pickup location confirmed'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceLoc = widget.locationController.deviceLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm / Adjust Location'),
        actions: [
          IconButton(
            tooltip: 'Reset to My GPS Location',
            icon: const Icon(Icons.my_location_rounded, color: AppColors.emergencyRed),
            onPressed: () {
              if (deviceLoc != null) {
                setState(() {
                  _selectedLat = deviceLoc.latitude;
                  _selectedLng = deviceLoc.longitude;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Informative banner explaining distinction
          Container(
            width: double.infinity,
            color: AppColors.emergencyLightRed,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.emergencyDarkRed, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Specify where the patient is located. This can differ from your current position.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.emergencyDarkRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Map Area / Visual Canvas Pinpoint
          Expanded(
            child: Stack(
              children: [
                // Simulated Geographic Grid View
                Container(
                  width: double.infinity,
                  color: const Color(0xFFE5E3DF), // Standard map canvas tone
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PICKUP PINPOINT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.location_pin,
                            color: AppColors.emergencyRed,
                            size: 48,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Directional D-pad Controls to adjust pin location
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      _buildDpadButton(Icons.arrow_upward_rounded, () => _adjustCoordinates(0.0015, 0)),
                      Row(
                        children: [
                          _buildDpadButton(Icons.arrow_back_rounded, () => _adjustCoordinates(0, -0.0015)),
                          const SizedBox(width: 40),
                          _buildDpadButton(Icons.arrow_forward_rounded, () => _adjustCoordinates(0, 0.0015)),
                        ],
                      ),
                      _buildDpadButton(Icons.arrow_downward_rounded, () => _adjustCoordinates(-0.0015, 0)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Confirmation Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TARGET COORDINATES', style: AppTextStyles.caption),
                      Text(
                        LocationFormatter.formatCoordinates(_selectedLat, _selectedLng),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      hintText: 'Nearby landmark / street / floor / gate',
                      prefixIcon: const Icon(Icons.add_location_alt_rounded, size: 20),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      child: const Text('CONFIRM EMERGENCY LOCATION'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDpadButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.emergencyDarkRed),
        onPressed: onPressed,
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14;

    final linePaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..strokeWidth = 1;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), linePaint);
    }

    // Draw simulated major roads
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.55), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.48, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
