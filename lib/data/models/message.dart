class Message {
  final String id;
  final dynamic bookingId;
  final String senderId;
  final String senderRole;
  final String content;
  final String createdAt;

  const Message({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      bookingId: map['booking_id'],
      senderId: map['sender_id'] as String,
      senderRole: map['sender_role'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
