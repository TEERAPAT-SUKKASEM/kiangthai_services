import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/chat_unread_service.dart';

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
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: AppColors.onAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
