import 'package:flutter/material.dart';

class SharedBookingFields extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final List<String> bookedTimes; // รายชื่อเวลาที่โดนจองแล้วในวันที่เลือก
  final bool isLoadingTimes;
  final TextEditingController addressController;
  final TextEditingController noteController;
  final Function(DateTime) onDateSelected;
  final Function(String) onTimeSelected;
  final VoidCallback onImageTap;
  final bool hasImage;

  const SharedBookingFields({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.bookedTimes,
    required this.isLoadingTimes,
    required this.addressController,
    required this.noteController,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.onImageTap,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. เซ็ตปุ่มเวลาตามที่คุณกำหนด (แบ่งเป็น 2 เซ็ตๆ ละ 2x4 = 8 ปุ่ม)
    // ช่วงเช้า: 08:00-11:30 (ทีละ 30 นาที = 8 ปุ่ม)
    final morningSlots = [
      '08:00',
      '08:30',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
    ];
    // ช่วงบ่าย: 13:00-16:30 (ทีละ 30 นาที = 8 ปุ่ม)
    final afternoonSlots = [
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30, thickness: 2),
        const Text(
          'ข้อมูลสถานที่',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: addressController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'ที่อยู่หน้างาน (บ้านเลขที่, ซอย, ถนน, ตำบล)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on, color: Colors.redAccent),
          ),
        ),

        const Divider(height: 30, thickness: 2),
        const Text(
          'เลือกวันที่และเวลา',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: CalendarDatePicker(
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateChanged: onDateSelected,
          ),
        ),
        const SizedBox(height: 20),

        // ==========================================================
        // ✅ ✅ ✅ ยกเครื่อง UI เวลาเป็นแบบ 2 แท็บ ✅ ✅ ✅
        // ==========================================================
        const Text(
          'เวลาที่สะดวก',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // ใช้ DefaultTabController บร๊อบส่วนแท็บเวลา (2 แท็บ เช้า/บ่าย)
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // 1. แถบเลือกแท็บ (เช้า/บ่าย)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black,
                  tabs: const [
                    Tab(text: 'ช่วงเช้า (08:00-11:30)'),
                    Tab(text: 'ช่วงบ่าย (13:00-16:30)'),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 2. เนื้อหาภายในแท็บ (ปุ่มเวลา)
              // จำเป็นต้องกำหนดความสูงให้ SizedBox เพราะ TabBarView อยู่ใน ListView
              SizedBox(
                height: 260, // ความสูงเพียงพอสำหรับตาราง 4 แถว + spacing
                child: TabBarView(
                  children: [
                    // --- แท็บช่วงเช้า (GridView 2x4) ---
                    _buildTimeGrid(morningSlots, context),
                    // --- แท็บช่วงบ่าย (GridView 2x4) ---
                    _buildTimeGrid(afternoonSlots, context),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ==========================================================
        const Divider(height: 30, thickness: 2),
        const Text(
          'ข้อมูลเพิ่มเติม (ถ้ามี)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

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

  // ==========================================================
  // Helper ฟังก์ชัน: สร้างตารางเวลา (GridView 2 คอลัมน์)
  // ==========================================================
  Widget _buildTimeGrid(List<String> timeSlots, BuildContext context) {
    if (selectedDate != null && isLoadingTimes) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      shrinkWrap: true, // จำเป็นเพราะอยู่ใน SizedBox
      physics:
          const NeverScrollableScrollPhysics(), // ปิดการสกอล์ในตัว Grid เพราะ TabBarView จัดการแล้ว
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // แบ่งเป็น 2 คอลัมน์ตามต้องการเป๊ะๆ
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio:
            3, // ปรับสัดส่วนปุ่มให้ดูสวยงาม (กว้างเป็น 3 เท่าของสูง)
      ),
      itemCount: timeSlots.length, // จำนวนปุ่ม (ควรเป็น 8 ปุ่มตามที่ส่งมา)
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
        final isBooked = bookedTimes.contains(
          slot,
        ); // บล็อกถ้าโดนจองไปแล้วในวันนั้นๆ
        final isSelected = selectedTime == slot;

        return ChoiceChip(
          label: Text(
            slot,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              // ปรับสีตัวอักษร: ถ้าโดนจอง->เทา, ถ้าเลือกอยู่->ขาว, ปกติ->ดำ
              color: isBooked
                  ? Colors.grey
                  : (isSelected ? Colors.white : Colors.black),
              decoration: isBooked
                  ? TextDecoration.lineThrough
                  : null, // ขีดฆ่าเวลาที่เต็ม
            ),
          ),
          selected: isSelected,
          padding: const EdgeInsets.symmetric(vertical: 8),
          // ลอจิกบล็อกคิวจริง: ถ้าโดนจอง ตั้งเป็น null เพื่อปิดการกด
          onSelected: isBooked
              ? null
              : (bool selected) {
                  if (selected) {
                    // แจ้งเตือนถ้าลูกค้ายังไม่ได้เลือกวันที่
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'กรุณาเลือกวันที่ก่อนครับ เพื่อเช็คคิวว่าง',
                          ),
                        ),
                      );
                      return;
                    }
                    onTimeSelected(slot);
                  }
                },
          selectedColor: Colors.blueAccent,
          backgroundColor: Colors.white,
          disabledColor: Colors.grey.shade200, // สีปุ่มถ้าโดนบล็อก
          side: BorderSide(
            color: isBooked ? Colors.grey.shade300 : Colors.blueAccent,
          ),
        );
      },
    );
  }
}
