import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/journal_entry.dart';

// ─── Journal list ─────────────────────────────────────────────────────────────

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DBHelper.instance.getJournals();
    if (mounted) setState(() => _entries = list);
  }

  Future<void> _open([JournalEntry? entry]) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => JournalEditorScreen(entry: entry)));
    _load();
  }

  Future<void> _delete(int id) async {
    await DBHelper.instance.deleteJournal(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My Journal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New Entry'),
      ),
      body: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📓', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    'Your journal is empty',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to write your first entry',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final e = _entries[i];
                return Dismissible(
                  key: Key('j_${e.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white),
                  ),
                  confirmDismiss: (_) => showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Entry'),
                      content: const Text(
                          'This entry will be permanently deleted.'),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () =>
                                Navigator.pop(ctx, true),
                            child: const Text('Delete')),
                      ],
                    ),
                  ),
                  onDismissed: (_) => _delete(e.id!),
                  child: GestureDetector(
                    onTap: () => _open(e),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant
                            .withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: theme.colorScheme.outline
                                .withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                e.title,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d').format(e.createdAt),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                      color: theme.colorScheme
                                          .onSurfaceVariant),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            e.content,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme
                                    .colorScheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Journal editor ───────────────────────────────────────────────────────────

class JournalEditorScreen extends StatefulWidget {
  final JournalEntry? entry;
  const JournalEditorScreen({super.key, this.entry});

  @override
  State<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.entry?.title ?? '');
    _contentCtrl =
        TextEditingController(text: widget.entry?.content ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in both the title and content.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    if (widget.entry == null) {
      await DBHelper.instance.insertJournal(JournalEntry(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      await DBHelper.instance.updateJournal(widget.entry!.copyWith(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        updatedAt: now,
      ));
    }
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.entry == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(children: [
          TextField(
            controller: _titleCtrl,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
            ),
          ),
          Divider(
              color: theme.colorScheme.outline.withOpacity(0.25)),
          const SizedBox(height: 4),
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(height: 1.55),
              decoration: const InputDecoration(
                hintText: 'Write your thoughts here…',
                border: InputBorder.none,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}