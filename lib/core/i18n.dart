import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Lightweight i18n service. `language` is a ValueNotifier so UI can rebuild via
// ValueListenableBuilder when the user flips the toggle in settings. Dictionary
// lives in _dictionary below — add a row per string you want translated.
//
// Usage:
//   Text(t('nav.services'))               // keyed translation
//   Text(tCanonical('Wiring Repair'))     // translate a canonical English
//                                          // value (e.g. DB enum). Falls back
//                                          // to the input when no key exists.
class I18n {
  I18n._();
  static final I18n instance = I18n._();

  // Current language code ('en' or 'th'). Default English.
  final ValueNotifier<String> language = ValueNotifier<String>('en');

  String translate(String key) {
    final entry = _dictionary[key];
    if (entry == null) return key; // fall back to the key itself
    return entry[language.value] ?? entry['en'] ?? key;
  }

  // Translate a value that is also the canonical (English) form stored in the
  // DB — e.g. booking sub-types like "Wiring Repair". Normalises to a key like
  // `subtype.wiring_repair`; falls back to the original text if no translation
  // exists, which keeps new/unknown strings readable.
  String translateCanonical(String canonical, {String prefix = 'subtype'}) {
    final slug = canonical
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final key = '$prefix.$slug';
    final entry = _dictionary[key];
    if (entry == null) return canonical;
    return entry[language.value] ?? canonical;
  }

