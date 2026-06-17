import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

// ═══════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATUS BADGE — Supports both status-string and label+color modes
// ═══════════════════════════════════════════════════════════════
class StatusBadge extends StatelessWidget {
  final String? status;
  final String? label;
  final Color? color;

  const StatusBadge({super.key, this.status, this.label, this.color});

  Color get _bgColor {
    if (color != null) return color!.withOpacity(0.12);
    switch (status) {
      case 'confirmed': return const Color(0xFFDCFCE7);
      case 'pending': return const Color(0xFFFEF9C3);
      case 'completed': return const Color(0xFFDBEAFE);
      case 'cancelled': return const Color(0xFFFEE2E2);
      case 'processing': return const Color(0xFFDBEAFE);
      case 'shipped': return const Color(0xFFE9D5FF);
      case 'delivered': return const Color(0xFFDCFCE7);
      default: return const Color(0xFFF1F5F9);
    }
  }

  Color get _textColor {
    if (color != null) return color!;
    switch (status) {
      case 'confirmed': return const Color(0xFF15803D);
      case 'pending': return const Color(0xFFA16207);
      case 'completed': return const Color(0xFF1D4ED8);
      case 'cancelled': return const Color(0xFFB91C1C);
      case 'processing': return const Color(0xFF1D4ED8);
      case 'shipped': return const Color(0xFF7C3AED);
      case 'delivered': return const Color(0xFF15803D);
      default: return const Color(0xFF475569);
    }
  }

  String get _label {
    if (label != null) return label!;
    const labels = {
      'pending': 'Menunggu',
      'confirmed': 'Dikonfirmasi',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
      'processing': 'Diproses',
      'shipped': 'Dikirim',
      'delivered': 'Diterima',
    };
    return labels[status] ?? status ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textColor)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AVATAR INITIALS
// ═══════════════════════════════════════════════════════════════
class AvatarInitials extends StatelessWidget {
  final String name;
  final double size;
  final Color? bgColor;
  final Color? textColor;

  const AvatarInitials({super.key, required this.name, this.size = 44, this.bgColor, this.textColor});

  String get _initials {
    final parts = name.split(' ').where((n) => !n.startsWith('Dr')).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bgColor ?? AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(_initials, style: TextStyle(
        fontSize: size * 0.35,
        fontWeight: FontWeight.w600,
        color: textColor ?? AppTheme.primary,
      )),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.buttonText, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════
String formatPrice(double price) {
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  return formatter.format(price);
}

String formatTime(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('HH:mm').format(date);
  } catch (_) {
    return dateString;
  }
}

String formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy', 'id').format(date);
  } catch (_) {
    return dateString;
  }
}
