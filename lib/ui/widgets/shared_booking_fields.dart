import 'package:flutter/material.dart';

class SharedBookingFields extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final List<String> bookedTimes;
  final bool isLoadingTimes;
  final TextEditingController addressController;
  final Function(DateTime) onDateSelected;
  final Function(String) onTimeSelected;

  const SharedBookingFields({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.bookedTimes,
    required this.isLoadingTimes,
    required this.addressController,
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
