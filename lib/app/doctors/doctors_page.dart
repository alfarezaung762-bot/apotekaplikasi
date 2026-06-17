import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../config/theme.dart';
import '../widgets/widgets.dart';
import '../models/doctor_profile.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});
  @override
  State<DoctorsPage> createState() => _State();
}

class _State extends State<DoctorsPage> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Cari Dokter')),
      body: Consumer<AppProvider>(builder: (ctx, app, _) {
        final docs = app.doctors.where((d) =>
          _search.isEmpty ||
          d.user.name.toLowerCase().contains(_search.toLowerCase()) ||
          d.specialization.toLowerCase().contains(_search.toLowerCase())
        ).toList();

        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(hintText: 'Cari dokter atau spesialisasi...', prefixIcon: const Icon(Icons.search, size: 20), filled: true, fillColor: AppTheme.surfaceDim),
            ),
          ),
          Expanded(
            child: docs.isEmpty
                ? const EmptyState(icon: Icons.search_off, title: 'Dokter tidak ditemukan', subtitle: '')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) => _DoctorCard(doctor: docs[i]),
                  ),
          ),
        ]);
      }),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorProfile doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailPage(doctor: doctor))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          AvatarInitials(name: doctor.user.name, size: 56),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doctor.user.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(doctor.specialization, style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(doctor.hospital, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              Text(' ${doctor.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(' (${doctor.reviewCount})', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const Spacer(),
              Text(formatPrice(doctor.price), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            ]),
          ])),
        ]),
      ),
    );
  }
}

// ── Doctor Detail + Booking ─────────────────────────────────
class DoctorDetailPage extends StatefulWidget {
  final DoctorProfile doctor;
  const DoctorDetailPage({super.key, required this.doctor});
  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  List<TimeSlot> _slots = [];
  bool _isLoading = true;
  String? _selectedDate;
  TimeSlot? _selectedSlot;
  String _consultationType = 'online';
  final _complaintCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final api = ApiService();
    final result = await api.get(ApiConfig.doctorTimeslotsById(widget.doctor.id));
    if (result['success'] == true && result['timeslots'] != null) {
      setState(() {
        _slots = (result['timeslots'] as List)
            .map((t) => TimeSlot.fromJson(t))
            .where((s) => s.isActive && !s.isBooked)
            .toList();
        if (_slots.isNotEmpty) {
          final grouped = _groupSlotsByDate();
          if (grouped.isNotEmpty) {
            _selectedDate = grouped.keys.first;
          }
        }
        _isLoading = false;
      });
    } else {
      // Try alternative endpoint
      final result2 = await api.get(ApiConfig.doctorTimeslots, queryParams: {'doctorId': widget.doctor.id});
      if (result2['success'] == true && result2['timeslots'] != null) {
        setState(() {
          _slots = (result2['timeslots'] as List)
              .map((t) => TimeSlot.fromJson(t))
              .where((s) => s.isActive && !s.isBooked)
              .toList();
          if (_slots.isNotEmpty) {
            final grouped = _groupSlotsByDate();
            if (grouped.isNotEmpty) {
              _selectedDate = grouped.keys.first;
            }
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, List<TimeSlot>> _groupSlotsByDate() {
    final map = <String, List<TimeSlot>>{};
    for (final s in _slots) {
      final date = s.date.contains('T') ? s.date.split('T')[0] : s.date;
      map.putIfAbsent(date, () => []).add(s);
    }
    return map;
  }

  String _formatIndoDayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final dayName = days[date.weekday % 7];
      final monthName = months[date.month - 1];
      return '$dayName, ${date.day} $monthName';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
    final grouped = _groupSlotsByDate();
    final dates = grouped.keys.toList();
    final activeSlots = _selectedDate != null ? (grouped[_selectedDate] ?? []) : [];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: Text(doc.user.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(children: [
              AvatarInitials(name: doc.user.name, size: 80),
              const SizedBox(height: 12),
              Text(doc.user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(doc.specialization, style: TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(doc.hospital, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _StatChip(icon: Icons.star, label: '${doc.rating}', color: Colors.amber),
                const SizedBox(width: 12),
                _StatChip(icon: Icons.work, label: '${doc.experience} thn', color: AppTheme.accent),
                const SizedBox(width: 12),
                _StatChip(icon: Icons.rate_review, label: '${doc.reviewCount} ulasan', color: AppTheme.primary),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Tipe Konsultasi
          const Text('Tipe Konsultasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _consultationType = 'online'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _consultationType == 'online' ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _consultationType == 'online' ? AppTheme.primary : AppTheme.border),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_outlined, color: _consultationType == 'online' ? Colors.white : AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 6),
                        Text('Online', style: TextStyle(color: _consultationType == 'online' ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _consultationType = 'offline'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _consultationType == 'offline' ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _consultationType == 'offline' ? AppTheme.primary : AppTheme.border),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined, color: _consultationType == 'offline' ? Colors.white : AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 6),
                        Text('Offline', style: TextStyle(color: _consultationType == 'offline' ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Schedule selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Tanggal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (dates.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Tidak ada jadwal tersedia', style: TextStyle(color: AppTheme.textMuted))))
                else ...[
                  // Date horizontal selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: dates.map((d) {
                        final isSelected = _selectedDate == d;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_formatIndoDayDate(d), style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedDate = d;
                                  _selectedSlot = null;
                                });
                              }
                            },
                            selectedColor: AppTheme.primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Pilih Waktu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  if (activeSlots.isEmpty)
                    Text('Tidak ada slot waktu untuk tanggal ini', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: activeSlots.map((s) {
                        final isSelected = _selectedSlot == s;
                        return ChoiceChip(
                          label: Text(s.startTime, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSlot = selected ? s : null;
                            });
                          },
                          selectedColor: AppTheme.accent,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.border),
                        );
                      }).toList(),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Keluhan
          const Text('Keluhan (Opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _complaintCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ceritakan keluhan atau gejala Anda...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _selectedSlot == null ? null : _submitBooking,
            child: Text(
              _selectedSlot == null ? 'Pilih Jadwal & Waktu' : 'Konfirmasi - ${formatPrice(doc.price)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_selectedSlot == null || _selectedDate == null) return;
    try {
      final auth = context.read<AuthProvider>();
      final app = context.read<AppProvider>();
      
      final pp = await app.fetchPatientProfile(auth.user!.id);
      if (pp == null) throw Exception('Profil pasien tidak ditemukan');

      await app.createAppointment({
        'patientId': pp.id,
        'doctorId': widget.doctor.id,
        'date': _selectedDate!,
        'time': _selectedSlot!.startTime,
        'type': _consultationType,
        'complaint': _complaintCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Janji berhasil dibuat! ✅'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
