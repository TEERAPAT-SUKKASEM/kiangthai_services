import 'package:flutter/material.dart';
import '../../core/theme.dart';

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
        const SizedBox(height: 24),
        _SectionTitle('Location & Contact'),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (savedAddresses.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Saved address',
              prefixIcon: Icon(Icons.bookmark_outline_rounded),
            ),
            isExpanded: true,
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
          const SizedBox(height: 12),
        ],

        TextField(
          controller: addressController,
          minLines: 2,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'Job site address',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),

        if (showSaveAddressButton)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onSaveAddressTap,
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                label: const Text('Save address'),
                style: TextButton.styleFrom(foregroundColor: AppColors.completed),
              ),
            ),
          ),

        const SizedBox(height: 24),
        _SectionTitle('Select Date & Time'),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: CalendarDatePicker(
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateChanged: onDateSelected,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Preferred Time',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),

        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Morning'),
                    Tab(text: 'Afternoon'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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

        return InkWell(
          onTap: isBooked
              ? null
              : () {
                  if (selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a date first')),
                    );
                    return;
                  }
                  onTimeSelected(slot);
                },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brand
                  : (isBooked ? AppColors.fieldFill : AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.brand
                    : (isBooked ? AppColors.border : AppColors.border),
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isBooked
                    ? AppColors.textMuted
                    : (isSelected ? Colors.white : AppColors.textPrimary),
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}
