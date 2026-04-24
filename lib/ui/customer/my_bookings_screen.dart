import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../data/models/booking.dart';
import '../chat/chat_screen.dart';
import '../widgets/unread_badge.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  Future<void> _submitRating(
    BuildContext context,
    dynamic bookingId,
    int rating,
    String reviewText,
  ) async {
    try {
      await Supabase.instance.client.from('bookings').update({
        'rating': rating,
        'review_text': reviewText.isEmpty ? null : reviewText,
      }).eq('id', bookingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your review!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save rating: $e')),
        );
      }
    }
  }

  Future<void> _showRatingDialog(BuildContext context, dynamic bookingId) async {
    int selectedRating = 0;
    final reviewController = TextEditingController();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Rate service',
      barrierColor: Colors.black54,
      transitionDuration: AppDurations.med,
      pageBuilder: (ctx, _, _) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate this Service',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'How was your experience?',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final star = i + 1;
                          final active = star <= selectedRating;
                          return IconButton(
                            splashRadius: 24,
                            icon: AnimatedScale(
                              duration: AppDurations.fast,
                              curve: Curves.easeOutBack,
                              scale: active ? 1.15 : 1.0,
                              child: Icon(
                                active
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: const Color(0xFFFBBF24),
                                size: 36,
                              ),
                            ),
                            onPressed: () =>
                                setDialogState(() => selectedRating = star),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: reviewController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Leave a comment (optional)',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: selectedRating == 0
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    _submitRating(
                                      context,
                                      bookingId,
                                      selectedRating,
                                      reviewController.text.trim(),
                                    );
                                  },
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    reviewController.dispose();
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    dynamic bookingId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text('You can rebook anytime from the services page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rejected),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('bookings')
            .update({'status': 'cancelled'})
            .eq('id', bookingId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('bookings')
                  .stream(primaryKey: ['id'])
                  .eq('customer_id', user.id)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _BookingsSkeleton();
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final raw = snapshot.data ?? [];
                if (raw.isEmpty) {
                  return _EmptyState();
                }

                final bookings = raw.map(Booking.fromMap).toList();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _BookingCard(
                      key: ValueKey(booking.id),
                      booking: booking,
                      userId: user.id,
                      onCancel: () => _showCancelDialog(context, booking.id),
                      onRate: () => _showRatingDialog(context, booking.id),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final String userId;
  final VoidCallback onCancel;
  final VoidCallback onRate;
  const _BookingCard({
    super.key,
    required this.booking,
    required this.userId,
    required this.onCancel,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = booking.status == 'cancelled' || booking.status == 'rejected';
    final createdAt = DateTime.tryParse(booking.createdAt)?.toLocal();
    final ageMinutes = createdAt != null
        ? DateTime.now().difference(createdAt).inMinutes
        : 0;
    final isUrgent = booking.status == 'pending' && ageMinutes > 5;
    final statusColor =
        isUrgent ? AppColors.urgentPending : AppColors.forStatus(booking.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tint(statusColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.handyman_rounded, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceType,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                              color: isCancelled ? AppColors.textMuted : AppColors.textPrimary,
                            ),
                      ),
                      if ((booking.subType ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          booking.subType!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusPill(
                  label: isUrgent ? 'Still waiting…' : booking.statusLabel,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  '${booking.bookingDate} · ${booking.bookingTime}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            if (booking.imageUrl != null && booking.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: isCancelled ? 0.4 : 1.0,
                  child: CachedNetworkImage(
                    imageUrl: booking.imageUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    memCacheHeight: 360,
                    fadeInDuration: AppDurations.med,
                    placeholder: (context, url) => Skeletonizer.zone(
                      enabled: true,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(color: AppColors.fieldFill),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: AppColors.fieldFill,
                      child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ],

            if (booking.isActive) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: UnreadBadge(
                  bookingId: booking.id,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          bookingId: booking.id,
                          currentUserId: userId,
                          currentUserRole: 'customer',
                          otherPersonName: 'Technician',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Chat with Technician'),
                  ),
                ),
              ),
            ],
            if (booking.status == 'pending') ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancel Booking'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.rejected),
                ),
              ),
            ],
            if (booking.status == 'completed') ...[
              const SizedBox(height: 14),
              if (booking.rating == null)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onRate,
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Rate this Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24),
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < booking.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFFBBF24),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (booking.reviewText != null && booking.reviewText!.isNotEmpty)
                        Expanded(
                          child: Text(
                            booking.reviewText!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tint(color, 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.tint(AppColors.brand, 0.14),
                    AppColors.tint(AppColors.accent, 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.brand,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No bookings yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Browse services and book your first one.\nYour history will appear here.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsSkeleton extends StatelessWidget {
  const _BookingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Air Conditioning Service',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Sub-service placeholder',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Jan 1 2026 · 10:00',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
