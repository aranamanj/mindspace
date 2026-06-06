import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _moodEnabled    = false;
  bool _journalEnabled = false;
  TimeOfDay _moodTime    = const TimeOfDay(hour: 9,  minute: 0);
  TimeOfDay _journalTime = const TimeOfDay(hour: 21, minute: 0);
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DBHelper.instance;
    final me = await db.getSetting('mood_notif_enabled');
    final mh = await db.getSetting('mood_notif_hour');
    final mm = await db.getSetting('mood_notif_minute');
    final je = await db.getSetting('journal_notif_enabled');
    final jh = await db.getSetting('journal_notif_hour');
    final jm = await db.getSetting('journal_notif_minute');
    if (!mounted) return;
    setState(() {
      _moodEnabled    = me == 'true';
      _journalEnabled = je == 'true';
      if (mh != null) {
        _moodTime = TimeOfDay(
            hour: int.parse(mh), minute: int.parse(mm ?? '0'));
      }
      if (jh != null) {
        _journalTime = TimeOfDay(
            hour: int.parse(jh), minute: int.parse(jm ?? '0'));
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final granted =
        await NotificationService.instance.requestPermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notification permission denied.'),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _saving = false);
      return;
    }

    final db = DBHelper.instance;

    // Mood reminder
    await db.setSetting('mood_notif_enabled', _moodEnabled.toString());
    await db.setSetting('mood_notif_hour',    _moodTime.hour.toString());
    await db.setSetting('mood_notif_minute',  _moodTime.minute.toString());
    if (_moodEnabled) {
      await NotificationService.instance
          .scheduleMoodReminder(_moodTime);
    } else {
      await NotificationService.instance.cancelMoodReminder();
    }

    // Journal reminder
    await db.setSetting(
        'journal_notif_enabled', _journalEnabled.toString());
    await db.setSetting(
        'journal_notif_hour', _journalTime.hour.toString());
    await db.setSetting(
        'journal_notif_minute', _journalTime.minute.toString());
    if (_journalEnabled) {
      await NotificationService.instance
          .scheduleJournalReminder(_journalTime);
    } else {
      await NotificationService.instance.cancelJournalReminder();
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Reminders saved ✅'),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _pickTime(bool isMood) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMood ? _moodTime : _journalTime,
    );
    if (picked != null) {
      setState(() {
        if (isMood) _moodTime = picked; else _journalTime = picked;
      });
    }
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Info banner ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Text('🔔',
                        style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Daily reminders help you build a consistent self-care habit.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── Mood ──────────────────────────────────────────────────
                Text(
                  'Mood Check-In',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _ReminderCard(
                  emoji: '😊',
                  title: 'Daily Mood Reminder',
                  subtitle: 'Get nudged to log your mood',
                  enabled: _moodEnabled,
                  formattedTime: _fmt(_moodTime),
                  onToggle: (v) => setState(() => _moodEnabled = v),
                  onTimeTap: () => _pickTime(true),
                ),
                const SizedBox(height: 24),

                // ── Journal ───────────────────────────────────────────────
                Text(
                  'Journaling',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _ReminderCard(
                  emoji: '✍️',
                  title: 'Daily Journal Reminder',
                  subtitle: 'Prompt yourself to reflect',
                  enabled: _journalEnabled,
                  formattedTime: _fmt(_journalTime),
                  onToggle: (v) =>
                      setState(() => _journalEnabled = v),
                  onTimeTap: () => _pickTime(false),
                ),
                const SizedBox(height: 36),

                // ── Save ──────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Text('Save Reminders',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool enabled;
  final String formattedTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _ReminderCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.formattedTime,
    required this.onToggle,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: enabled
            ? theme.colorScheme.primaryContainer.withOpacity(0.25)
            : theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(children: [
        ListTile(
          leading:
              Text(emoji, style: const TextStyle(fontSize: 26)),
          title: Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          subtitle:
              Text(subtitle, style: theme.textTheme.bodySmall),
          trailing: Switch(value: enabled, onChanged: onToggle),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: !enabled
              ? const SizedBox.shrink()
              : Column(children: [
                  Divider(
                      height: 1,
                      color: theme.colorScheme.outline
                          .withOpacity(0.15)),
                  InkWell(
                    onTap: onTimeTap,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 18,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text('Remind me at',
                            style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            formattedTime,
                            style:
                                theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
        ),
      ]),
    );
  }
}