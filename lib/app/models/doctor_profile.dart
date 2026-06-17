import 'user.dart';

class DoctorProfile {
  final String id;
  final String userId;
  final User user;
  final String specialization;
  final String hospital;
  final int experience;
  final double rating;
  final int reviewCount;
  final double price;
  final String? bio;
  final List<String> education;
  final bool isVerified;
  final bool isOnline;
  final String? practiceAddress;
  final bool isOnlineEnabled;
  final bool isOfflineEnabled;
  final int consultationDuration;

  DoctorProfile({
    required this.id,
    required this.userId,
    required this.user,
    required this.specialization,
    required this.hospital,
    required this.experience,
    this.rating = 0,
    this.reviewCount = 0,
    required this.price,
    this.bio,
    this.education = const [],
    this.isVerified = true,
    this.isOnline = false,
    this.practiceAddress,
    this.isOnlineEnabled = true,
    this.isOfflineEnabled = true,
    this.consultationDuration = 30,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user']?['id'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : User(id: '', name: '', email: '', role: 'doctor', createdAt: ''),
      specialization: json['specialization'] ?? '',
      hospital: json['hospital'] ?? '',
      experience: (json['experience'] ?? 0) is int ? json['experience'] : (json['experience'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: (json['reviewCount'] ?? 0) is int ? json['reviewCount'] : (json['reviewCount'] as num?)?.toInt() ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      bio: json['bio'],
      education: json['education'] != null ? List<String>.from(json['education']) : [],
      isVerified: json['isVerified'] ?? true,
      isOnline: json['isOnline'] ?? false,
      practiceAddress: json['practiceAddress'],
      isOnlineEnabled: json['isOnlineEnabled'] ?? true,
      isOfflineEnabled: json['isOfflineEnabled'] ?? true,
      consultationDuration: json['consultationDuration'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'user': user.toJson(),
    'specialization': specialization,
    'hospital': hospital,
    'experience': experience,
    'rating': rating,
    'reviewCount': reviewCount,
    'price': price,
    'bio': bio,
    'education': education,
    'isVerified': isVerified,
    'isOnline': isOnline,
    'practiceAddress': practiceAddress,
    'isOnlineEnabled': isOnlineEnabled,
    'isOfflineEnabled': isOfflineEnabled,
    'consultationDuration': consultationDuration,
  };
}
