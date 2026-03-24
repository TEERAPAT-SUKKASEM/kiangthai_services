import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'air_booking_screen.dart';
import 'profile_settings_screen.dart';

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
        // ========================================================
        // ✅ ✅ ✅ เปลี่ยนจากปุ่ม Logout เป็นป๊อบอัพเมนูรูปคน ✅ ✅ ✅
        // ========================================================
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline, size: 28), // ไอคอนรูปคน
            onSelected: (value) async {
              if (value == 'settings') {
                // กดตั้งค่าโปรไฟล์ ไปหน้า ProfileSettingsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              } else if (value == 'logout') {
                // กดออกจากระบบ
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังออกจากระบบ...')),
                );
                await Supabase.instance.client.auth.signOut();

                if (context.mounted) {
                  // เด้งกลับไปหน้า login (ถ้าหน้า login ของคุณไม่ได้ชื่อ '/login' ให้แก้ตรงนี้นะครับ)
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings, color: Colors.blue),
                  title: Text('ตั้งค่าโปรไฟล์'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(), // เส้นคั่น
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('ออกจากระบบ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10), // เว้นระยะขอบขวานิดนึง
        ],
        // ========================================================
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
              if (service['name'] == 'แอร์') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AirBookingScreen(),
                  ),
                );
              }
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
