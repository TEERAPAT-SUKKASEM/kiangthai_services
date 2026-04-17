import 'package:flutter/material.dart';
import 'air_booking_screen.dart';
import 'service_booking_screen.dart';
import 'profile_settings_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  static const List<Map<String, dynamic>> _services = [
    {'name': 'AC', 'icon': Icons.ac_unit, 'color': Colors.blue},
    {
      'name': 'Electrical',
      'icon': Icons.electrical_services,
      'color': Colors.orange,
    },
    {'name': 'Solar', 'icon': Icons.wb_sunny, 'color': Colors.yellow},
    {'name': 'CCTV', 'icon': Icons.videocam, 'color': Colors.red},
    {'name': 'Water Pump', 'icon': Icons.water_drop, 'color': Colors.cyan},
    {
      'name': 'Electronics',
      'icon': Icons.devices_other,
      'color': Colors.purple,
    },
  ];

  static final Map<String, ServiceConfig> _serviceConfigs = {
    'Electrical': electricalConfig,
    'Solar': solarConfig,
    'CCTV': cctvConfig,
    'Water Pump': waterPumpConfig,
    'Electronics': electronicsConfig,
  };

  void _onServiceTap(BuildContext context, Map<String, dynamic> service) {
    final name = service['name'] as String;
    if (name == 'AC') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AirBookingScreen()),
      );
    } else {
      final config = _serviceConfigs[name];
      if (config != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceBookingScreen(config: config),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Service'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return InkWell(
            onTap: () => _onServiceTap(context, service),
            child: Card(
              color: (service['color'] as Color).withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    service['icon'] as IconData,
                    size: 50,
                    color: service['color'] as Color,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    service['name'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
