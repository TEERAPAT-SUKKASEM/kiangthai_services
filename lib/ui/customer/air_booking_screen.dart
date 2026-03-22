import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AirBookingScreen extends StatefulWidget {
  const AirBookingScreen({super.key});

  @override
  State<AirBookingScreen> createState() => _AirBookingScreenState();
}

class _AirBookingScreenState extends State<AirBookingScreen> {
  String _selectedService = 'ล้างแอร์';
  final _btuController = TextEditingController();
  final _countController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จองบริการแอร์')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'ประเภทบริการ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: _selectedService,
            isExpanded: true,
            items: <String>['ล้างแอร์', 'ซ่อมแอร์', 'ติดตั้งแอร์', 'ย้ายแอร์']
                .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                })
                .toList(),
            onChanged: (newValue) =>
                setState(() => _selectedService = newValue!),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _btuController,
            decoration: const InputDecoration(
              labelText: 'ขนาด BTU (ถ้าทราบ)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _countController,
            decoration: const InputDecoration(
              labelText: 'จำนวนเครื่อง',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลังบันทึกข้อมูล...')),
              );
            },
            child: const Text('ยืนยันการจอง', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
