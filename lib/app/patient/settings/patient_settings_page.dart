import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../models/user.dart';

class PatientSettingsPage extends StatelessWidget {
  const PatientSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Pengaturan')),
      body: Consumer<AuthProvider>(builder: (ctx, auth, _) {
        if (auth.user == null) return const SizedBox();
        final user = auth.user!;
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
              Text(user.email, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('Pasien', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          // Menu items
          _SettingsTile(icon: Icons.person_outline, title: 'Edit Profil', onTap: () => _editProfile(context, auth)),
          _SettingsTile(icon: Icons.receipt_long, title: 'Riwayat Transaksi', onTap: () => Navigator.pushNamed(context, '/patient/transactions')),
          _SettingsTile(icon: Icons.local_pharmacy_outlined, title: 'Pesanan Obat', onTap: () => Navigator.pushNamed(context, '/patient/orders')),
          _SettingsTile(icon: Icons.notifications_outlined, title: 'Notifikasi', onTap: () {}),
          _SettingsTile(icon: Icons.help_outline, title: 'Bantuan', onTap: () {}),
          const SizedBox(height: 16),
          _SettingsTile(icon: Icons.logout, title: 'Keluar', color: AppTheme.error, onTap: () {
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

  void _editProfile(BuildContext context, AuthProvider auth) {
    final user = auth.user!;
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Edit Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              try {
                final app = context.read<AppProvider>();
                await app.updateUserProfile(user.id, {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                });
                final updatedUser = User(id: user.id, name: nameCtrl.text.trim(), email: emailCtrl.text.trim(), role: user.role);
                await auth.updateUser(updatedUser);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Simpan Perubahan'),
          )),
        ]),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsTile({required this.icon, required this.title, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppTheme.primary),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
