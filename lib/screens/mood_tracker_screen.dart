import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/mood_entry.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _noteCtrl = TextEditingController();

  int _selectedMood = 3;
  bool _saving = false;
  List<MoodEntry> _moods = [];

  static const _emojis  = ['😢', '😕', '😐', '🙂', '😄'];
  static const _labels  = ['Very Low', 'Low', 'Neutral', 'Good', 'Great'];
  static const _colors  = [
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFFFFD54F),
    Color(0xFF81C784),
    Color(0xFF4CAF50),
  ];

  Color  _color(int s) => _colors[s - 1];
  String _emoji(int s) => _emojis[s - 1];
  String _label(int s) => _labels[s - 1];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadMoods();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMoods() async {
    final list = await DBHelper.instance.getMoods();
    if (mounted) setState(() => _moods = list);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await DBHelper.instance.insertMood(MoodEntry(
      moodScore: _selectedMood,
      note: _noteCtrl.text.trim().isEmpty
          ? null
          : _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
    ));
    _noteCtrl.clear();
    await _loadMoods();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Mood logged! ${_emoji(_selectedMood)}'),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    _tabs.animateTo(1);
  }

  Future<void> _delete(int id) async {
    await DBHelper.instance.deleteMood(id);
    _loadMoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Log Mood'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildLog(), _buildHistory()],
      ),
    );
  }

  // ── Log tab ───────────────────────────────────────────────────────────────

  Widget _buildLog() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 8),
        Text(
          'How are you feeling?',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 36),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _emoji(_selectedMood),
            key: ValueKey(_selectedMood),
            style: const TextStyle(fontSize: 84),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            _label(_selectedMood),
            key: ValueKey(_selectedMood),
            style: theme.textTheme.titleMedium?.copyWith(
              color: _color(_selectedMood),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Mood selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final s   = i + 1;
            final sel = _selectedMood == s;
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sel
                      ? _color(s).withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel
                        ? _color(s)
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Text(
                  _emoji(s),
                  style: TextStyle(fontSize: sel ? 30 : 24),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 30),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Note (optional)',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "What's on your mind?",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14)),
            filled: true,
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : const Text('Log Mood',
                    style: TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    );
  }

  // ── History tab ───────────────────────────────────────────────────────────

  Widget _buildHistory() {
    final theme = Theme.of(context);
    if (_moods.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📊', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          Text(
            'No moods logged yet',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _moods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final mood = _moods[i];
        return Dismissible(
          key: Key('mood_${mood.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _delete(mood.id!),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border(
                  left: BorderSide(
                      color: _color(mood.moodScore), width: 4)),
            ),
            child: Row(children: [
              Text(_emoji(mood.moodScore),
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(mood.moodScore),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _color(mood.moodScore),
                      ),
                    ),
                    if (mood.note != null &&
                        mood.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        mood.note!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d\nh:mm a').format(mood.createdAt),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ]),
          ),
        );
      },
    );
  }
}