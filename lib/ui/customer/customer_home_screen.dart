import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  // รายชื่อบริการทั้ง 6 อย่าง
  final List<Map<String, dynamic>> services = const [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกบริการ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // แสดง 2 คอลัมน์
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return InkWell(
            onTap: () {
              // TODO: ไปยังหน้าแบบฟอร์มของแต่ละบริการ
              print('เลือกบริการ: ${service['name']}');
            },
            child: Card(
              color: service['color'].withOpacity(0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(service['icon'], size: 50, color: service['color']),
                  const SizedBox(height: 10),
                  Text(
                    service['name'],
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
