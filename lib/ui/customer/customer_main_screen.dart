import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/chat_unread_service.dart';
import '../../services/notification_service.dart';
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
  RealtimeChannel? _messagesChannel;

  final List<Widget> _pages = const [
    CustomerHomeScreen(),
    MyBookingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToBookingUpdates();
    _subscribeToIncomingMessages();
  }

  @override
  void dispose() {
    _bookingChannel?.unsubscribe();
    _messagesChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToIncomingMessages() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _messagesChannel = Supabase.instance.client
        .channel('customer_messages_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final senderId = payload.newRecord['sender_id'] as String?;
            if (senderId == user.id) return; // my own message
            final bookingId = payload.newRecord['booking_id'];
            ChatUnreadService.instance.markUnread(bookingId);
            NotificationService.showLocal(
              title: 'New message',
              body: payload.newRecord['content'] as String? ?? '',
            );
          },
        )
        .subscribe();
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
              'accepted' => ('Technician has accepted your job!', AppColors.accepted),
              'on_the_way' => ('Technician is on the way!', AppColors.onTheWay),
              'in_progress' => ('Technician has started the job!', AppColors.inProgress),
              'completed' => ('Job completed!', AppColors.completed),
              'rejected' => ('Technician rejected the job. Please rebook.', AppColors.rejected),
              _ => ('Booking status changed', AppColors.textMuted),
            };

            NotificationService.showLocal(
              title: 'Booking update',
              body: message,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(message)),
                  ],
                ),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'View',
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
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: AppDurations.med,
        transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
          animation: primary,
          secondaryAnimation: secondary,
          fillColor: AppColors.background,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: user == null
              ? const Stream.empty()
              : Supabase.instance.client
                  .from('bookings')
                  .stream(primaryKey: ['id'])
                  .eq('customer_id', user.id),
          builder: (context, snapshot) {
            final hasPending = (snapshot.data ?? [])
                .any((b) => b['status'] == 'pending');

            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Services',
                ),
                BottomNavigationBarItem(
                  icon: _BookingsTabIcon(
                    icon: Icons.receipt_long_outlined,
                    showDot: hasPending,
                  ),
                  activeIcon: _BookingsTabIcon(
                    icon: Icons.receipt_long_rounded,
                    showDot: hasPending,
                  ),
                  label: 'My Bookings',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingsTabIcon extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  const _BookingsTabIcon({required this.icon, required this.showDot});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Icon(icon)),
          if (showDot)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
