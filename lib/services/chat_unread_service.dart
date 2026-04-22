import 'package:flutter/foundation.dart';

// Session-scoped unread-message tracking. The set resets on app restart.
// Screens watch `unread` via ValueListenableBuilder; realtime listeners and
// the chat screen mutate it via mark* methods.
class ChatUnreadService {
  ChatUnreadService._();
  static final ChatUnreadService instance = ChatUnreadService._();

  final ValueNotifier<Set<dynamic>> unread = ValueNotifier<Set<dynamic>>({});

  void markUnread(dynamic bookingId) {
    if (bookingId == null) return;
    if (unread.value.contains(bookingId)) return;
    unread.value = {...unread.value, bookingId};
  }

  void markRead(dynamic bookingId) {
    if (bookingId == null) return;
    if (!unread.value.contains(bookingId)) return;
    unread.value = {...unread.value}..remove(bookingId);
  }

  bool isUnread(dynamic bookingId) => unread.value.contains(bookingId);
}
