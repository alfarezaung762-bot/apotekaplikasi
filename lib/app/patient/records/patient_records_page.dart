import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class PatientRecordsPage extends StatefulWidget {
  const PatientRecordsPage({super.key});
  @override
  State<PatientRecordsPage> createState() => _State();
}

class _State extends State<PatientRecordsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Rekam Medis')),
      body: Consumer2<AuthProvider, AppProvider>(builder: (ctx, auth, app, _) {
        if (auth.user == null) return const SizedBox();
        final records = app.appointments.where((a) =>
          a.isCompleted && a.diagnosis != null && a.diagnosis!.isNotEmpty &&
          (a.patient?.userId == auth.user!.id || a.patientId.contains(auth.user!.id))
        ).where((r) =>
          _search.isEmpty ||
          (r.doctor?.user.name.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          (r.diagnosis?.toLowerCase().contains(_search.toLowerCase()) ?? false)
        ).toList();

        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari dokter atau diagnosis...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceDim,
              ),
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const EmptyState(icon: Icons.description_outlined, title: 'Tidak ada rekam medis', subtitle: 'Belum ada riwayat konsultasi yang selesai')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    itemBuilder: (ctx, i) => _RecordCard(record: records[i]),
                  ),
          ),
        ]);
      }),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final Appointment record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDim,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.description, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Konsultasi dengan ${record.doctor?.user.name ?? 'Dokter'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.calendar_today, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(formatDate(record.date), style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ]),
            ])),
            const StatusBadge(label: 'Selesai', color: AppTheme.success),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Keluhan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Text(record.complaint ?? '-', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                Text('Diagnosis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Text(record.diagnosis ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Catatan Dokter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Text(record.notes ?? '-', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                Text('Dokter Pemeriksa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.medical_services, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(record.doctor?.specialization ?? '-', style: const TextStyle(fontSize: 13)),
                ]),
              ])),
            ]),
          ]),
        ),
      ]),
    );
  }
}
