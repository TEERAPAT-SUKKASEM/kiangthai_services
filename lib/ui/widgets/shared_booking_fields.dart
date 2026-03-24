import 'package:flutter/material.dart';

class SharedBookingFields extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final List<String> bookedTimes;
  final bool isLoadingTimes;

  // เพิ่ม Controller และตัวแปรใหม่สำหรับระบบ Profile
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final List<String> savedAddresses;
  final Function(String?) onAddressSelected;
  final bool showSaveAddressButton;
  final VoidCallback onSaveAddressTap;

  final Function(DateTime) onDateSelected;
  final Function(String) onTimeSelected;

  const SharedBookingFields({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.bookedTimes,
    required this.isLoadingTimes,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.savedAddresses,
    required this.onAddressSelected,
    required this.showSaveAddressButton,
    required this.onSaveAddressTap,
    required this.onDateSelected,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
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
          'ข้อมูลสถานที่และผู้ติดต่อ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 15),

        // 1. กล่องชื่อ และ เบอร์โทร (แบ่งซ้ายขวา)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ-นามสกุล',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'เบอร์โทรศัพท์',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 2. Dropdown เลือกที่อยู่ (โชว์ก็ต่อเมื่อมีที่อยู่เคยเซฟไว้)
        if (savedAddresses.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'เลือกที่อยู่ที่บันทึกไว้',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.bookmark),
            ),
            isExpanded: true,
            // ถ้าข้อความในกล่องตรงกับในลิสต์ ให้โชว์ค่านั้น ถ้าไม่ตรง (ลูกค้าพิมพ์แก้) ให้กลายเป็น null
            value: savedAddresses.contains(addressController.text)
                ? addressController.text
                : null,
            items: savedAddresses.map((addr) {
              return DropdownMenuItem(
                value: addr,
                child: Text(addr, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: onAddressSelected,
          ),
          const SizedBox(height: 15),
        ],

        // 3. กล่องที่อยู่ (ยืดหยุ่นตามความยาว)
        TextField(
          controller: addressController,
          minLines: 2,
          maxLines:
              null, // ใส่ null เพื่อให้กล่องยืดลงมาเรื่อยๆ เวลากด Enter หรือพิมพ์ยาว
          decoration: const InputDecoration(
            labelText: 'ที่อยู่หน้างาน (รายละเอียดเพิ่มเติม)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on, color: Colors.redAccent),
          ),
        ),

        // 4. ปุ่มบันทึกที่อยู่ (โชว์ก็ต่อเมื่อเป็นที่อยู่ใหม่ที่ไม่เคยมีในลิสต์)
        if (showSaveAddressButton)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSaveAddressTap,
              icon: const Icon(Icons.save_alt),
              label: const Text('บันทึกที่อยู่นี้ไว้ในรายการ'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
          ),

        // ----------------- ส่วนของปฏิทินและเวลา (เหมือนเดิม) -----------------
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

        const Text(
          'เวลาที่สะดวก',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        DefaultTabController(
          length: 2,
          child: Column(
            children: [
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
              SizedBox(
                height: 260,
                child: TabBarView(
                  children: [
                    _buildTimeGrid(morningSlots, context),
                    _buildTimeGrid(afternoonSlots, context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeGrid(List<String> timeSlots, BuildContext context) {
    if (selectedDate != null && isLoadingTimes)
      return const Center(child: CircularProgressIndicator());

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
        final isBooked = bookedTimes.contains(slot);
        final isSelected = selectedTime == slot;

        return ChoiceChip(
          label: Text(
            slot,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBooked
                  ? Colors.grey
                  : (isSelected ? Colors.white : Colors.black),
              decoration: isBooked ? TextDecoration.lineThrough : null,
            ),
          ),
          selected: isSelected,
          padding: const EdgeInsets.symmetric(vertical: 8),
          onSelected: isBooked
              ? null
              : (selected) {
                  if (selected) {
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณาเลือกวันที่ก่อนครับ'),
                        ),
                      );
                      return;
                    }
                    onTimeSelected(slot);
                  }
                },
          selectedColor: Colors.blueAccent,
          backgroundColor: Colors.white,
          disabledColor: Colors.grey.shade200,
          side: BorderSide(
            color: isBooked ? Colors.grey.shade300 : Colors.blueAccent,
          ),
        );
      },
    );
  }
}
