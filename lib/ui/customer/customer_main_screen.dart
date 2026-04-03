import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_home_screen.dart';
import 'my_bookings_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;
  RealtimeChannel? _bookingChannel;

  final List<Widget> _pages = const [
    CustomerHomeScreen(),
    MyBookingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToBookingUpdates();
  }

  @override
  void dispose() {
    _bookingChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToBookingUpdates() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _bookingChannel = Supabase.instance.client
        .channel('customer_booking_updates_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: user.id,
          ),
          callback: (payload) {
            if (!mounted) return;
            final newStatus = payload.newRecord['status'] as String?;
            final oldStatus = payload.oldRecord['status'] as String?;

            if (newStatus == oldStatus) return;

            final (String message, Color color) = switch (newStatus) {
              'accepted' => ('Technician has accepted your job!', Colors.blue),
              'on_the_way' => ('Technician is on the way!', Colors.orange),
              'in_progress' => ('Technician has started the job!', Colors.blue),
              'completed' => ('Job completed!', Colors.green),
              'rejected' => ('Technician rejected the job. Please rebook.', Colors.red),
              _ => ('Booking status changed', Colors.grey),
            };

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text(message)),
                  ],
                ),
                backgroundColor: color,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'View Booking',
                  textColor: Colors.white,
                  onPressed: () => setState(() => _currentIndex = 1),
                ),
              ),
            );
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Services'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'My Bookings',
          ),
        ],
      ),
    );
  }
}
