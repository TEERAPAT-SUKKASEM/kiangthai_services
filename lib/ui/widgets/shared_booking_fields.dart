import 'package:flutter/material.dart';

class SharedBookingFields extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final List<String> bookedTimes;
  final bool isLoadingTimes;

  // Add controllers and new variables for the Profile system
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
          'Location & Contact Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 15),

        // 1. Name and phone fields (side by side)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
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
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 2. Address dropdown (only shown when saved addresses exist)
        if (savedAddresses.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Saved Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.bookmark),
            ),
            isExpanded: true,
            // Show matched saved address as selected; null if user typed something new
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

        // 3. Address field (flexible height)
        TextField(
          controller: addressController,
          minLines: 2,
          maxLines:
              null, // null lets the field expand freely on Enter or long input
          decoration: const InputDecoration(
            labelText: 'Job Site Address (additional details)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on, color: Colors.redAccent),
          ),
        ),

        // 4. Save address button (shown only when a new address is entered)
        if (showSaveAddressButton)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSaveAddressTap,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save this address to list'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
          ),

        // ----------------- Date & time section -----------------
        const Divider(height: 30, thickness: 2),
        const Text(
          'Select Date & Time',
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
          'Preferred Time',
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
                    Tab(text: 'Morning (08:00-11:30)'),
                    Tab(text: 'Afternoon (13:00-16:30)'),
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

  bool _isPastSlot(String slot) {
    if (selectedDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
    );
    if (selected != today) return false;
    final parts = slot.split(':');
    final slotDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return slotDateTime.isBefore(now);
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
        final isBooked = bookedTimes.contains(slot) || _isPastSlot(slot);
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
                          content: Text('Please select a date first'),
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
