import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});
  @override
  State<DoctorAppointmentsPage> createState() => _State();
}

class _State extends State<DoctorAppointmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Jadwal Konsultasi'),
        bottom: TabBar(controller: _tab, isScrollable: true, tabAlignment: TabAlignment.start, tabs: const [
          Tab(text: 'Menunggu'),
          Tab(text: 'Dikonfirmasi'),
          Tab(text: 'Selesai'),
          Tab(text: 'Dibatalkan'),
        ]),
      ),
      body: Consumer2<AuthProvider, AppProvider>(builder: (ctx, auth, app, _) {
        if (auth.user == null) return const SizedBox();
        final all = app.getAppointmentsByDoctor(auth.user!.id);
        return TabBarView(controller: _tab, children: [
          _AptList(apts: all.where((a) => a.isPending).toList()),
          _AptList(apts: all.where((a) => a.isConfirmed).toList()),
          _AptList(apts: all.where((a) => a.isCompleted).toList()),
          _AptList(apts: all.where((a) => a.isCancelled).toList()),
        ]);
      }),
    );
  }
}

class _AptList extends StatelessWidget {
  final List<Appointment> apts;
  const _AptList({required this.apts});

  @override
  Widget build(BuildContext context) {
    if (apts.isEmpty) return const EmptyState(icon: Icons.event_note, title: 'Tidak ada konsultasi', subtitle: '');
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: apts.length, itemBuilder: (ctx, i) => _DoctorAptCard(apt: apts[i]));
  }
}

class _DoctorAptCard extends StatelessWidget {
  final Appointment apt;
  const _DoctorAptCard({required this.apt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AvatarInitials(name: apt.patient?.user.name ?? 'Pasien', size: 44),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(apt.patient?.user.name ?? 'Pasien', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('${formatDate(apt.date)} • ${apt.time}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          _statusBadge(),
        ]),
        if (apt.complaint != null && apt.complaint!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.surfaceDim, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Keluhan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              Text(apt.complaint!, style: const TextStyle(fontSize: 13)),
            ]),
          ),
        ],
        if (apt.diagnosis != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.medical_services, size: 14, color: AppTheme.success),
            const SizedBox(width: 4),
            Expanded(child: Text('Diagnosis: ${apt.diagnosis}', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w500))),
          ]),
        ],
        const SizedBox(height: 12),
        _buildActions(context),
      ]),
    );
  }

  Widget _statusBadge() {
    Color c; String l;
    switch (apt.status) {
      case 'pending': c = Colors.orange; l = 'Menunggu'; break;
      case 'confirmed': c = Colors.blue; l = 'Dikonfirmasi'; break;
      case 'completed': c = AppTheme.success; l = 'Selesai'; break;
      case 'cancelled': c = AppTheme.error; l = 'Dibatalkan'; break;
      default: c = AppTheme.textMuted; l = apt.status;
    }
    return StatusBadge(label: l, color: c);
  }

  Widget _buildActions(BuildContext context) {
    if (apt.isPending) {
      return Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _updateStatus(context, 'cancelled'),
          icon: const Icon(Icons.close, size: 16), label: const Text('Tolak'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
        )),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _updateStatus(context, 'confirmed'),
          icon: const Icon(Icons.check, size: 16), label: const Text('Terima'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
        )),
      ]);
    }
    if (apt.isConfirmed) {
      return Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: () {
            if (apt.patient?.userId != null) {
              final app = context.read<AppProvider>();
              app.setActiveChatUserId(apt.patient!.userId);
              app.setDoctorTab(3); // Index 3 is the Chat tab in DoctorShell
            }
          },
          icon: const Icon(Icons.chat_bubble_outline, size: 16),
          label: const Text('Mulai Chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        )),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _completeDialog(context),
          icon: const Icon(Icons.done_all, size: 16),
          label: const Text('Selesai'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        )),
      ]);
    }
    return const SizedBox();
  }

  void _updateStatus(BuildContext context, String status) async {
    final ok = await context.read<AppProvider>().updateAppointmentStatus(apt.id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Status diperbarui!' : 'Gagal memperbarui status')));
    }
  }

  void _completeDialog(BuildContext context) {
    final diagCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Selesaikan Konsultasi'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: diagCtrl, decoration: const InputDecoration(labelText: 'Diagnosis', hintText: 'Masukkan diagnosis...'), maxLines: 2),
        const SizedBox(height: 12),
        TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan / Resep', hintText: 'Masukkan catatan...'), maxLines: 3),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(onPressed: () async {
          final ok = await context.read<AppProvider>().updateAppointmentStatus(
            apt.id, 'completed',
            diagnosis: diagCtrl.text.trim().isNotEmpty ? diagCtrl.text.trim() : null,
            notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
          );
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Konsultasi diselesaikan!' : 'Gagal')));
        }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white), child: const Text('Selesaikan')),
      ],
    ));
  }
}
