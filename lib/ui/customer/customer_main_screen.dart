import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n.dart';
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
              title: t('chat.new_message'),
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
              'accepted' => (t('notify.accepted'), AppColors.accepted),
              'on_the_way' => (t('notify.on_the_way'), AppColors.onTheWay),
              'in_progress' => (t('notify.in_progress'), AppColors.inProgress),
              'completed' => (t('notify.completed'), AppColors.completed),
              'rejected' => (t('notify.rejected'), AppColors.rejected),
              _ => (t('notify.status_changed'), AppColors.textMuted),
            };

            NotificationService.showLocal(
              title: t('bookings.booking_update'),
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
                  label: t('common.view'),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: t('nav.services'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long_rounded),
              label: t('nav.my_bookings'),
            ),
          ],
        ),
      ),
    );
  }
}
