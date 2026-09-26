import 'package:flutter/material.dart';
import 'package:sportlinea_app/api/models.dart';
import 'package:sportlinea_app/theme.dart';

String when(DateTime dt) {
  final l = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
}

DateTime? parseWhen(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Widget notificationFromMap(Map<String, dynamic> n) {
  return NotificationCard(
    type: n['type']?.toString() ?? '',
    text: n['text']?.toString() ?? '',
    sentAt: parseWhen(n['sentAt']),
  );
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 22, color: Sl.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Sl.text)),
          ),
        ],
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.label, this.onPressed, this.outlined = false});
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Sl.text,
          side: const BorderSide(color: Color(0x80FFFFFF)),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(label, textAlign: TextAlign.center),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Sl.accent,
        foregroundColor: Sl.primary,
        disabledBackgroundColor: Sl.border,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding, this.gold = false});
  final Widget child;
  final EdgeInsets? padding;
  final bool gold;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gold ? null : Sl.card,
        gradient: gold
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x24F5C518), Color(0xCC122A22)],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold ? const Color(0x59F5C518) : Sl.border),
      ),
      child: child,
    );
  }
}

class SportChip extends StatelessWidget {
  const SportChip(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: Sl.primaryLight, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(color: Sl.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.onTap});
  final SportEventDto event;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Sl.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Sl.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 6, runSpacing: 4, children: [
              SportChip(event.sportType),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Sl.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Sl.border),
                ),
                child: Text(event.sportCategory, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Sl.muted)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Sl.text)),
            const SizedBox(height: 4),
            Text(when(event.startDate), style: const TextStyle(color: Sl.muted, fontSize: 13)),
            if (event.coefficients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: event.coefficients.map((c) {
                  return Container(
                    constraints: const BoxConstraints(minWidth: 84),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Sl.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Sl.border),
                    ),
                    child: Column(
                      children: [
                        Text(c.title, style: const TextStyle(fontSize: 12, color: Sl.text)),
                        Text(c.value.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Sl.accent)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label, this.color, this.compact = false});
  final String value;
  final String label;
  final Color? color;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: compact ? const EdgeInsets.symmetric(horizontal: 10, vertical: 12) : const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: compact ? 20 : 26, fontWeight: FontWeight.w800, color: color ?? Sl.accent)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: Sl.muted, fontSize: compact ? 12 : 13)),
        ],
      ),
    );
  }
}

class AlertBox extends StatelessWidget {
  const AlertBox(this.text, {super.key, this.kind = 'error'});
  final String text;
  final String kind;
  @override
  Widget build(BuildContext context) {
    final style = switch (kind) {
      'success' => (const Color(0x1A2ECC71), const Color(0x8C2ECC71), const Color(0xFFB8F0C8)),
      'warning' => (const Color(0x1FF1C40F), const Color(0xA6F1C40F), const Color(0xFFFFE082)),
      'bonus' => (const Color(0x1AF5C518), const Color(0x8CF5C518), const Color(0xFFFFE9A8)),
      _ => (const Color(0x1FE74C3C), const Color(0xA6E74C3C), const Color(0xFFFF6B6B)),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.$2),
      ),
      child: Text(text, style: TextStyle(color: style.$3, height: 1.35, fontSize: 13)),
    );
  }
}

class HeaderLink extends StatelessWidget {
  const HeaderLink({super.key, required this.label, required this.onTap, this.accent = false});
  final String label;
  final VoidCallback onTap;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 4, 6),
        child: Text(
          label,
          style: TextStyle(
            color: accent ? Sl.accent : const Color(0xE6FFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final bg = switch (status) {
      'Won' => Sl.success,
      'Lost' => Sl.danger,
      'Cancelled' => Sl.muted,
      _ => Sl.pending,
    };
    final label = switch (status) {
      'Won' => 'Выиграла',
      'Lost' => 'Проиграла',
      'Cancelled' => 'Отмена',
      _ => 'Принята',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.type, required this.text, this.sentAt});
  final String type;
  final String text;
  final DateTime? sentAt;

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final style = switch (type) {
      'BetLoss' || 'WithdrawalRejected' || 'BalanceReset' => _NoteStyle.loss,
      'BetWin' || 'WithdrawalApproved' || 'BalanceDeposit' || 'WithdrawalAccepted' => _NoteStyle.win,
      'Bonus' => _NoteStyle.bonus,
      'WithdrawalPending' => _NoteStyle.warning,
      'BetResult' when lower.contains('проиграла') => _NoteStyle.loss,
      'BetResult' when lower.contains('выиграла') => _NoteStyle.win,
      _ => _NoteStyle.info,
    };
    final label = switch (type) {
      'BetLoss' => 'Проигрыш',
      'BetWin' => 'Выигрыш',
      'Bonus' => 'Бонус',
      'WithdrawalPending' => 'Вывод на проверке',
      'WithdrawalApproved' => 'Вывод подтверждён',
      'WithdrawalRejected' => 'Вывод отклонён',
      'BalanceReset' => 'Обнуление счёта',
      'BalanceDeposit' => 'Пополнение баланса',
      'WithdrawalAccepted' => 'Вывод средств',
      'BetResult' => 'Ставка',
      'Registration' => 'Регистрация',
      _ => 'Инфо',
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(color: style.badge, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                ),
              ),
              if (sentAt != null) Text(when(sentAt!), style: const TextStyle(color: Sl.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: style.text, height: 1.35)),
        ],
      ),
    );
  }
}

class _NoteStyle {
  const _NoteStyle({required this.bg, required this.border, required this.text, required this.badge});
  final Color bg;
  final Color border;
  final Color text;
  final Color badge;

  static const loss = _NoteStyle(
    bg: Color(0x1FE74C3C),
    border: Color(0xA6E74C3C),
    text: Color(0xFFFF6B6B),
    badge: Color(0xFFFF6B6B),
  );
  static const win = _NoteStyle(
    bg: Color(0x1A2ECC71),
    border: Color(0x8C2ECC71),
    text: Color(0xFFB8F0C8),
    badge: Sl.success,
  );
  static const bonus = _NoteStyle(
    bg: Color(0x1AF5C518),
    border: Color(0x8CF5C518),
    text: Color(0xFFFFE9A8),
    badge: Sl.accent,
  );
  static const warning = _NoteStyle(
    bg: Color(0x1FF1C40F),
    border: Color(0xA6F1C40F),
    text: Color(0xFFFFE082),
    badge: Color(0xFFF1C40F),
  );
  static const info = _NoteStyle(bg: Sl.card, border: Sl.border, text: Sl.text, badge: Sl.muted);
}

class FilterChipBtn extends StatelessWidget {
  const FilterChipBtn({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Sl.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? Sl.accent : const Color(0x80FFFFFF)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Sl.primary : Sl.text,
            ),
          ),
        ),
      ),
    );
  }
}
