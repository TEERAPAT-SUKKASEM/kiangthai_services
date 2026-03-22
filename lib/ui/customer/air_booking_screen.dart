import 'package:flutter/material.dart';
// import ไฟล์ชิ้นส่วนส่วนกลางของเรา
import '../widgets/shared_booking_fields.dart';

class AirBookingScreen extends StatefulWidget {
  const AirBookingScreen({super.key});

  @override
  State<AirBookingScreen> createState() => _AirBookingScreenState();
}

class _AirBookingScreenState extends State<AirBookingScreen> {
  // 1. ตัวแปรสำหรับฟอร์มจองแอร์ (เฉพาะของแอร์)
  String _selectedService = 'ล้างแอร์';
  final _btuController = TextEditingController();
  final _countController = TextEditingController(text: '1');

  // 2. ตัวแปรสำหรับชิ้นส่วนส่วนกลาง (เวลา, สถานที่, รูปภาพ)
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  bool _hasImage = false;

  @override
  void dispose() {
    // ควรล้างข้อมูลใน Controller เมื่อออกจากหน้าจอเพื่อป้องกัน Memory Leak
    _btuController.dispose();
    _countController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

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
          const SizedBox(height: 20),

          // --- เรียกใช้งาน SharedBookingFields (ส่งค่าให้ครบถ้วน) ---
          SharedBookingFields(
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            addressController: _addressController,
            noteController: _noteController,
            hasImage: _hasImage,
            onDateTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            onTimeTap: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => _selectedTime = picked);
              }
            },
            onImageTap: () {
              // ตอนนี้ทำปุ่มให้กดสลับสถานะได้ก่อน เดี๋ยวเรามาใส่โค้ดกล้องทีหลัง
              setState(() => _hasImage = !_hasImage);
            },
          ),

          // --------------------------------------------------------
          const SizedBox(height: 30),

          // ปุ่มยืนยัน
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // ตรวจสอบเบื้องต้นว่ากรอกข้อมูลครบไหม
              if (_selectedDate == null ||
                  _selectedTime == null ||
                  _addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกวันที่ เวลา และที่อยู่ให้ครบถ้วน'),
                  ),
                );
                return;
              }
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
