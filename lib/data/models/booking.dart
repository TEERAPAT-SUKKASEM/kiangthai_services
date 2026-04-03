class Booking {
  final dynamic id;
  final String customerId;
  final String? technicianId;
  final String serviceType;
  final Map<String, dynamic> serviceDetails;
  final String bookingDate;
  final String bookingTime;
  final String status;
  final String? imageUrl;
  final String createdAt;

  const Booking({
    required this.id,
    required this.customerId,
    this.technicianId,
    required this.serviceType,
    required this.serviceDetails,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    this.imageUrl,
    required this.createdAt,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      customerId: map['customer_id'] as String,
      technicianId: map['technician_id'] as String?,
      serviceType: map['service_type'] as String? ?? '',
      serviceDetails: map['service_details'] as Map<String, dynamic>? ?? {},
      bookingDate: map['booking_date'] as String? ?? '',
      bookingTime: (map['booking_time'] as String? ?? '').length >= 5
          ? (map['booking_time'] as String).substring(0, 5)
          : map['booking_time'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  String get statusLabel => switch (status) {
    'pending' => 'Waiting for Technician',
    'accepted' => 'Technician Accepted',
    'on_the_way' => 'Technician on the Way',
    'in_progress' => 'In Progress',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    'rejected' => 'Rejected',
    _ => status,
  };

  bool get isActive =>
      status == 'accepted' ||
      status == 'on_the_way' ||
      status == 'in_progress';

  String? get subType => serviceDetails['sub_type'] as String?;
  String? get contactName => serviceDetails['contact_name'] as String?;
  String? get contactPhone => serviceDetails['contact_phone'] as String?;
  String? get address => serviceDetails['address'] as String?;
  String? get btu => serviceDetails['btu'] as String?;
  String? get count => serviceDetails['count']?.toString();
  String? get symptoms => serviceDetails['symptoms'] as String?;
}
