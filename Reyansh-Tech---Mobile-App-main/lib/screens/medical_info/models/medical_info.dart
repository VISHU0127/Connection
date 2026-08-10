class MedicalInfo {
  final String bloodGroup;
  final String allergies;
  final String medicalCondition;

  const MedicalInfo({
    required this.bloodGroup,
    required this.allergies,
    required this.medicalCondition,
  });

  factory MedicalInfo.fromJson(Map<String, dynamic> json) => MedicalInfo(
        bloodGroup: json['blood_group'] as String,
        allergies: json['allergies'] as String,
        medicalCondition: json['medical_condition'] as String,
      );

  Map<String, dynamic> toJson() => {
        'blood_group': bloodGroup,
        'allergies': allergies,
        'medical_condition': medicalCondition,
      };
}