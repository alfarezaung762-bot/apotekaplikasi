import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../models/models.dart';

class DoctorSchedulePage extends StatefulWidget {
  const DoctorSchedulePage({super.key});
  @override
  State<DoctorSchedulePage> createState() => _State();
}

class _State extends State<DoctorSchedulePage> {
  bool _isLoading = true;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    await app.fetchDoctors();
    final doc = app.getDoctorByUserId(auth.user!.id);
    if (doc != null) {
      _doctorId = doc.id;
      await app.fetchDoctorTimeSlots(doc.id);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, String>> _next7Days() {
    final days = <Map<String, String>>[];
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final d = now.add(Duration(days: i));
      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final label = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'][d.weekday % 7];
      days.add({'date': dateStr, 'label': '$label, ${d.day}/${d.month}/${d.year}'});
    }
    return days;
  }

  void _addSlotDialog() {
    final days = _next7Days();
    String? selectedDate;
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
      title: const Text('Tambah Jadwal Baru'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Tanggal'),
          items: days.map((d) => DropdownMenuItem(value: d['date'], child: Text(d['label']!))).toList(),
          onChanged: (v) => setDlg(() => selectedDate = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: startCtrl,
          decoration: const InputDecoration(labelText: 'Jam Mulai (contoh: 08:00)', prefixIcon: Icon(Icons.access_time)),
          onTap: () async {
            final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
            if (time != null) startCtrl.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          },
          readOnly: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: endCtrl,
          decoration: const InputDecoration(labelText: 'Jam Selesai (contoh: 09:00)', prefixIcon: Icon(Icons.access_time)),
          onTap: () async {
            final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
            if (time != null) endCtrl.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          },
          readOnly: true,
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(onPressed: () async {
          if (selectedDate == null || startCtrl.text.isEmpty || endCtrl.text.isEmpty || _doctorId == null) return;
          await context.read<AppProvider>().addTimeSlot({
            'doctorId': _doctorId,
            'date': selectedDate,
            'startTime': startCtrl.text,
            'endTime': endCtrl.text,
          });
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal berhasil ditambahkan!')));
        }, child: const Text('Tambah')),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    final days = _next7Days();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Jadwal Praktik')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSlotDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AppProvider>(builder: (ctx, app, _) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: days.length,
                itemBuilder: (ctx, i) {
                  final day = days[i];
                  final slots = app.timeSlots.where((s) {
                    final slotDate = s.date.contains('T') ? s.date.split('T')[0] : s.date;
                    return slotDate == day['date'];
                  }).toList();
                  return _DayCard(date: day['date']!, label: day['label']!, slots: slots);
                },
              );
            }),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String date, label;
  final List<TimeSlot> slots;
  const _DayCard({required this.date, required this.label, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.surfaceDim, borderRadius: BorderRadius.circular(10)),
              child: Text('${slots.where((s) => s.isActive).length} slot', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ),
          ]),
        ),
        if (slots.isEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text('Tidak ada jadwal', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)))
        else
          ...slots.map((slot) => _SlotTile(slot: slot)),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final TimeSlot slot;
  const _SlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: slot.isActive ? AppTheme.primary.withOpacity(0.05) : AppTheme.surfaceDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: slot.isActive ? AppTheme.primary.withOpacity(0.2) : AppTheme.border),
      ),
      child: Row(children: [
        Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          '${slot.startTime} - ${slot.endTime}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, decoration: slot.isActive ? null : TextDecoration.lineThrough, color: slot.isActive ? null : AppTheme.textMuted),
        ),
        if (slot.isBooked) ...[
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('Dibooking', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600))),
        ],
        const Spacer(),
        Switch(
          value: slot.isActive,
          onChanged: (val) => context.read<AppProvider>().updateTimeSlotStatus(slot.id, val),
          activeColor: AppTheme.primary,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
          onPressed: () => context.read<AppProvider>().deleteTimeSlot(slot.id),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32),
        ),
      ]),
    );
  }
}
