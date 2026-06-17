import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../models/user.dart';

class DoctorSettingsPage extends StatelessWidget {
  const DoctorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Pengaturan')),
      body: Consumer2<AuthProvider, AppProvider>(builder: (ctx, auth, app, _) {
        if (auth.user == null) return const SizedBox();
        final user = auth.user!;
        final doc = app.getDoctorByUserId(user.id);
        return ListView(padding: const EdgeInsets.all(16), children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
            child: Column(children: [
              AvatarInitials(name: user.name, size: 72),
              const SizedBox(height: 12),
              Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(doc?.specialization ?? 'Dokter', style: TextStyle(fontSize: 14, color: AppTheme.primary)),
              const SizedBox(height: 4),
              Text(doc?.hospital ?? '', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              if (doc != null) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _MiniStat(label: 'Rating', value: '${doc.rating}', icon: Icons.star, color: Colors.amber),
                  const SizedBox(width: 20),
                  _MiniStat(label: 'Pengalaman', value: '${doc.experience} thn', icon: Icons.work, color: AppTheme.accent),
                  const SizedBox(width: 20),
                  _MiniStat(label: 'Review', value: '${doc.reviewCount}', icon: Icons.rate_review, color: AppTheme.primary),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          _Tile(icon: Icons.person_outline, title: 'Edit Profil', onTap: () => _editProfile(context, auth, app)),
          _Tile(icon: Icons.medical_services_outlined, title: 'Edit Profil Dokter', onTap: () => _editDoctorProfile(context, app)),
          _Tile(icon: Icons.people_outline, title: 'Daftar Pasien', onTap: () => Navigator.pushNamed(context, '/doctor/patients')),
          _Tile(icon: Icons.notifications_outlined, title: 'Notifikasi', onTap: () {}),
          _Tile(icon: Icons.help_outline, title: 'Bantuan', onTap: () {}),
          const SizedBox(height: 16),
          _Tile(icon: Icons.logout, title: 'Keluar', color: AppTheme.error, onTap: () {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              auth.logout();
            });
          }),
          const SizedBox(height: 24),
        ]);
      }),
    );
  }

  void _editProfile(BuildContext context, AuthProvider auth, AppProvider app) {
    final user = auth.user!;
    final nameCtrl = TextEditingController(text: user.name);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Edit Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              try {
                await app.updateUserProfile(user.id, {'name': nameCtrl.text.trim()});
                await auth.updateUser(User(id: user.id, name: nameCtrl.text.trim(), email: user.email, role: user.role));
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui!')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Simpan'),
          )),
        ]),
      ),
    );
  }

  void _editDoctorProfile(BuildContext context, AppProvider app) {
    final auth = context.read<AuthProvider>();
    final doc = app.getDoctorByUserId(auth.user!.id);
    if (doc == null) return;

    final specCtrl = TextEditingController(text: doc.specialization);
    final hospCtrl = TextEditingController(text: doc.hospital);
    final bioCtrl = TextEditingController(text: doc.bio ?? '');
    final expCtrl = TextEditingController(text: doc.experience.toString());
    final priceCtrl = TextEditingController(text: doc.price.toInt().toString());

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: ListView(shrinkWrap: true, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Edit Profil Dokter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Spesialisasi', prefixIcon: Icon(Icons.medical_services))),
          const SizedBox(height: 12),
          TextField(controller: hospCtrl, decoration: const InputDecoration(labelText: 'Rumah Sakit / Klinik', prefixIcon: Icon(Icons.local_hospital))),
          const SizedBox(height: 12),
          TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: 'Bio / Tentang', prefixIcon: Icon(Icons.info_outline)), maxLines: 3),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Pengalaman (tahun)'), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Tarif (Rp)'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final ok = await app.updateDoctorProfile(doc.id, {
                'specialization': specCtrl.text.trim(),
                'hospital': hospCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
                'experience': int.tryParse(expCtrl.text) ?? doc.experience,
                'price': int.tryParse(priceCtrl.text) ?? doc.price.toInt(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Profil dokter diperbarui!' : 'Gagal')));
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Simpan Perubahan'),
          )),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
    ]);
  }
}

class _Tile extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap; final Color? color;
  const _Tile({required this.icon, required this.title, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppTheme.primary),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
        onTap: onTap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
