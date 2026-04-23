import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n.dart';
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
          SnackBar(content: Text(t('bookings.rating_saved'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('common.error')}: $e')),
        );
      }
    }
  }

  Future<void> _showRatingDialog(BuildContext context, dynamic bookingId) async {
    int selectedRating = 0;
    final reviewController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t('bookings.rate_service')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('bookings.rate_title'),
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    icon: Icon(
                      star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFBBF24),
                      size: 38,
                    ),
                    onPressed: () => setDialogState(() => selectedRating = star),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: t('bookings.review_hint'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('common.cancel')),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      _submitRating(
                        context,
                        bookingId,
                        selectedRating,
                        reviewController.text.trim(),
                      );
                    },
              child: Text(t('common.submit')),
            ),
          ],
        ),
      ),
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
        title: Text(t('bookings.cancel_confirm')),
        content: Text(t('bookings.cancel_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('bookings.keep')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rejected),
            child: Text(t('bookings.cancel_booking')),
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
            SnackBar(content: Text(t('bookings.cancelled'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t('common.error')}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(t('bookings.title'))),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${t('common.error')}: ${snapshot.error}'));
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
    required this.booking,
    required this.userId,
    required this.onCancel,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = booking.status == 'cancelled' || booking.status == 'rejected';
    final statusColor = AppColors.forStatus(booking.status);

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
                        tCanonical(booking.serviceType, prefix: 'service'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                              color: isCancelled ? AppColors.textMuted : AppColors.textPrimary,
                            ),
                      ),
                      if ((booking.subType ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tCanonical(booking.subType!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusPill(
                  label: tCanonical(booking.status, prefix: 'status'),
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
                  child: Image.network(
                    booking.imageUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        color: AppColors.fieldFill,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
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
                          otherPersonName: t('common.technician'),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: Text(t('bookings.chat_with_tech')),
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
                  label: Text(t('bookings.cancel_booking')),
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
                    label: Text(t('bookings.rate_service')),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inbox_rounded, color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            t('bookings.empty'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            t('bookings.empty_body'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
