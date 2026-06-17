import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});
  @override
  State<DoctorDashboardPage> createState() => _State();
}

class _State extends State<DoctorDashboardPage> {
  Timer? _t;
  @override
  void initState() { super.initState(); _t = Timer.periodic(const Duration(seconds: 10), (_) { final a = context.read<AuthProvider>(); if (a.user != null) context.read<AppProvider>().refreshData(a.user!.id, 'doctor'); }); }
  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(automaticallyImplyLeading: false, title: Consumer<AuthProvider>(builder: (_, a, __) => Text('Dr. ${a.user?.name.split(' ').last ?? ''} 👨‍⚕️'))),
      body: Consumer2<AuthProvider, AppProvider>(builder: (ctx, auth, app, _) {
        if (auth.user == null) return const SizedBox();
        final uid = auth.user!.id;
        final doc = app.getDoctorByUserId(uid);
        final docApts = doc != null ? app.getAppointmentsByDoctor(doc.id) : <dynamic>[];
        final completed = docApts.where((a) => a.status == 'completed').length;
        final pending = docApts.where((a) => a.status == 'pending' || a.status == 'confirmed').toList();
        final unread = app.getUnreadMessageCount(uid);

        return RefreshIndicator(
          onRefresh: () => app.refreshData(uid, 'doctor'),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // Profile card
            if (doc != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
              child: Row(children: [
                AvatarInitials(name: doc.user.name, size: 56),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(doc.user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                    if (doc.isVerified) const Icon(Icons.verified, size: 18, color: AppTheme.primary),
                  ]),
                  Text(doc.specialization, style: TextStyle(fontSize: 13, color: AppTheme.primary)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    Text(' ${doc.rating}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(' (${doc.reviewCount})', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(width: 12),
                    Text(formatPrice(doc.price), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ]),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            // Stats
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0, children: [
              StatCard(label: 'Jadwal Hari Ini', value: '${pending.length}', icon: Icons.calendar_today, color: AppTheme.primary),
              StatCard(label: 'Konsultasi Selesai', value: '$completed', icon: Icons.check_circle_outline, color: AppTheme.success),
              StatCard(label: 'Pesan Baru', value: '$unread', icon: Icons.chat_bubble_outline, color: AppTheme.accent),
              StatCard(label: 'Pendapatan', value: formatPrice(completed * (doc?.price ?? 0)), icon: Icons.account_balance_wallet, color: const Color(0xFFF59E0B)),
            ]),
            const SizedBox(height: 20),
            // Today's schedule
            const Text('Jadwal Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (pending.isEmpty) Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
              child: Column(children: [
                Icon(Icons.calendar_today, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('Tidak ada jadwal hari ini', style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            )
            else ...pending.take(5).map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  AvatarInitials(name: a.patient?.user.name ?? 'P', size: 44, bgColor: AppTheme.accent.withOpacity(0.1), textColor: AppTheme.accent),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(a.patient?.user.name ?? 'Pasien', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))), StatusBadge(status: a.status)]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.access_time, size: 13, color: AppTheme.textMuted), const SizedBox(width: 4),
                      Text(a.time, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 10),
                      Icon(a.type == 'online' ? Icons.videocam : Icons.location_on, size: 13, color: AppTheme.textMuted), const SizedBox(width: 4),
                      Text(a.type == 'online' ? 'Online' : 'Offline', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (a.status == 'pending') ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => app.updateAppointmentStatus(a.id, 'cancelled'),
                      child: const Text('Tolak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                      ),
                      onPressed: () => app.updateAppointmentStatus(a.id, 'confirmed'),
                      child: const Text('Terima', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ] else if (a.status == 'confirmed') ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (a.patient?.userId != null) {
                          app.setActiveChatUserId(a.patient!.userId);
                          app.setDoctorTab(3); // Index 3 is the Chat tab in DoctorShell
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 14),
                      label: const Text('Mulai Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
              ]),
            )),
          ]),
        );
      }),
    );
  }
}
