import 'package:flutter/material.dart';
import 'air_booking_screen.dart';
import 'profile_settings_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  static const List<Map<String, dynamic>> _services = [
    {'name': 'แอร์', 'icon': Icons.ac_unit, 'color': Colors.blue},
    {
      'name': 'ไฟฟ้า',
      'icon': Icons.electrical_services,
      'color': Colors.orange,
    },
    {'name': 'โซล่า', 'icon': Icons.wb_sunny, 'color': Colors.yellow},
    {'name': 'กล้องวงจรปิด', 'icon': Icons.videocam, 'color': Colors.red},
    {'name': 'ปั๊มน้ำ', 'icon': Icons.water_drop, 'color': Colors.cyan},
    {
      'name': 'อิเล็กทรอนิกส์',
      'icon': Icons.devices_other,
      'color': Colors.purple,
    },
  ];

  void _onServiceTap(BuildContext context, Map<String, dynamic> service) {
    if (service['name'] == 'แอร์') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AirBookingScreen()),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('บริการ${service['name']}'),
          content: const Text(
            'บริการนี้กำลังเปิดให้บริการเร็วๆ นี้ กรุณาติดต่อเราโดยตรง',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกบริการ'),
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
