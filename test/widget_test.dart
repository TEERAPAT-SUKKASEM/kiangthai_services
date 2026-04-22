import 'package:flutter_test/flutter_test.dart';
import 'package:kiangthai_services/data/models/booking.dart';

void main() {
  group('Booking.fromMap', () {
    test('parses a typical Supabase row', () {
      final booking = Booking.fromMap({
        'id': 'abc-123',
        'customer_id': 'cust-1',
        'technician_id': null,
        'service_type': 'AC',
        'service_details': {
          'sub_type': 'AC Cleaning',
          'btu': '12,000 BTU',
          'count': '2',
          'contact_name': 'John Doe',
          'contact_phone': '0800000000',
          'address': '123 Main St',
        },
        'booking_date': '2026-05-01',
        'booking_time': '09:30:00',
        'status': 'pending',
        'image_url': null,
        'created_at': '2026-04-22T10:00:00Z',
      });

      expect(booking.customerId, 'cust-1');
      expect(booking.technicianId, isNull);
      expect(booking.serviceType, 'AC');
      expect(booking.subType, 'AC Cleaning');
      expect(booking.btu, '12,000 BTU');
      expect(booking.count, '2');
      expect(booking.contactName, 'John Doe');
      expect(booking.bookingTime, '09:30');
      expect(booking.status, 'pending');
      expect(booking.statusLabel, 'Waiting for Technician');
      expect(booking.isActive, isFalse);
    });

    test('handles missing optional fields with sane defaults', () {
      final booking = Booking.fromMap({
        'id': 1,
        'customer_id': 'cust-1',
        'created_at': '2026-04-22T10:00:00Z',
      });

      expect(booking.serviceType, '');
      expect(booking.serviceDetails, isEmpty);
      expect(booking.bookingDate, '');
      expect(booking.bookingTime, '');
      expect(booking.status, 'pending');
      expect(booking.subType, isNull);
    });

    test('isActive is true for accepted/on_the_way/in_progress', () {
      Booking withStatus(String s) => Booking.fromMap({
        'id': 1,
        'customer_id': 'c',
        'status': s,
        'created_at': '',
      });

      expect(withStatus('accepted').isActive, isTrue);
      expect(withStatus('on_the_way').isActive, isTrue);
      expect(withStatus('in_progress').isActive, isTrue);
      expect(withStatus('completed').isActive, isFalse);
      expect(withStatus('pending').isActive, isFalse);
      expect(withStatus('cancelled').isActive, isFalse);
    });

    test('statusLabel falls back to raw value for unknown status', () {
      final booking = Booking.fromMap({
        'id': 1,
        'customer_id': 'c',
        'status': 'something_new',
        'created_at': '',
      });
      expect(booking.statusLabel, 'something_new');
    });
  });
}
