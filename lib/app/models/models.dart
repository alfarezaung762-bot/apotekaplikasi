// Models for MedConnect Flutter App

// ── PatientProfile ──────────────────────────────────────────
class PatientProfile {
  final String id;
  final String userId;
  final String? phone;
  final String? address;
  final String? dateOfBirth;

  PatientProfile({required this.id, required this.userId, this.phone, this.address, this.dateOfBirth});

  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    phone: json['phone'],
    address: json['address'],
    dateOfBirth: json['dateOfBirth'],
  );
}

// ── Appointment ─────────────────────────────────────────────
class AppointmentDoctor {
  final String id;
  final String userId;
  final String specialization;
  final String hospital;
  final double price;
  final AppointmentUser user;

  AppointmentDoctor({required this.id, required this.userId, required this.specialization, required this.hospital, required this.price, required this.user});

  factory AppointmentDoctor.fromJson(Map<String, dynamic> json) => AppointmentDoctor(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    specialization: json['specialization'] ?? '',
    hospital: json['hospital'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    user: AppointmentUser.fromJson(json['user'] ?? {}),
  );
}

class AppointmentPatient {
  final String id;
  final String userId;
  final AppointmentUser user;

  AppointmentPatient({required this.id, required this.userId, required this.user});

  factory AppointmentPatient.fromJson(Map<String, dynamic> json) => AppointmentPatient(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    user: AppointmentUser.fromJson(json['user'] ?? {}),
  );
}

class AppointmentUser {
  final String id;
  final String name;
  final String email;

  AppointmentUser({required this.id, required this.name, required this.email});

  factory AppointmentUser.fromJson(Map<String, dynamic> json) => AppointmentUser(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Unknown',
    email: json['email'] ?? '',
  );
}

class Appointment {
  final String id;
  final String patientId;
  final AppointmentPatient? patient;
  final String doctorId;
  final AppointmentDoctor? doctor;
  final String date;
  final String time;
  final String type;
  final String status;
  final String? complaint;
  final String? diagnosis;
  final String? notes;
  final String? practiceAddress;
  final String createdAt;

  Appointment({
    required this.id, required this.patientId, this.patient,
    required this.doctorId, this.doctor, required this.date,
    required this.time, required this.type, required this.status,
    this.complaint, this.diagnosis, this.notes, this.practiceAddress,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] ?? '',
    patientId: json['patientId'] ?? '',
    patient: json['patient'] != null ? AppointmentPatient.fromJson(json['patient']) : null,
    doctorId: json['doctorId'] ?? '',
    doctor: json['doctor'] != null ? AppointmentDoctor.fromJson(json['doctor']) : null,
    date: json['date'] ?? '',
    time: json['time'] ?? '',
    type: (json['type'] ?? 'online').toString().toLowerCase(),
    status: (json['status'] ?? 'pending').toString().toLowerCase(),
    complaint: json['complaint'],
    diagnosis: json['diagnosis'],
    notes: json['notes'],
    practiceAddress: json['practiceAddress'],
    createdAt: json['createdAt'] ?? '',
  );

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming => isPending || isConfirmed;
}

// ── ChatMessage ─────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String type;
  final bool isRead;
  final String createdAt;

  ChatMessage({
    required this.id, required this.senderId, required this.receiverId,
    required this.content, this.type = 'TEXT', this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    senderId: json['senderId'] ?? '',
    receiverId: json['receiverId'] ?? '',
    content: json['content'] ?? '',
    type: json['type'] ?? 'TEXT',
    isRead: json['isRead'] ?? false,
    createdAt: json['createdAt'] ?? '',
  );
}

// ── Notification ────────────────────────────────────────────
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id, required this.userId, required this.title,
    required this.message, this.type = 'INFO', this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    type: json['type'] ?? 'INFO',
    isRead: json['isRead'] ?? false,
    createdAt: json['createdAt'] ?? '',
  );
}

// ── PaymentTransaction ──────────────────────────────────────
class PaymentTransaction {
  final String id;
  final String userId;
  final String type;         // APPOINTMENT, ORDER
  final String? referenceId;
  final double amount;
  final String status;       // PENDING, PAID, FAILED
  final String? paymentMethod;
  final String createdAt;

  PaymentTransaction({
    required this.id, required this.userId, required this.type,
    this.referenceId, required this.amount, required this.status,
    this.paymentMethod, required this.createdAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => PaymentTransaction(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    type: json['type'] ?? '',
    referenceId: json['referenceId'],
    amount: (json['amount'] ?? 0).toDouble(),
    status: json['status'] ?? 'PENDING',
    paymentMethod: json['paymentMethod'],
    createdAt: json['createdAt'] ?? '',
  );

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PAID': case 'SUCCESS': return 'Berhasil';
      case 'PENDING': return 'Menunggu';
      case 'FAILED': return 'Gagal';
      default: return status;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'APPOINTMENT': return 'Konsultasi Dokter';
      case 'ORDER': return 'Pembelian Obat';
      default: return type;
    }
  }
}

// ── TimeSlot ────────────────────────────────────────────────
class TimeSlot {
  final String id;
  final String doctorId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool isBooked;

  TimeSlot({
    required this.id, required this.doctorId, required this.date,
    required this.startTime, required this.endTime,
    this.isActive = true, this.isBooked = false,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    id: json['id'] ?? '',
    doctorId: json['doctorId'] ?? '',
    date: _parseDate(json['date']),
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
    isActive: json['isActive'] ?? true,
    isBooked: json['isBooked'] ?? false,
  );

  static String _parseDate(dynamic d) {
    if (d == null) return '';
    if (d is String) return d.contains('T') ? d.split('T')[0] : d;
    return d.toString();
  }
}

// ── SimpleUser (for chat contacts) ──────────────────────────
class SimpleUser {
  final String id;
  final String name;
  final String email;
  final String role;

  SimpleUser({required this.id, required this.name, required this.email, required this.role});

  factory SimpleUser.fromJson(Map<String, dynamic> json) => SimpleUser(
    id: json['id'] ?? '',
    name: json['name'] ?? 'User',
    email: json['email'] ?? '',
    role: json['role'] ?? '',
  );
}

// ── Medicine ────────────────────────────────────────────────
class Medicine {
  final String id;
  final String name;
  final String genericName;
  final String description;
  final String category;
  final double price;
  final int stock;
  final String unit;
  final bool requiresPrescription;
  final String image;
  final String pharmacyId;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.unit,
    required this.requiresPrescription,
    required this.image,
    required this.pharmacyId,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    genericName: json['genericName'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    stock: json['stock'] ?? 0,
    unit: json['unit'] ?? '',
    requiresPrescription: json['requiresPrescription'] ?? false,
    image: json['image'] ?? '',
    pharmacyId: json['pharmacyId'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'genericName': genericName,
    'description': description,
    'category': category,
    'price': price,
    'stock': stock,
    'unit': unit,
    'requiresPrescription': requiresPrescription,
    'image': image,
    'pharmacyId': pharmacyId,
  };
}

// ── CartItem ────────────────────────────────────────────────
class CartItem {
  final Medicine medicine;
  int quantity;

  CartItem({required this.medicine, this.quantity = 1});

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    medicine: Medicine.fromJson(json['medicine']),
    quantity: json['quantity'] ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'medicine': medicine.toJson(),
    'quantity': quantity,
  };
}

