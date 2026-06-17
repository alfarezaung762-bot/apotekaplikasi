import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class PatientTransactionsPage extends StatefulWidget {
  const PatientTransactionsPage({super.key});
  @override
  State<PatientTransactionsPage> createState() => _State();
}

class _State extends State<PatientTransactionsPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) context.read<AppProvider>().fetchTransactions(auth.user!.id);
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Konsultasi'),
          Tab(text: 'Pesanan'),
        ]),
      ),
      body: Consumer<AppProvider>(builder: (ctx, app, _) {
        return TabBarView(controller: _tab, children: [
          _TxList(transactions: app.transactions),
          _TxList(transactions: app.transactions.where((t) => t.type == 'APPOINTMENT').toList()),
          _TxList(transactions: app.transactions.where((t) => t.type == 'ORDER').toList()),
        ]);
      }),
    );
  }
}

class _TxList extends StatelessWidget {
  final List<PaymentTransaction> transactions;
  const _TxList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const EmptyState(icon: Icons.credit_card_outlined, title: 'Tidak ada transaksi', subtitle: 'Belum ada riwayat transaksi');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (ctx, i) => _TxCard(tx: transactions[i]),
    );
  }
}

class _TxCard extends StatelessWidget {
  final PaymentTransaction tx;
  const _TxCard({required this.tx});

  Color get _statusColor {
    switch (tx.status.toUpperCase()) {
      case 'PAID': case 'SUCCESS': return AppTheme.success;
      case 'PENDING': return Colors.orange;
      case 'FAILED': return AppTheme.error;
      default: return AppTheme.textMuted;
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
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(tx.type == 'APPOINTMENT' ? Icons.calendar_today : Icons.local_pharmacy, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(tx.typeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            StatusBadge(label: tx.statusLabel, color: _statusColor),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Text('#${tx.id.length > 8 ? tx.id.substring(0, 8) : tx.id}', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace')),
            Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
            Text(formatDate(tx.createdAt), style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            if (tx.paymentMethod != null) ...[
              Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
              Icon(Icons.credit_card, size: 12, color: AppTheme.textMuted),
              Text(' ${tx.paymentMethod}', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ]),
          const SizedBox(height: 6),
          Text(formatPrice(tx.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}
