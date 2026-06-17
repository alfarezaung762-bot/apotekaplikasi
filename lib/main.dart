import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/config/theme.dart';
import 'app/providers/providers.dart';
import 'app/auth/login/login_page.dart';
import 'app/auth/register/register_page.dart';
import 'app/widgets/shell.dart';
import 'app/doctors/doctors_page.dart';
import 'app/patient/transactions/patient_transactions_page.dart';
import 'app/patient/orders/patient_orders_page.dart';
import 'app/patient/pharmacy/pharmacy_page.dart';
import 'app/patient/pharmacy/cart_page.dart';
import 'app/doctor/patients/doctor_patients_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MedConnectApp());
}

class MedConnectApp extends StatelessWidget {
  const MedConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'MedConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return _fade(const LoginPage());
            case '/register':
              return _fade(const RegisterPage());
            case '/patient/dashboard':
              return _fade(const PatientShell());
            case '/patient/appointments':
              return _fade(const PatientShell());
            case '/patient/chat':
              return _fade(const PatientShell());
            case '/patient/orders':
              return _slide(const PatientOrdersPage());
            case '/patient/pharmacy':
              return _slide(const PharmacyPage());
            case '/patient/cart':
              return _slide(const CartPage());
            case '/patient/transactions':
              return _slide(const PatientTransactionsPage());
            case '/patient/settings':
              return _fade(const PatientShell());
            case '/doctor/dashboard':
              return _fade(const DoctorShell());
            case '/doctor/appointments':
              return _fade(const DoctorShell());
            case '/doctor/chat':
              return _fade(const DoctorShell());
            case '/doctor/patients':
              return _slide(const DoctorPatientsPage());
            case '/doctor/settings':
              return _fade(const DoctorShell());
            case '/doctors':
              return _slide(const DoctorsPage());
            default:
              return _fade(const LoginPage());
          }
        },
      ),
    );
  }

  static Route _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  static Route _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

/// Gate widget that checks auth state and shows the right screen
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const LoginPage();
        }
        if (auth.isPatient) {
          return const PatientShell();
        }
        return const DoctorShell();
      },
    );
  }
}