  // Load the user's saved preference from profiles.language.
  Future<void> loadForCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('language')
          .eq('id', user.id)
          .maybeSingle();
      final lang = data?['language'] as String?;
      if (lang == 'en' || lang == 'th') {
        language.value = lang!;
      }
    } catch (_) {
      // leave default
    }
  }

  // Update the in-memory language and persist to the user's profile.
  Future<void> setLanguage(String lang) async {
    if (lang != 'en' && lang != 'th') return;
    language.value = lang;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'language': lang})
          .eq('id', user.id);
    } catch (_) {
      // non-fatal
    }
  }

  static const Map<String, Map<String, String>> _dictionary = {
    // ---------- Navigation / shell ----------
    'nav.services': {'en': 'Services', 'th': 'บริการ'},
    'nav.my_bookings': {'en': 'My Bookings', 'th': 'การจองของฉัน'},
    'nav.profile': {'en': 'Profile', 'th': 'โปรไฟล์'},

    // ---------- Common ----------
    'common.cancel': {'en': 'Cancel', 'th': 'ยกเลิก'},
    'common.ok': {'en': 'OK', 'th': 'ตกลง'},
    'common.delete': {'en': 'Delete', 'th': 'ลบ'},
    'common.save': {'en': 'Save', 'th': 'บันทึก'},
    'common.submit': {'en': 'Submit', 'th': 'ส่ง'},
    'common.error': {'en': 'Error', 'th': 'ข้อผิดพลาด'},
    'common.view': {'en': 'View', 'th': 'ดู'},
    'common.customer': {'en': 'Customer', 'th': 'ลูกค้า'},
    'common.technician': {'en': 'Technician', 'th': 'ช่าง'},

    // ---------- Customer home ----------
    'home.greeting': {'en': 'Hello', 'th': 'สวัสดี'},
    'home.subtitle': {
      'en': 'What service do you need today?',
      'th': 'วันนี้คุณต้องการบริการอะไร?',
    },
    'home.our_services': {'en': 'Our Services', 'th': 'บริการของเรา'},
    'home.available_suffix': {'en': 'available', 'th': 'รายการ'},
    'home.book_now': {'en': 'Book now', 'th': 'จองเลย'},
    'home.promo_title': {
      'en': 'Trusted home services',
      'th': 'บริการถึงบ้านที่เชื่อถือได้',
    },
    'home.promo_body': {
      'en': 'Book verified technicians in minutes.',
      'th': 'จองช่างที่ตรวจสอบแล้วภายในไม่กี่นาที',
    },
    'home.trust.verified': {'en': 'Verified', 'th': 'ตรวจสอบแล้ว'},
    'home.trust.rating': {'en': 'Rating', 'th': 'คะแนน'},
    'home.trust.response': {'en': 'Response', 'th': 'ตอบกลับ'},
    'service.ac': {'en': 'AC', 'th': 'แอร์'},
    'service.electrical': {'en': 'Electrical', 'th': 'ไฟฟ้า'},
    'service.solar': {'en': 'Solar', 'th': 'โซลาร์เซลล์'},
    'service.cctv': {'en': 'CCTV', 'th': 'กล้องวงจรปิด'},
    'service.water_pump': {'en': 'Water Pump', 'th': 'ปั๊มน้ำ'},
    'service.electronics': {'en': 'Electronics', 'th': 'เครื่องใช้ไฟฟ้า'},

    // ---------- Login / signup ----------
    'login.hero_title': {
      'en': 'Home services,\nmade simple.',
      'th': 'บริการถึงบ้าน\nง่ายกว่าที่เคย',
    },
    'login.hero_subtitle': {
      'en': 'Book trusted technicians for AC, electrical, solar, and more.',
      'th': 'จองช่างที่เชื่อถือได้สำหรับแอร์ ไฟฟ้า โซลาร์ และอื่นๆ',
    },
    'login.tab_login': {'en': 'Log In', 'th': 'เข้าสู่ระบบ'},
    'login.tab_signup': {'en': 'Sign Up', 'th': 'สมัครสมาชิก'},
    'login.welcome_back': {'en': 'Welcome back', 'th': 'ยินดีต้อนรับกลับ'},
    'login.log_in_to_continue': {
      'en': 'Log in to continue',
      'th': 'เข้าสู่ระบบเพื่อดำเนินการต่อ',
    },
    'login.email': {'en': 'Email', 'th': 'อีเมล'},
    'login.password': {'en': 'Password', 'th': 'รหัสผ่าน'},
    'login.enter_email': {'en': 'Enter your email', 'th': 'กรอกอีเมลของคุณ'},
    'login.invalid_email': {
      'en': 'Invalid email address',
      'th': 'อีเมลไม่ถูกต้อง',
    },
    'login.enter_password': {
      'en': 'Enter your password',
      'th': 'กรอกรหัสผ่านของคุณ',
    },
    'login.log_in': {'en': 'Log In', 'th': 'เข้าสู่ระบบ'},
    'login.forgot_password': {
      'en': 'Forgot password?',
      'th': 'ลืมรหัสผ่าน?',
    },
    'login.reset_password': {'en': 'Reset password', 'th': 'รีเซ็ตรหัสผ่าน'},
    'login.reset_body': {
      'en': 'Enter the email on your account. We\'ll send you a reset link.',
      'th': 'กรอกอีเมลของบัญชีคุณ เราจะส่งลิงก์รีเซ็ตไปให้',
    },
    'login.send': {'en': 'Send', 'th': 'ส่ง'},
    'login.reset_sent_prefix': {
      'en': 'Reset link sent to',
      'th': 'ส่งลิงก์รีเซ็ตไปที่',
    },
    'signup.create_account': {'en': 'Create an account', 'th': 'สร้างบัญชี'},
    'signup.join': {
      'en': 'Join Kiang Thai Service',
      'th': 'เข้าร่วม Kiang Thai Service',
    },
    'signup.full_name': {'en': 'Full Name', 'th': 'ชื่อ-นามสกุล'},
    'signup.phone': {'en': 'Phone', 'th': 'เบอร์โทรศัพท์'},
    'signup.enter_name': {'en': 'Enter your name', 'th': 'กรอกชื่อของคุณ'},
    'signup.enter_phone': {
      'en': 'Enter your phone',
      'th': 'กรอกเบอร์โทรศัพท์ของคุณ',
    },
    'signup.password_new': {'en': 'Enter a password', 'th': 'กรอกรหัสผ่าน'},
    'signup.password_min': {
      'en': 'At least 6 characters',
      'th': 'อย่างน้อย 6 ตัวอักษร',
    },
    'signup.i_am_a': {'en': 'I am a', 'th': 'ฉันคือ'},
    'signup.submit': {'en': 'Create Account', 'th': 'สร้างบัญชี'},
    'signup.success': {
      'en': 'Account created. Please log in.',
      'th': 'สร้างบัญชีเรียบร้อย กรุณาเข้าสู่ระบบ',
    },

    // ---------- Profile settings ----------
    'settings.title': {'en': 'Profile Settings', 'th': 'ตั้งค่าโปรไฟล์'},
    'settings.personal_info': {
      'en': 'Personal Information',
      'th': 'ข้อมูลส่วนตัว',
    },
    'settings.full_name': {'en': 'Full Name', 'th': 'ชื่อ-นามสกุล'},
    'settings.phone': {'en': 'Phone Number', 'th': 'เบอร์โทรศัพท์'},
    'settings.saved_addresses': {
      'en': 'Saved Addresses',
      'th': 'ที่อยู่ที่บันทึกไว้',
    },
    'settings.add_address': {'en': 'Add Address', 'th': 'เพิ่มที่อยู่'},
    'settings.no_addresses': {
      'en': 'No saved addresses yet',
      'th': 'ยังไม่มีที่อยู่ที่บันทึกไว้',
    },
    'settings.edit_address': {'en': 'Edit Address', 'th': 'แก้ไขที่อยู่'},
    'settings.new_address': {'en': 'Add New Address', 'th': 'เพิ่มที่อยู่ใหม่'},
    'settings.enter_address': {
      'en': 'Enter your address',
      'th': 'กรอกที่อยู่ของคุณ',
    },
    'settings.confirm_delete': {'en': 'Confirm Delete', 'th': 'ยืนยันการลบ'},
    'settings.confirm_delete_body': {
      'en': 'Remove this address from your list?',
      'th': 'ลบที่อยู่นี้ออกจากรายการของคุณ?',
    },
    'settings.save_all': {'en': 'Save All Changes', 'th': 'บันทึกทั้งหมด'},
    'settings.sign_out': {'en': 'Sign Out', 'th': 'ออกจากระบบ'},
    'settings.language': {'en': 'Language', 'th': 'ภาษา'},
    'settings.language_english': {'en': 'English', 'th': 'อังกฤษ'},
    'settings.language_thai': {'en': 'Thai', 'th': 'ไทย'},
    'settings.profile_saved': {
      'en': 'Profile saved successfully!',
      'th': 'บันทึกโปรไฟล์เรียบร้อย!',
    },
    'settings.profile_load_failed': {
      'en': 'Failed to load profile',
      'th': 'โหลดโปรไฟล์ไม่สำเร็จ',
    },
    'settings.profile_save_failed': {
      'en': 'Failed to save profile',
      'th': 'บันทึกโปรไฟล์ไม่สำเร็จ',
    },

    // ---------- Booking status labels ----------
    'status.pending': {'en': 'Waiting for Technician', 'th': 'รอช่าง'},
    'status.accepted': {'en': 'Technician Accepted', 'th': 'ช่างรับงานแล้ว'},
    'status.on_the_way': {'en': 'Technician on the Way', 'th': 'ช่างกำลังมา'},
    'status.in_progress': {'en': 'In Progress', 'th': 'กำลังดำเนินการ'},
    'status.completed': {'en': 'Completed', 'th': 'เสร็จสิ้น'},
    'status.cancelled': {'en': 'Cancelled', 'th': 'ยกเลิกแล้ว'},
    'status.rejected': {'en': 'Rejected', 'th': 'ถูกปฏิเสธ'},

    // ---------- My bookings (customer) ----------
    'bookings.title': {'en': 'My Bookings', 'th': 'การจองของฉัน'},
    'bookings.empty': {'en': 'No bookings yet', 'th': 'ยังไม่มีการจอง'},
    'bookings.empty_body': {
      'en': 'Your bookings will appear here.',
      'th': 'การจองของคุณจะแสดงที่นี่',
    },
    'bookings.chat_with_tech': {
      'en': 'Chat with Technician',
      'th': 'แชทกับช่าง',
    },
    'bookings.cancel_booking': {'en': 'Cancel Booking', 'th': 'ยกเลิกการจอง'},
    'bookings.cancel_confirm': {
      'en': 'Cancel this booking?',
      'th': 'ยกเลิกการจองนี้?',
    },
    'bookings.cancel_body': {
      'en': 'You won\'t be able to undo this.',
      'th': 'คุณจะไม่สามารถเรียกคืนได้',
    },
    'bookings.keep': {'en': 'Keep', 'th': 'เก็บไว้'},
    'bookings.rate_service': {'en': 'Rate Service', 'th': 'ให้คะแนนบริการ'},
    'bookings.rate_title': {
      'en': 'Rate your experience',
      'th': 'ให้คะแนนประสบการณ์ของคุณ',
    },
    'bookings.review_hint': {
      'en': 'Leave a review (optional)',
      'th': 'รีวิว (ไม่บังคับ)',
    },
    'bookings.your_rating': {'en': 'Your rating', 'th': 'คะแนนของคุณ'},
    'bookings.booking_update': {'en': 'Booking update', 'th': 'อัปเดตการจอง'},
    'bookings.cancelled': {
      'en': 'Booking cancelled',
      'th': 'ยกเลิกการจองเรียบร้อย',
    },
    'bookings.rating_saved': {
      'en': 'Thanks for your feedback!',
      'th': 'ขอบคุณสำหรับความคิดเห็น!',
    },
    // Booking update messages (customer)
    'notify.accepted': {
      'en': 'Technician has accepted your job!',
      'th': 'ช่างรับงานของคุณแล้ว!',
    },
    'notify.on_the_way': {
      'en': 'Technician is on the way!',
      'th': 'ช่างกำลังเดินทางมา!',
    },
    'notify.in_progress': {
      'en': 'Technician has started the job!',
      'th': 'ช่างเริ่มทำงานแล้ว!',
    },
    'notify.completed': {'en': 'Job completed!', 'th': 'งานเสร็จสมบูรณ์!'},
    'notify.rejected': {
      'en': 'Technician rejected the job. Please rebook.',
      'th': 'ช่างปฏิเสธงาน กรุณาจองใหม่',
    },
    'notify.status_changed': {
      'en': 'Booking status changed',
      'th': 'สถานะการจองเปลี่ยนแล้ว',
    },

    // ---------- Technician ----------
    'tech.new_jobs': {'en': 'New Jobs', 'th': 'งานใหม่'},
    'tech.my_jobs': {'en': 'My Jobs', 'th': 'งานของฉัน'},
    'tech.no_new_jobs': {
      'en': 'No new jobs available',
      'th': 'ยังไม่มีงานใหม่',
    },
    'tech.no_my_jobs': {'en': 'No active jobs', 'th': 'ไม่มีงานที่กำลังทำ'},
    'tech.reject_confirm': {'en': 'Reject this job?', 'th': 'ปฏิเสธงานนี้?'},
    'tech.reject_body': {
      'en': 'You won\'t be able to undo this action.',
      'th': 'คุณจะไม่สามารถย้อนกลับการดำเนินการนี้ได้',
    },
    'tech.reject': {'en': 'Reject', 'th': 'ปฏิเสธ'},
    'tech.accept_job': {'en': 'Accept Job', 'th': 'รับงาน'},
    'tech.complete_confirm': {'en': 'Complete this job?', 'th': 'ปิดงานนี้?'},
    'tech.complete_body': {
      'en': 'Mark this job as fully completed.',
      'th': 'ทำเครื่องหมายว่างานเสร็จสมบูรณ์',
    },
    'tech.complete': {'en': 'Complete', 'th': 'เสร็จสิ้น'},
    'tech.on_my_way': {'en': 'On My Way', 'th': 'กำลังไป'},
    'tech.arrived': {'en': 'Arrived', 'th': 'ถึงแล้ว'},
    'tech.close_job': {'en': 'Close Job', 'th': 'ปิดงาน'},
    'tech.chat': {'en': 'Chat', 'th': 'แชท'},
    'tech.job_accepted': {'en': 'Job accepted', 'th': 'รับงานเรียบร้อย'},
    'tech.job_rejected': {'en': 'Job rejected', 'th': 'ปฏิเสธงานเรียบร้อย'},
    'tech.updated_on_the_way': {
      'en': 'Updated: On the way to customer',
      'th': 'อัปเดต: กำลังไปหาลูกค้า',
    },
    'tech.updated_in_progress': {
      'en': 'Updated: Work in progress',
      'th': 'อัปเดต: กำลังทำงาน',
    },
    'tech.updated_completed': {
      'en': 'Job closed. Great work!',
      'th': 'ปิดงานเรียบร้อย ทำได้ดี!',
    },
    'tech.status_updated': {'en': 'Status updated', 'th': 'อัปเดตสถานะแล้ว'},
    'tech.new_job_title': {'en': 'New job available', 'th': 'มีงานใหม่'},
    'tech.new_job_body': {
      'en': 'A new booking is waiting for a technician.',
      'th': 'มีการจองใหม่รอช่าง',
    },
    'tech.history_show': {'en': 'Show History', 'th': 'แสดงประวัติ'},
    'tech.history_hide': {'en': 'Hide History', 'th': 'ซ่อนประวัติ'},

    // Stage indicator
    'stage.accepted': {'en': 'Accepted', 'th': 'รับแล้ว'},
    'stage.on_the_way': {'en': 'On the Way', 'th': 'กำลังมา'},
    'stage.in_progress': {'en': 'In Progress', 'th': 'กำลังทำ'},
    'stage.completed': {'en': 'Completed', 'th': 'เสร็จสิ้น'},

    // ---------- Chat ----------
    'chat.type_message': {'en': 'Type a message...', 'th': 'พิมพ์ข้อความ...'},
    'chat.empty': {
      'en': 'No messages yet. Start the conversation!',
      'th': 'ยังไม่มีข้อความ เริ่มต้นการสนทนา!',
    },
    'chat.failed_send': {
      'en': 'Failed to send message',
      'th': 'ส่งข้อความไม่สำเร็จ',
    },
    'chat.new_message': {'en': 'New message', 'th': 'ข้อความใหม่'},

    // ---------- Shared booking form ----------
    'booking.location_contact': {
      'en': 'Location & Contact',
      'th': 'สถานที่และการติดต่อ',
    },
    'booking.full_name': {'en': 'Full Name', 'th': 'ชื่อ-นามสกุล'},
    'booking.phone': {'en': 'Phone', 'th': 'เบอร์โทรศัพท์'},
    'booking.saved_address': {
      'en': 'Saved address',
      'th': 'ที่อยู่ที่บันทึกไว้',
    },
    'booking.job_site_address': {
      'en': 'Job site address',
      'th': 'ที่อยู่หน้างาน',
    },
    'booking.save_address': {'en': 'Save address', 'th': 'บันทึกที่อยู่'},
    'booking.select_date_time': {
      'en': 'Select Date & Time',
      'th': 'เลือกวันและเวลา',
    },
    'booking.preferred_time': {'en': 'Preferred Time', 'th': 'เวลาที่สะดวก'},
    'booking.morning': {'en': 'Morning', 'th': 'เช้า'},
    'booking.afternoon': {'en': 'Afternoon', 'th': 'บ่าย'},
    'booking.select_date_first': {
      'en': 'Please select a date first',
      'th': 'กรุณาเลือกวันก่อน',
    },
    'booking.service_type': {'en': 'Service Type', 'th': 'ประเภทบริการ'},
    'booking.take_photo': {
      'en': 'Take photo / Attach job site image',
      'th': 'ถ่ายรูป / แนบรูปหน้างาน',
    },
    'booking.image_attached': {
      'en': 'Image attached (tap to change)',
      'th': 'แนบรูปแล้ว (กดเพื่อเปลี่ยน)',
    },
    'booking.confirm_booking': {
      'en': 'Confirm Booking',
      'th': 'ยืนยันการจอง',
    },
    'booking.fill_required': {
      'en': 'Please fill in all required fields',
      'th': 'กรุณากรอกข้อมูลที่จำเป็นทั้งหมด',
    },
    'booking.saving': {
      'en': 'Saving booking...',
      'th': 'กำลังบันทึกการจอง...',
    },
    'booking.slot_full': {
      'en': 'This time slot is now full, please choose another',
      'th': 'ช่วงเวลานี้เต็มแล้ว กรุณาเลือกเวลาอื่น',
    },
    'booking.confirmed': {
      'en': 'Booking confirmed!',
      'th': 'ยืนยันการจองเรียบร้อย!',
    },
    'booking.address_saved': {
      'en': 'Address saved successfully!',
      'th': 'บันทึกที่อยู่เรียบร้อย!',
    },
    'booking.details_suffix': {'en': 'Details', 'th': 'รายละเอียด'},

    // Per-service titles
    'booking.title.ac': {'en': 'Book AC Service', 'th': 'จองบริการแอร์'},
    'booking.title.electrical': {
      'en': 'Book Electrical Service',
      'th': 'จองบริการไฟฟ้า',
    },
    'booking.title.solar': {
      'en': 'Book Solar Service',
      'th': 'จองบริการโซลาร์เซลล์',
    },
    'booking.title.cctv': {
      'en': 'Book CCTV Service',
      'th': 'จองบริการกล้องวงจรปิด',
    },
    'booking.title.water_pump': {
      'en': 'Book Water Pump Service',
      'th': 'จองบริการปั๊มน้ำ',
    },
    'booking.title.electronics': {
      'en': 'Book Electronics Service',
      'th': 'จองบริการเครื่องใช้ไฟฟ้า',
    },

    // AC-specific
    'ac.btu_size': {'en': 'BTU Size', 'th': 'ขนาด BTU'},
    'ac.btu_unknown': {
      'en': 'Unknown / Not Sure',
      'th': 'ไม่ทราบ / ไม่แน่ใจ',
    },
    'ac.units': {'en': 'Number of Units', 'th': 'จำนวนเครื่อง'},
    'ac.repair_details': {'en': 'Repair Details', 'th': 'รายละเอียดการซ่อม'},
    'ac.issue_hint': {
      'en': 'Describe the issue (e.g. not cooling, water dripping)',
      'th': 'อธิบายปัญหา (เช่น ไม่เย็น น้ำหยด)',
    },
    'ac.describe_issue': {
      'en': 'Please describe the issue',
      'th': 'กรุณาอธิบายปัญหา',
    },

    // ---------- Canonical subtype translations ----------
    // Used by I18n.translateCanonical() — slug = lowercase, non-alphanum → _
    // AC
    'subtype.ac_cleaning': {'en': 'AC Cleaning', 'th': 'ล้างแอร์'},
    'subtype.ac_repair': {'en': 'AC Repair', 'th': 'ซ่อมแอร์'},
    'subtype.ac_installation': {'en': 'AC Installation', 'th': 'ติดตั้งแอร์'},
    'subtype.ac_relocation': {'en': 'AC Relocation', 'th': 'ย้ายแอร์'},
    // Electrical
    'subtype.wiring_repair': {'en': 'Wiring Repair', 'th': 'ซ่อมระบบสายไฟ'},
    'subtype.outlet_switch_install': {
      'en': 'Outlet / Switch Install',
      'th': 'ติดตั้งปลั๊ก / สวิตช์',
    },
    'subtype.circuit_breaker': {'en': 'Circuit Breaker', 'th': 'เซอร์กิตเบรกเกอร์'},
    'subtype.electrical_inspection': {
      'en': 'Electrical Inspection',
      'th': 'ตรวจระบบไฟฟ้า',
    },
    // Solar
    'subtype.panel_installation': {
      'en': 'Panel Installation',
      'th': 'ติดตั้งแผงโซลาร์',
    },
    'subtype.panel_maintenance': {
      'en': 'Panel Maintenance',
      'th': 'บำรุงรักษาแผงโซลาร์',
    },
    'subtype.inverter_repair': {
      'en': 'Inverter Repair',
      'th': 'ซ่อมอินเวอร์เตอร์',
    },
    'subtype.system_consultation': {
      'en': 'System Consultation',
      'th': 'ปรึกษาระบบ',
    },
    // CCTV
    'subtype.new_installation': {
      'en': 'New Installation',
      'th': 'ติดตั้งใหม่',
    },
    'subtype.camera_repair': {'en': 'Camera Repair', 'th': 'ซ่อมกล้อง'},
    'subtype.camera_replacement': {
      'en': 'Camera Replacement',
      'th': 'เปลี่ยนกล้อง',
    },
    'subtype.system_upgrade': {'en': 'System Upgrade', 'th': 'อัปเกรดระบบ'},
    // Water pump
    'subtype.installation': {'en': 'Installation', 'th': 'ติดตั้ง'},
    'subtype.repair': {'en': 'Repair', 'th': 'ซ่อม'},
    'subtype.replacement': {'en': 'Replacement', 'th': 'เปลี่ยน'},
    'subtype.maintenance': {'en': 'Maintenance', 'th': 'บำรุงรักษา'},
    // Electronics
    'subtype.tv_repair': {'en': 'TV Repair', 'th': 'ซ่อมทีวี'},
    'subtype.washing_machine': {'en': 'Washing Machine', 'th': 'เครื่องซักผ้า'},
    'subtype.refrigerator': {'en': 'Refrigerator', 'th': 'ตู้เย็น'},
    'subtype.other_appliance': {
      'en': 'Other Appliance',
      'th': 'เครื่องใช้ไฟฟ้าอื่นๆ',
    },

    // Extra field labels — keys derived from canonical English slugs so
    // service_booking_screen can just tCanonical(label, prefix: 'field').
    'field.describe_the_issue': {
      'en': 'Describe the issue',
      'th': 'อธิบายปัญหา',
    },
    'field.additional_details': {
      'en': 'Additional details',
      'th': 'รายละเอียดเพิ่มเติม',
    },
    'field.roof_type': {'en': 'Roof Type', 'th': 'ประเภทหลังคา'},
    'field.number_of_panels_if_applicable': {
      'en': 'Number of Panels (if applicable)',
      'th': 'จำนวนแผง (ถ้ามี)',
    },
    'field.number_of_cameras': {
      'en': 'Number of Cameras',
      'th': 'จำนวนกล้อง',
    },
    'field.location_type': {'en': 'Location Type', 'th': 'ประเภทตำแหน่ง'},
    'field.pump_type': {'en': 'Pump Type', 'th': 'ประเภทปั๊ม'},
    'field.brand_model': {'en': 'Brand / Model', 'th': 'ยี่ห้อ / รุ่น'},

    // Dropdown options
    'opt.concrete': {'en': 'Concrete', 'th': 'คอนกรีต'},
    'opt.metal_sheet': {'en': 'Metal Sheet', 'th': 'เมทัลชีท'},
    'opt.tile': {'en': 'Tile', 'th': 'กระเบื้อง'},
    'opt.other': {'en': 'Other', 'th': 'อื่นๆ'},
    'opt.indoor': {'en': 'Indoor', 'th': 'ในอาคาร'},
    'opt.outdoor': {'en': 'Outdoor', 'th': 'นอกอาคาร'},
    'opt.both': {'en': 'Both', 'th': 'ทั้งสอง'},
    'opt.submersible': {'en': 'Submersible', 'th': 'ปั๊มแช่'},
    'opt.centrifugal': {'en': 'Centrifugal', 'th': 'ปั๊มหอยโข่ง'},
    'opt.jet_pump': {'en': 'Jet Pump', 'th': 'ปั๊มเจ็ท'},
    'opt.booster_pump': {'en': 'Booster Pump', 'th': 'ปั๊มเพิ่มแรงดัน'},
    'opt.not_sure': {'en': 'Not Sure', 'th': 'ไม่แน่ใจ'},
  };
}

// Convenience top-level helpers.
String t(String key) => I18n.instance.translate(key);
String tCanonical(String canonical, {String prefix = 'subtype'}) =>
    I18n.instance.translateCanonical(canonical, prefix: prefix);
