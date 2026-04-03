class Profile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String role;
  final List<String> savedAddresses;

  const Profile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.savedAddresses,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      role: map['role'] as String? ?? 'customer',
      savedAddresses: map['saved_addresses'] != null
          ? List<String>.from(map['saved_addresses'] as List)
          : [],
    );
  }

  Map<String, dynamic> toUpdateMap() => {
    'full_name': fullName,
    'phone_number': phoneNumber,
    'saved_addresses': savedAddresses,
  };

  Profile copyWith({
    String? fullName,
    String? phoneNumber,
    List<String>? savedAddresses,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role,
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }
}
