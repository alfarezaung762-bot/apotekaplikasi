import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class PatientAppointmentsPage extends StatefulWidget {
  const PatientAppointmentsPage({super.key});
  @override
  State<PatientAppointmentsPage> createState() => _State();
}

class _State extends State<PatientAppointmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Konsultasi'),
        bottom: TabBar(controller: _tab, isScrollable: true, tabAlignment: TabAlignment.start, tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Mendatang'),
          Tab(text: 'Selesai'),
          Tab(text: 'Dibatalkan'),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/doctors'),
        icon: const Icon(Icons.add),
        label: const Text('Buat Janji'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<AuthProvider, AppProvider>(builder: (ctx, auth, app, _) {
        if (auth.user == null) return const SizedBox();
        final all = app.getAppointmentsByPatient(auth.user!.id);
        final upcoming = all.where((a) => a.isUpcoming).toList();
        final completed = all.where((a) => a.isCompleted).toList();
        final cancelled = all.where((a) => a.isCancelled).toList();

        return TabBarView(controller: _tab, children: [
          _AptList(appointments: all, userId: auth.user!.id),
          _AptList(appointments: upcoming, userId: auth.user!.id),
          _AptList(appointments: completed, userId: auth.user!.id),
          _AptList(appointments: cancelled, userId: auth.user!.id),
        ]);
      }),
    );
  }
}

class _AptList extends StatelessWidget {
  final List<Appointment> appointments;
  final String userId;
  const _AptList({required this.appointments, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const EmptyState(icon: Icons.calendar_today_outlined, title: 'Tidak ada konsultasi', subtitle: 'Belum ada janji temu');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (ctx, i) => _AptCard(apt: appointments[i], userId: userId),
    );
  }
}

class _AptCard extends StatelessWidget {
  final Appointment apt;
  final String userId;
  const _AptCard({required this.apt, required this.userId});

  Color get _statusColor {
    switch (apt.status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'completed': return AppTheme.success;
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.textMuted;
    }
  }

  String get _statusLabel {
    switch (apt.status) {
      case 'pending': return 'Menunggu';
      case 'confirmed': return 'Dikonfirmasi';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default: return apt.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          AvatarInitials(name: apt.doctor?.user.name ?? 'Dokter', size: 44),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(apt.doctor?.user.name ?? 'Dokter', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(apt.doctor?.specialization ?? '', style: TextStyle(fontSize: 12, color: AppTheme.primary)),
          ])),
          StatusBadge(label: _statusLabel, color: _statusColor),
        ]),
        const SizedBox(height: 12),
        // Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.surfaceDim, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            _InfoItem(icon: Icons.calendar_today, label: formatDate(apt.date)),
            const SizedBox(width: 16),
            _InfoItem(icon: Icons.access_time, label: apt.time),
            const SizedBox(width: 16),
            _InfoItem(icon: Icons.videocam, label: apt.type == 'online' ? 'Online' : 'Offline'),
          ]),
        ),
        if (apt.complaint != null && apt.complaint!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Keluhan: ${apt.complaint}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
        // Actions
        const SizedBox(height: 12),
        Row(children: [
          if (apt.status == 'confirmed') ...[
            Expanded(child: ElevatedButton.icon(
              onPressed: () {
                if (apt.doctor?.userId != null) {
                  final app = context.read<AppProvider>();
                  app.setActiveChatUserId(apt.doctor!.userId);
                  app.setPatientTab(2); // Index 2 is the Chat tab in PatientShell
                }
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Mulai Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            )),
            const SizedBox(width: 8),
          ],
          if (apt.isUpcoming) ...[
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _cancelDialog(context),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Batalkan'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
            )),
          ],
          if (apt.isCompleted) ...[
            if (apt.diagnosis != null)
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _viewResep(context),
                icon: const Icon(Icons.description, size: 16),
                label: const Text('Lihat Resep'),
              )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _rateDialog(context),
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Beri Ulasan'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
            )),
          ],
        ]),
      ]),
    );
  }

  void _cancelDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Batalkan Konsultasi?'),
      content: const Text('Apakah Anda yakin ingin membatalkan janji temu ini?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tidak')),
        ElevatedButton(
          onPressed: () {
            context.read<AppProvider>().cancelAppointment(apt.id);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konsultasi dibatalkan')));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
          child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _viewResep(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Row(children: [
        Icon(Icons.description, color: AppTheme.primary),
        const SizedBox(width: 8),
        const Text('Hasil Konsultasi'),
      ]),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _ResepField(label: 'Dokter', value: apt.doctor?.user.name ?? '-'),
        _ResepField(label: 'Tanggal', value: formatDate(apt.date)),
        _ResepField(label: 'Keluhan', value: apt.complaint ?? '-'),
        _ResepField(label: 'Diagnosis', value: apt.diagnosis ?? '-'),
        _ResepField(label: 'Catatan', value: apt.notes ?? '-'),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
    ));
  }

  void _rateDialog(BuildContext context) {
    double rating = 5;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      title: const Text('Beri Ulasan'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Bagaimana pengalaman Anda dengan ${apt.doctor?.user.name}?'),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
          GestureDetector(
            onTap: () => setState(() => rating = (i + 1).toDouble()),
            child: Icon(Icons.star, size: 36, color: i < rating ? Colors.amber : Colors.grey.shade300),
          ),
        )),
        const SizedBox(height: 8),
        Text('${rating.toInt()}/5', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            context.read<AppProvider>().submitDoctorReview(apt.doctorId, rating);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan berhasil dikirim!')));
          },
          child: const Text('Kirim'),
        ),
      ],
    )));
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoItem({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: AppTheme.textMuted),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ]);
  }
}

class _ResepField extends StatelessWidget {
  final String label, value;
  const _ResepField({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 14)),
    ]));
  }
}
