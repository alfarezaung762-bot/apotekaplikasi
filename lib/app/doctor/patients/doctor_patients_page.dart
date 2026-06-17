import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
// models imported via widgets

class DoctorPatientsPage extends StatelessWidget {
  const DoctorPatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Daftar Pasien')),
      body: Consumer2<AuthProvider, AppProvider>(builder: (ctx, auth, app, _) {
        if (auth.user == null) return const SizedBox();
        final apts = app.getAppointmentsByDoctor(auth.user!.id);
        // Group unique patients
        final patientMap = <String, _PatientInfo>{};
        for (final a in apts) {
          final pid = a.patient?.userId ?? a.patientId;
          final name = a.patient?.user.name ?? 'Pasien';
          if (!patientMap.containsKey(pid)) {
            patientMap[pid] = _PatientInfo(id: pid, name: name, visits: 0, lastDate: a.date);
          }
          patientMap[pid]!.visits++;
          if (a.date.compareTo(patientMap[pid]!.lastDate) > 0) {
            patientMap[pid]!.lastDate = a.date;
          }
        }
        final patients = patientMap.values.toList()..sort((a, b) => b.lastDate.compareTo(a.lastDate));

        if (patients.isEmpty) {
          return const EmptyState(icon: Icons.people_outline, title: 'Belum ada pasien', subtitle: 'Pasien akan muncul setelah ada konsultasi');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          itemBuilder: (ctx, i) {
            final p = patients[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
              child: Row(children: [
                AvatarInitials(name: p.name, size: 48),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.event, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${p.visits} kunjungan', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('Terakhir: ${formatDate(p.lastDate)}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                ])),
              ]),
            );
          },
        );
      }),
    );
  }
}

class _PatientInfo {
  final String id, name;
  int visits;
  String lastDate;
  _PatientInfo({required this.id, required this.name, required this.visits, required this.lastDate});
}
