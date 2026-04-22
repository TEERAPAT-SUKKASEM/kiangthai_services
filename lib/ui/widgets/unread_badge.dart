import 'package:flutter/material.dart';
import '../../services/chat_unread_service.dart';

// Shows `child` with a small red dot in the top-right corner when
// `bookingId` is flagged as unread in ChatUnreadService.
class UnreadBadge extends StatelessWidget {
  final dynamic bookingId;
  final Widget child;

  const UnreadBadge({
    super.key,
    required this.bookingId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<dynamic>>(
      valueListenable: ChatUnreadService.instance.unread,
      builder: (context, unread, _) {
        final show = unread.contains(bookingId);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (show)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
