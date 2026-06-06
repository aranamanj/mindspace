import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/mood_entry.dart';
import 'mood_tracker_screen.dart';
import 'journal_screen.dart';
import 'breathing_screen.dart';
import 'notification_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MoodEntry? _latestMood;
  int _journalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final moods    = await DBHelper.instance.getMoods();
    final journals = await DBHelper.instance.getJournals();
    if (!mounted) return;
    setState(() {
      _latestMood   = moods.isNotEmpty ? moods.first : null;
      _journalCount = journals.length;
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MindSpace 🌿',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              _push(const NotificationSettingsScreen()),
                          icon: const Icon(
                              Icons.notifications_none_rounded),
                          tooltip: 'Reminders',
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Text(
                            DateFormat('d').format(DateTime.now()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Mood banner ─────────────────────────────────────────────
                _MoodBanner(
                  mood: _latestMood,
                  onTap: () => _push(const MoodTrackerScreen()),
                ),
                const SizedBox(height: 20),

                Text(
                  'What would you like to do?',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // ── Feature cards ───────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.edit_note_rounded,
                      label: 'Journal',
                      subtitle: '$_journalCount entries',
                      color: const Color(0xFF9C8FE6),
                      onTap: () => _push(const JournalScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.air_rounded,
                      label: 'Breathe',
                      subtitle: 'Calm down',
                      color: const Color(0xFF6BBFB5),
                      onTap: () => _push(const BreathingScreen()),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                _FeatureCard(
                  icon: Icons.mood_rounded,
                  label: 'Track Mood',
                  subtitle: 'Log how you feel right now',
                  color: const Color(0xFF6B9EFF),
                  onTap: () => _push(const MoodTrackerScreen()),
                  wide: true,
                ),
                const SizedBox(height: 12),

                _FeatureCard(
                  icon: Icons.notifications_active_rounded,
                  label: 'Reminders',
                  subtitle: 'Set daily check-in alerts',
                  color: const Color(0xFFFF8A65),
                  onTap: () => _push(const NotificationSettingsScreen()),
                  wide: true,
                ),
                const SizedBox(height: 24),

                // ── Affirmation ─────────────────────────────────────────────
                const _AffirmationCard(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MoodBanner extends StatelessWidget {
  final MoodEntry? mood;
  final VoidCallback onTap;
  const _MoodBanner({required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood == null ? 'No mood logged yet' : 'Latest mood',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood == null
                      ? 'Tap to log your mood'
                      : mood!.moodLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (mood != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d · h:mm a')
                        .format(mood!.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withOpacity(0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            mood == null ? '🌿' : mood!.moodEmoji,
            style: const TextStyle(fontSize: 52),
          ),
        ]),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(wide ? 14 : 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15)),
        ),
        child: wide
            ? Row(children: [
                _iconBox(color),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBox(color),
                  const SizedBox(height: 12),
                  Text(label,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
      ),
    );
  }

  Widget _iconBox(Color c) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: c, size: 22),
      );
}

class _AffirmationCard extends StatelessWidget {
  const _AffirmationCard();

  static const _affirmations = [
    "You are stronger than you think. 💙",
    "Every day is a new beginning. 🌱",
    "It's okay to take things one step at a time. 🌿",
    "You deserve peace and happiness. ☀️",
    "Your feelings are valid. 🌊",
    "Small progress is still progress. 🐢",
    "Be gentle with yourself today. 🌸",
    "You are not alone on this journey. 🤝",
    "Healing is not linear — keep going. 💫",
    "Rest is productive too. 🛌",
    "You have survived every hard day so far. 🌟",
    "Your mental health matters. 💚",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idx = DateTime.now()
            .difference(DateTime(DateTime.now().year))
            .inDays %
        _affirmations.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF9C8FE6).withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF9C8FE6).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF9C8FE6), size: 16),
            const SizedBox(width: 6),
            Text(
              'Daily Affirmation',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF9C8FE6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            _affirmations[idx],
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}