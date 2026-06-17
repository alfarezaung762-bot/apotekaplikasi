class ApiConfig {
  // Production URL - terhubung langsung ke Vercel
  static const String baseUrl = 'https://layanankesehatan-project.vercel.app';
  
  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  
  // Appointments
  static const String appointments = '/api/appointments';
  static String appointmentById(String id) => '/api/appointments/$id';
  static const String bookedAppointments = '/api/appointments/booked';
  
  // Doctors
  static const String doctors = '/api/doctors';
  static String doctorById(String id) => '/api/doctors/$id';
  static String doctorTimeslotsById(String id) => '/api/doctors/$id/timeslots';
  static const String doctorProfile = '/api/doctor-profile';
  static const String doctorTimeslots = '/api/doctor/timeslots';
  
  // Messages
  static const String messages = '/api/messages';
  
  // Notifications
  static const String notifications = '/api/notifications';
  
  // Patient Profile
  static const String patientProfile = '/api/patient-profile';
  
  // Transactions
  static const String transactions = '/api/transactions';
  
  // Users
  static const String users = '/api/users';
  static String userById(String id) => '/api/users/$id';
  
  static String fullUrl(String endpoint) => '$baseUrl$endpoint';
}
