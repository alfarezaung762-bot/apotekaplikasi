import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluter_apotek/app/providers/providers.dart';
import 'package:fluter_apotek/app/config/theme.dart';

// Patient pages
import 'package:fluter_apotek/app/patient/dashboard/patient_dashboard_page.dart';
import 'package:fluter_apotek/app/patient/appointments/patient_appointments_page.dart';
import 'package:fluter_apotek/app/patient/chat/patient_chat_page.dart';
import 'package:fluter_apotek/app/patient/records/patient_records_page.dart';
import 'package:fluter_apotek/app/patient/settings/patient_settings_page.dart';

// Doctor pages
import 'package:fluter_apotek/app/doctor/dashboard/doctor_dashboard_page.dart';
import 'package:fluter_apotek/app/doctor/schedule/doctor_schedule_page.dart';
import 'package:fluter_apotek/app/doctor/appointments/doctor_appointments_page.dart';
import 'package:fluter_apotek/app/doctor/chat/doctor_chat_page.dart';
import 'package:fluter_apotek/app/doctor/settings/doctor_settings_page.dart';

// ═══════════════════════════════════════════════════════════════
// PATIENT SHELL — 5 tabs: Dashboard, Konsultasi, Chat, Rekam Medis, Pengaturan
// ═══════════════════════════════════════════════════════════════
class PatientShell extends StatefulWidget {
  const PatientShell({super.key});
  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  final _pages = const [
    PatientDashboardPage(),
    PatientAppointmentsPage(),
    PatientChatPage(),
    PatientRecordsPage(),
    PatientSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<AppProvider>().refreshData(auth.user!.id, 'patient');
        context.read<AppProvider>().fetchDoctors();
        context.read<AppProvider>().fetchPatientProfile(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      body: IndexedStack(index: app.selectedPatientTab, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: NavigationBar(
          selectedIndex: app.selectedPatientTab,
          onDestinationSelected: (i) => app.setPatientTab(i),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Konsultasi'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Rekam Medis'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Pengaturan'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DOCTOR SHELL — 5 tabs: Dashboard, Jadwal, Konsultasi, Chat, Pengaturan
// ═══════════════════════════════════════════════════════════════
class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});
  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  final _pages = const [
    DoctorDashboardPage(),
    DoctorSchedulePage(),
    DoctorAppointmentsPage(),
    DoctorChatPage(),
    DoctorSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<AppProvider>().refreshData(auth.user!.id, 'doctor');
        context.read<AppProvider>().fetchDoctors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      body: IndexedStack(index: app.selectedDoctorTab, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: NavigationBar(
          selectedIndex: app.selectedDoctorTab,
          onDestinationSelected: (i) => app.setDoctorTab(i),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Jadwal'),
            NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Konsultasi'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Pengaturan'),
          ],
        ),
      ),
    );
  }
}
