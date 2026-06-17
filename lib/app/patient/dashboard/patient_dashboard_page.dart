import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});
  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<AppProvider>().refreshData(auth.user!.id, 'patient');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Consumer<AuthProvider>(
          builder: (_, auth, __) => Text('Halo, ${auth.user?.name.split(' ')[0] ?? ''} 👋'),
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (_, app, __) {
              final auth = context.read<AuthProvider>();
              final count = auth.user != null ? app.getUnreadMessageCount(auth.user!.id) : 0;
              return Stack(
                children: [
                  IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                  if (count > 0) Positioned(right: 8, top: 8, child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text('$count', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                  )),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, AppProvider>(
        builder: (context, auth, app, _) {
          if (auth.user == null) return const SizedBox();
          final user = auth.user!;
          final patientId = 'pat-${user.id}';
          final appointments = app.getAppointmentsByPatient(patientId);
          final unreadMessages = app.getUnreadMessageCount(user.id);

          final upcomingAppointments = appointments
              .where((a) => a.status == 'confirmed' || a.status == 'pending')
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          return RefreshIndicator(
            onRefresh: () => app.refreshData(user.id, 'patient'),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.0,
                  children: [
                    StatCard(label: 'Total Konsultasi', value: '${appointments.length}', icon: Icons.calendar_today, color: AppTheme.primary),
                    StatCard(label: 'Pesan Baru', value: '$unreadMessages', icon: Icons.chat_bubble_outline, color: AppTheme.accent),
                  ],
                ),
                const SizedBox(height: 20),
                // Upcoming appointments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Konsultasi Mendatang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
                  ],
                ),
                const SizedBox(height: 8),
                if (upcomingAppointments.isEmpty)
                  _EmptyCard(icon: Icons.calendar_today, text: 'Tidak ada konsultasi mendatang')
                else
                  ...upcomingAppointments.take(3).map((apt) => _AppointmentTile(appointment: apt)),
                const SizedBox(height: 20),
                // Quick actions
                const Text('Menu Cepat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _QuickAction(icon: Icons.search, label: 'Cari Dokter', color: AppTheme.primary, onTap: () => Navigator.pushNamed(context, '/doctors'))),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickAction(icon: Icons.chat, label: 'Chat Dokter', color: AppTheme.accent, onTap: () => app.setPatientTab(2))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _QuickAction(icon: Icons.local_pharmacy, label: 'Apotek Online', color: AppTheme.primaryLight, onTap: () => Navigator.pushNamed(context, '/patient/pharmacy'))),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickAction(icon: Icons.receipt_long, label: 'Pesanan Obat', color: Colors.orange, onTap: () => Navigator.pushNamed(context, '/patient/orders'))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final dynamic appointment;
  const _AppointmentTile({required this.appointment});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          AvatarInitials(name: appointment.doctor?.user.name ?? 'Dokter', size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(appointment.doctor?.user.name ?? 'Dokter', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                    StatusBadge(status: appointment.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(appointment.doctor?.specialization ?? '', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${appointment.date} - ${appointment.time}', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(width: 10),
                    Icon(appointment.type == 'online' ? Icons.videocam : Icons.location_on, size: 13, color: appointment.type == 'online' ? AppTheme.primary : AppTheme.accent),
                    const SizedBox(width: 3),
                    Text(appointment.type == 'online' ? 'Online' : 'Offline', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
