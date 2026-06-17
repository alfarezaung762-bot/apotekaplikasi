import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/models.dart';
import '../models/doctor_profile.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPatient => _user?.role == 'patient';
  bool get isDoctor => _user?.role == 'doctor';

  final ApiService _api = ApiService();

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        _user = User.fromJson(jsonDecode(userData));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.post(ApiConfig.login, {
        'email': email,
        'password': password,
      });

      if (result['success'] == true && result['user'] != null) {
        _user = User.fromJson(result['user']);
        await _saveUserToStorage(_user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Koneksi gagal. Periksa internet Anda.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.post(ApiConfig.register, {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      if (result['success'] == true && result['user'] != null) {
        _user = User.fromJson(result['user']);
        await _saveUserToStorage(_user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'Registrasi gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Koneksi gagal. Periksa internet Anda.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUser(User updatedUser) async {
    _user = updatedUser;
    await _saveUserToStorage(updatedUser);
    notifyListeners();
  }

  void logout() {
    _user = null;
    _clearStorage();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ════════════════════════════════════════════════════════════
// App Provider — All data management
// ════════════════════════════════════════════════════════════
class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<DoctorProfile> _doctors = [];
  List<Appointment> _appointments = [];
  List<ChatMessage> _messages = [];
  List<AppNotification> _notifications = [];
  List<PaymentTransaction> _transactions = [];
  List<TimeSlot> _timeSlots = [];
  List<SimpleUser> _users = [];
  PatientProfile? _patientProfile;
  bool _isLoading = false;

  int _selectedPatientTab = 0;
  int _selectedDoctorTab = 0;
  String? _activeChatUserId;

  int get selectedPatientTab => _selectedPatientTab;
  int get selectedDoctorTab => _selectedDoctorTab;
  String? get activeChatUserId => _activeChatUserId;

  void setPatientTab(int index) {
    _selectedPatientTab = index;
    notifyListeners();
  }

  void setDoctorTab(int index) {
    _selectedDoctorTab = index;
    notifyListeners();
  }

  void setActiveChatUserId(String? userId) {
    _activeChatUserId = userId;
    notifyListeners();
  }

  AppProvider() {
    loadCart();
  }

  List<DoctorProfile> get doctors => _doctors;
  List<Appointment> get appointments => _appointments;
  List<ChatMessage> get messages => _messages;
  List<AppNotification> get notifications => _notifications;
  List<PaymentTransaction> get transactions => _transactions;
  List<TimeSlot> get timeSlots => _timeSlots;
  List<SimpleUser> get users => _users;
  PatientProfile? get patientProfile => _patientProfile;
  bool get isLoading => _isLoading;

  // ── Getters ────────────────────────────────────────────────
  int getUnreadCount(String userId) {
    return _notifications.where((n) => n.userId == userId && !n.isRead).length;
  }

  int getUnreadMessageCount(String userId) {
    return _messages.where((m) => m.receiverId == userId && !m.isRead).length;
  }

  List<Appointment> getAppointmentsByPatient(String patientId) {
    return _appointments.where((a) =>
      a.patientId == patientId || a.patient?.userId == patientId
    ).toList();
  }

  List<Appointment> getAppointmentsByDoctor(String doctorId) {
    return _appointments.where((a) =>
      a.doctorId == doctorId || a.doctor?.userId == doctorId
    ).toList();
  }

  List<ChatMessage> getMessagesBetweenUsers(String userId1, String userId2) {
    return _messages.where((m) =>
      (m.senderId == userId1 && m.receiverId == userId2) ||
      (m.senderId == userId2 && m.receiverId == userId1)
    ).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  DoctorProfile? getDoctorByUserId(String userId) {
    try {
      return _doctors.firstWhere((d) => d.userId == userId);
    } catch (_) {
      return null;
    }
  }

  DoctorProfile? getDoctorById(String doctorId) {
    try {
      return _doctors.firstWhere((d) => d.id == doctorId);
    } catch (_) {
      return null;
    }
  }

  String getUserName(String userId) {
    // First check doctors
    final doc = getDoctorByUserId(userId);
    if (doc != null) return doc.user.name;
    // Then check users list
    try {
      return _users.firstWhere((u) => u.id == userId).name;
    } catch (_) {
      return 'User';
    }
  }

  // ── Fetch Doctors ─────────────────────────────────────────
  Future<void> fetchDoctors() async {
    final result = await _api.get(ApiConfig.doctors, queryParams: {'t': DateTime.now().millisecondsSinceEpoch.toString()});
    if (result['success'] == true && result['doctors'] != null) {
      _doctors = (result['doctors'] as List).map((d) => DoctorProfile.fromJson(d)).toList();
      notifyListeners();
    }
  }

  // ── Fetch Patient Profile ────────────────────────────────
  Future<PatientProfile?> fetchPatientProfile(String userId) async {
    final result = await _api.get(ApiConfig.patientProfile, queryParams: {'userId': userId});
    if (result['success'] == true && result['patientProfile'] != null) {
      _patientProfile = PatientProfile.fromJson(result['patientProfile']);
      notifyListeners();
      return _patientProfile;
    }
    return null;
  }

  // ── Fetch Users (for chat contacts) ──────────────────────
  Future<void> fetchUsers(List<String> ids) async {
    if (ids.isEmpty) return;
    final result = await _api.get(ApiConfig.users, queryParams: {'ids': ids.join(',')});
    if (result['success'] == true && result['users'] != null) {
      final newUsers = (result['users'] as List).map((u) => SimpleUser.fromJson(u)).toList();
      for (final u in newUsers) {
        _users.removeWhere((existing) => existing.id == u.id);
        _users.add(u);
      }
      notifyListeners();
    }
  }

  // ── Refresh All Data ──────────────────────────────────────
  Future<void> refreshData(String userId, String role) async {
    try {
      final futures = await Future.wait([
        _api.get(ApiConfig.appointments, queryParams: {'userId': userId, 'role': role}),
        _api.get(ApiConfig.notifications, queryParams: {'userId': userId}),
      ]);

      final aptResult = futures[0];
      final notifResult = futures[1];

      if (aptResult['success'] == true && aptResult['appointments'] != null) {
        _appointments = (aptResult['appointments'] as List).map((a) => Appointment.fromJson(a)).toList();
      }
      if (notifResult['success'] == true && notifResult['notifications'] != null) {
        _notifications = (notifResult['notifications'] as List).map((n) => AppNotification.fromJson(n)).toList();
      }
      notifyListeners();
    } catch (e) {
      // Silent fail
    }
  }

  // ── Fetch Transactions ────────────────────────────────────
  Future<void> fetchTransactions(String userId) async {
    final result = await _api.get(ApiConfig.transactions, queryParams: {'userId': userId});
    if (result['success'] == true && result['transactions'] != null) {
      _transactions = (result['transactions'] as List).map((t) => PaymentTransaction.fromJson(t)).toList();
      notifyListeners();
    }
  }

  // ── Create Appointment ────────────────────────────────────
  Future<Appointment?> createAppointment(Map<String, dynamic> data) async {
    final result = await _api.post(ApiConfig.appointments, data);
    if (result['success'] == true && result['appointment'] != null) {
      final apt = Appointment.fromJson(result['appointment']);
      _appointments.insert(0, apt);
      notifyListeners();
      return apt;
    }
    throw Exception(result['error'] ?? 'Gagal membuat janji temu');
  }

  // ── Update Appointment Status ─────────────────────────────
  Future<bool> updateAppointmentStatus(String id, String status, {String? diagnosis, String? notes}) async {
    try {
      final result = await _api.patch(ApiConfig.appointmentById(id), body: {
        'status': status,
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (notes != null) 'notes': notes,
      });
      if (result['success'] == true && result['appointment'] != null) {
        final updated = Appointment.fromJson(result['appointment']);
        final idx = _appointments.indexWhere((a) => a.id == id);
        if (idx >= 0) _appointments[idx] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── Cancel Appointment ────────────────────────────────────
  Future<bool> cancelAppointment(String id) async {
    return updateAppointmentStatus(id, 'cancelled');
  }

  // ── Send Message ──────────────────────────────────────────
  Future<ChatMessage?> sendMessage(String senderId, String receiverId, String content) async {
    final result = await _api.post(ApiConfig.messages, {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': 'TEXT',
    });
    if (result['success'] == true && result['message'] != null) {
      final msg = ChatMessage.fromJson(result['message']);
      _messages.add(msg);
      notifyListeners();
      return msg;
    }
    // Fallback local message
    final localMsg = ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      createdAt: DateTime.now().toIso8601String(),
    );
    _messages.add(localMsg);
    notifyListeners();
    return localMsg;
  }

  // ── Fetch Messages ────────────────────────────────────────
  Future<void> fetchMessages(String userId1, String userId2) async {
    final result = await _api.get(ApiConfig.messages, queryParams: {'userId1': userId1, 'userId2': userId2});
    if (result['success'] == true && result['messages'] != null) {
      final newMessages = (result['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList();
      for (final nm in newMessages) {
        if (!_messages.any((m) => m.id == nm.id)) {
          _messages.add(nm);
        }
      }
      notifyListeners();
    }
  }

  // ── Mark Notification Read ────────────────────────────────
  Future<void> markNotificationRead(String id) async {
    _api.patch(ApiConfig.notifications, queryParams: {'id': id});
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = AppNotification(
        id: _notifications[idx].id, userId: _notifications[idx].userId,
        title: _notifications[idx].title, message: _notifications[idx].message,
        type: _notifications[idx].type, isRead: true, createdAt: _notifications[idx].createdAt,
      );
      notifyListeners();
    }
  }

  // ── Update User Profile ───────────────────────────────────
  Future<Map<String, dynamic>?> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final result = await _api.put(ApiConfig.userById(userId), body: data);
    if (result['success'] == true) {
      return result;
    }
    throw Exception(result['error'] ?? 'Gagal memperbarui profil');
  }

  // ── Update Doctor Profile ─────────────────────────────────
  Future<bool> updateDoctorProfile(String doctorId, Map<String, dynamic> data) async {
    final result = await _api.patch(ApiConfig.doctorProfile, body: {'doctorId': doctorId, ...data});
    if (result['success'] == true) {
      await fetchDoctors();
      return true;
    }
    return false;
  }

  // ── Submit Doctor Review ──────────────────────────────────
  Future<void> submitDoctorReview(String doctorId, double rating) async {
    await _api.patch(ApiConfig.doctorProfile, body: {'doctorId': doctorId, 'rating': rating});
    await fetchDoctors();
  }

  // ── Fetch Doctor Profile ──────────────────────────────────
  Future<DoctorProfile?> fetchDoctorProfile(String userId) async {
    final result = await _api.get(ApiConfig.doctorProfile, queryParams: {'userId': userId});
    if (result['success'] == true && result['doctorProfile'] != null) {
      return DoctorProfile.fromJson(result['doctorProfile']);
    }
    return null;
  }

  // ── TimeSlots ─────────────────────────────────────────────
  Future<void> fetchDoctorTimeSlots(String doctorId) async {
    final result = await _api.get(ApiConfig.doctorTimeslots, queryParams: {'doctorId': doctorId});
    if (result['success'] == true && result['timeslots'] != null) {
      _timeSlots = (result['timeslots'] as List).map((t) => TimeSlot.fromJson(t)).toList();
      notifyListeners();
    }
  }

  Future<void> addTimeSlot(Map<String, dynamic> data) async {
    final result = await _api.post(ApiConfig.doctorTimeslots, data);
    if (result['success'] == true && result['timeslot'] != null) {
      _timeSlots.add(TimeSlot.fromJson(result['timeslot']));
      notifyListeners();
    }
  }

  Future<void> updateTimeSlotStatus(String id, bool isActive) async {
    final result = await _api.put(ApiConfig.doctorTimeslots, body: {'id': id, 'isActive': isActive});
    if (result['success'] == true && result['timeslot'] != null) {
      final idx = _timeSlots.indexWhere((t) => t.id == id);
      if (idx >= 0) {
        _timeSlots[idx] = TimeSlot.fromJson(result['timeslot']);
        notifyListeners();
      }
    }
  }

  Future<void> deleteTimeSlot(String id) async {
    await _api.delete(ApiConfig.doctorTimeslots, queryParams: {'id': id});
    _timeSlots.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ── Cart & Checkout Methods ──────────────────────────────
  List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;
  double get cartTotal => _cartItems.fold(0.0, (sum, item) => sum + (item.medicine.price * item.quantity));
  int get cartCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items');
      if (cartData != null) {
        final List decoded = jsonDecode(cartData);
        _cartItems = decoded.map((item) => CartItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
      await prefs.setString('cart_items', cartData);
    } catch (_) {}
  }

  void addToCart(Medicine medicine) {
    final idx = _cartItems.indexWhere((item) => item.medicine.id == medicine.id);
    if (idx >= 0) {
      _cartItems[idx].quantity += 1;
    } else {
      _cartItems.add(CartItem(medicine: medicine, quantity: 1));
    }
    notifyListeners();
    _saveCart();
  }

  void updateCartQuantity(String medicineId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(medicineId);
      return;
    }
    final idx = _cartItems.indexWhere((item) => item.medicine.id == medicineId);
    if (idx >= 0) {
      _cartItems[idx].quantity = quantity;
      notifyListeners();
      _saveCart();
    }
  }

  void removeFromCart(String medicineId) {
    _cartItems.removeWhere((item) => item.medicine.id == medicineId);
    notifyListeners();
    _saveCart();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
    _saveCart();
  }

  Future<String?> createCheckoutSession(String userId, double amount) async {
    try {
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Buat Transaksi di DB
      final checkoutResult = await _api.post('/api/checkout', {
        'userId': userId,
        'amount': amount,
        'orderId': orderId,
        'type': 'ORDER',
      });
      
      if (checkoutResult['success'] == true && checkoutResult['transactionId'] != null) {
        final transactionId = checkoutResult['transactionId'];
        
        // 2. Buat Token & URL Pembayaran Midtrans
        final paymentResult = await _api.post('/api/payments/create-token', {
          'transactionId': transactionId,
        });
        
        if (paymentResult['success'] == true && paymentResult['redirect_url'] != null) {
          clearCart();
          fetchTransactions(userId);
          return paymentResult['redirect_url'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
