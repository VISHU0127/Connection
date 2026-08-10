import 'package:my_app/screens/medical_info/models/medical_info.dart';
import 'package:my_app/screens/emergency_contacts/models/emergency_contact.dart';

export 'package:my_app/screens/medical_info/models/medical_info.dart';
export 'package:my_app/screens/emergency_contacts/models/emergency_contact.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final MedicalInfo? medicalInfo;
  final List<EmergencyContact> emergencyContacts;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.medicalInfo,
    this.emergencyContacts = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? '1',
        name: json['full_name'] as String? ?? json['name'] as String? ?? 'User',
        email: json['email'] as String? ?? '',
        phone: json['phone_number'] as String? ?? json['phone'] as String? ?? '',
        medicalInfo: json['medical_info'] != null
            ? MedicalInfo.fromJson(json['medical_info'] as Map<String, dynamic>)
            : null,
        emergencyContacts: (json['emergency_contacts'] as List<dynamic>? ?? [])
            .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
            .toList(),
      );


  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        if (medicalInfo != null) 'medical_info': medicalInfo!.toJson(),
        'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
      };

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    MedicalInfo? medicalInfo,
    List<EmergencyContact>? emergencyContacts,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        medicalInfo: medicalInfo ?? this.medicalInfo,
        emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      );
}
