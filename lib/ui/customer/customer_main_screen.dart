import 'package:flutter/material.dart';
// Import หน้าทั้งสองของเราเข้ามา
import 'customer_home_screen.dart';
import 'my_bookings_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex =
      0; // ตัวแปรจำว่าตอนนี้อยู่หน้าไหน (0 = หน้าหลัก, 1 = ประวัติ)

  // รายการหน้าจอที่จะสลับไปมา
  final List<Widget> _pages = [
    const CustomerHomeScreen(),
    const MyBookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // แสดงหน้าจอตาม Index ที่เลือก
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // เปลี่ยนหน้าเมื่อกดที่ไอคอนด้านล่าง
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'เลือกบริการ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'การจองของฉัน',
          ),
        ],
      ),
    );
  }
}
