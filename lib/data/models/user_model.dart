/// 👤 MODÈLE UTILISATEUR
/// Représente un utilisateur de l'application (médecin, patient, etc.)
class UserModel {
  final String id; // UID Firebase
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String gender; // 'male', 'female', 'other'
  final String? profileImageUrl;
  final UserRole role; // Rôle de l'utilisateur
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  // 🏥 Informations médicales
  final int? height; // Taille en cm
  final int? weight; // Poids en kg
  final String? bloodType; // Groupe sanguin (A+, A-, B+, B-, AB+, AB-, O+, O-)
  final String? medicalConditions; // Conditions médicales
  final String? allergies; // Allergies
  final String? medications; // Médicaments actuels
  final String? emergencyContact; // Contact d'urgence

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    required this.gender,
    this.profileImageUrl,
    this.role = UserRole.patient,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.height,
    this.weight,
    this.bloodType,
    this.medicalConditions,
    this.allergies,
    this.medications,
    this.emergencyContact,
  });

  /// Nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';

  /// Âge calculé à partir de la date de naissance
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Conversion depuis JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      gender: json['gender'] ?? 'other',
      profileImageUrl: json['profileImageUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.patient,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      height: json['height'],
      weight: json['weight'],
      bloodType: json['bloodType'],
      medicalConditions: json['medicalConditions'],
      allergies: json['allergies'],
      medications: json['medications'],
      emergencyContact: json['emergencyContact'],
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'height': height,
      'weight': weight,
      'bloodType': bloodType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'medications': medications,
      'emergencyContact': emergencyContact,
    };
  }

  /// Conversion depuis Firestore
  factory UserModel.fromFirestore(dynamic doc) {
    final Map<String, dynamic> data = doc.data() ?? {};
    return UserModel(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      dateOfBirth: data['dateOfBirth'] != null
          ? DateTime.parse(data['dateOfBirth'])
          : null,
      gender: data['gender'] ?? 'other',
      profileImageUrl: data['profileImageUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.patient,
      ),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      height: data['height'],
      weight: data['weight'],
      bloodType: data['bloodType'],
      medicalConditions: data['medicalConditions'],
      allergies: data['allergies'],
      medications: data['medications'],
      emergencyContact: data['emergencyContact'],
    );
  }

  /// Conversion vers Firestore (pour .set() et .update())
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'height': height,
      'weight': weight,
      'bloodType': bloodType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'medications': medications,
      'emergencyContact': emergencyContact,
    };
  }

  /// Copie avec modification
  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? height,
    int? weight,
    String? bloodType,
    String? medicalConditions,
    String? allergies,
    String? medications,
    String? emergencyContact,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodType: bloodType ?? this.bloodType,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}

/// 🎭 RÔLES UTILISATEURS
enum UserRole {
  patient, // Patient standard
  doctor, // Médecin
  admin, // Administrateur système
}
