import 'package:flutter/material.dart';

class SharedBookingFields extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final TextEditingController addressController;
  final TextEditingController noteController;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback onImageTap;
  final bool hasImage; // ตัวแปรเช็คว่าลูกค้าแนบรูปหรือยัง

  const SharedBookingFields({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.addressController,
    required this.noteController,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onImageTap,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30, thickness: 2),
        const Text(
          'ข้อมูลสถานที่และเวลา',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        // 1. ช่องกรอกที่อยู่หน้างาน
        TextField(
          controller: addressController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'ที่อยู่หน้างาน (บ้านเลขที่, ซอย, ถนน, ตำบล)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on, color: Colors.redAccent),
          ),
        ),
        const SizedBox(height: 15),

        // 2. ปุ่มเลือกวันที่ และ เวลา (แบ่งครึ่งจอ)
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onDateTap,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'วันที่',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? 'เลือกวันที่'
                            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onTimeTap,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'เวลา',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedTime == null
                            ? 'เลือกเวลา'
                            : selectedTime!.format(context),
                      ),
                      const Icon(Icons.access_time, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const Divider(height: 30, thickness: 2),
        const Text(
          'ข้อมูลเพิ่มเติม (ถ้ามี)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        // 3. ปุ่มแนบรูปภาพหน้างาน
        OutlinedButton.icon(
          onPressed: onImageTap,
          icon: Icon(
            hasImage ? Icons.check_circle : Icons.camera_alt,
            color: hasImage ? Colors.green : Colors.blue,
          ),
          label: Text(
            hasImage
                ? 'แนบรูปภาพสำเร็จ (กดเพื่อเปลี่ยน)'
                : 'ถ่ายรูป / แนบรูปภาพหน้างาน',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: hasImage ? Colors.green : Colors.blue),
          ),
        ),
        const SizedBox(height: 15),

        // 4. ช่องหมายเหตุ
        TextField(
          controller: noteController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'หมายเหตุถึงช่าง (อาการเสีย, จุดสังเกต)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
