import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
// models imported via widgets

class PatientOrdersPage extends StatefulWidget {
  const PatientOrdersPage({super.key});
  @override
  State<PatientOrdersPage> createState() => _State();
}

class _State extends State<PatientOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) context.read<AppProvider>().fetchTransactions(auth.user!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Pesanan Obat')),
      body: Consumer<AppProvider>(builder: (ctx, app, _) {
        // Show ORDER type transactions as orders
        final orders = app.transactions.where((t) => t.type == 'ORDER').toList();
        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.local_pharmacy_outlined,
            title: 'Belum ada pesanan',
            subtitle: 'Anda belum memiliki riwayat pesanan obat.\nPesanan obat dapat dilakukan melalui website.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final o = orders[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_pharmacy, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('Pembelian Obat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    StatusBadge(label: o.statusLabel, color: o.status == 'PAID' ? AppTheme.success : Colors.orange),
                  ]),
                  const SizedBox(height: 4),
                  Text('#${o.id.length > 8 ? o.id.substring(0, 8) : o.id} • ${formatDate(o.createdAt)}', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Text(formatPrice(o.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ])),
              ]),
            );
          },
        );
      }),
    );
  }
}
