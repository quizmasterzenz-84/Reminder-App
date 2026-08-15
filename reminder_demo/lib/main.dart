import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reusable_reminder_kit/reusable_reminder_kit.dart';

void main() {
  runApp(const ReminderDemoApp());
}

class ReminderDemoApp extends StatelessWidget {
  const ReminderDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reminder Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: const ReminderHomePage(),
    );
  }
}

class _Reminder {
  final int id;
  final String categoryId;
  final String categoryName;
  final Importance importance;
  final String title;
  final DateTime nextTriggerTime;
  final DateTime? finalTime;
  final String? snoozeLabel;

  const _Reminder({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.importance,
    required this.title,
    required this.nextTriggerTime,
    this.finalTime,
    this.snoozeLabel,
  });
}

class ReminderHomePage extends StatefulWidget {
  const ReminderHomePage({super.key});

  @override
  State<ReminderHomePage> createState() => _ReminderHomePageState();
}

class _ReminderHomePageState extends State<ReminderHomePage> {
  final List<CategoryOption> _categories = [
    CategoryOption(id: 'work', name: 'Work', importance: Importance.high),
    CategoryOption(id: 'health', name: 'Health', importance: Importance.medium),
    CategoryOption(id: 'home', name: 'Home', importance: Importance.low),
  ];

  static final List<FilterOption<int>> _filterOptions = [
    const FilterOption<int>('Next 7 days', 7),
    const FilterOption<int>('Next 14 days', 14),
    const FilterOption<int>('Next 21 days', 21),
    const FilterOption<int>('Next 30 days', 30),
  ];

  late final List<_Reminder> _reminders = [
    _Reminder(
      id: 1,
      categoryId: 'work',
      categoryName: 'Work',
      importance: Importance.high,
      title: 'Client follow-up',
      nextTriggerTime: DateTime.now().add(const Duration(days: 3)),
      finalTime: DateTime.now().add(const Duration(days: 17)),
      snoozeLabel: '10 min',
    ),
    _Reminder(
      id: 2,
      categoryId: 'health',
      categoryName: 'Health',
      importance: Importance.medium,
      title: 'Take medicine',
      nextTriggerTime: DateTime.now().add(const Duration(hours: 2)),
      snoozeLabel: '5 min',
    ),
    _Reminder(
      id: 3,
      categoryId: 'home',
      categoryName: 'Home',
      importance: Importance.low,
      title: 'Water the plants',
      nextTriggerTime: DateTime.now().add(const Duration(days: 6)),
    ),
  ];

  int _nextId = 4;
  int _selectedDays = 14;
  String? _selectedCategoryId;
  late Timer _clockTimer;
  final Set<int> _alreadyNotifiedIds = {};

  @override
  void initState() {
    super.initState();
    // Ticks every second so "due now" state and badges update live, with no
    // need to re-open the screen — satisfies real-time (down to the minute)
    // reminder testing.
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkForNewlyDueReminders();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _checkForNewlyDueReminders() {
    final now = DateTime.now();
    for (final reminder in _reminders) {
      final isDue = !reminder.nextTriggerTime.isAfter(now);
      if (isDue && _alreadyNotifiedIds.add(reminder.id)) {
        if (!mounted) continue;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 "${reminder.title}" is due now!'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    Importance selectedImportance = Importance.medium;
    final result = await showDialog<CategoryOption>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add new category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Category name'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<Importance>(
                segments: const [
                  ButtonSegment(
                    value: Importance.high,
                    label: Text('High'),
                  ),
                  ButtonSegment(
                    value: Importance.medium,
                    label: Text('Medium'),
                  ),
                  ButtonSegment(value: Importance.low, label: Text('Low')),
                ],
                selected: {selectedImportance},
                onSelectionChanged: (value) =>
                    setDialogState(() => selectedImportance = value.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop(
                  CategoryOption(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                    importance: selectedImportance,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() => _categories.add(result));
    }
  }

  Future<void> _addReminder({_Reminder? editing}) async {
    final titleController = TextEditingController(text: editing?.title);
    final snoozeController = TextEditingController(text: editing?.snoozeLabel);
    String? categoryId = editing?.categoryId ??
        (_categories.isNotEmpty ? _categories.first.id : null);
    final initialTime = editing?.nextTriggerTime ??
        DateTime.now().add(const Duration(minutes: 1));
    DateTime pickedDate = DateTime(
      initialTime.year,
      initialTime.month,
      initialTime.day,
    );
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(initialTime);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editing == null ? 'Add reminder' : 'Edit reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                CategorySelector(
                  categories: _categories,
                  selectedId: categoryId,
                  onSelected: (value) =>
                      setDialogState(() => categoryId = value),
                  onAddNewCategory: () async {
                    Navigator.of(context).pop(false);
                    await _addCategory();
                    if (mounted) await _addReminder();
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${formatShortDate(pickedDate)}'),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () async {
                    // No minimum-day restriction: firstDate is "now", so
                    // today (and thus "1 minute from now") stays selectable.
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: pickedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (selected != null) {
                      setDialogState(() => pickedDate = selected);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Time: ${pickedTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: pickedTime,
                    );
                    if (selected != null) {
                      setDialogState(() => pickedTime = selected);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: snoozeController,
                  decoration: const InputDecoration(
                    labelText: 'Snooze label (optional)',
                    hintText: 'e.g. 5 min',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
                onPressed: () {
                if (titleController.text.trim().isEmpty || categoryId == null) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || categoryId == null) return;

    final category = _categories.firstWhere((c) => c.id == categoryId);
    final nextTriggerTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final updatedReminder = _Reminder(
      id: editing?.id ?? _nextId++,
      categoryId: category.id,
      categoryName: category.name,
      importance: category.importance,
      title: titleController.text.trim(),
      nextTriggerTime: nextTriggerTime,
      finalTime: editing?.finalTime,
      snoozeLabel: snoozeController.text.trim().isEmpty
          ? null
          : snoozeController.text.trim(),
    );

    setState(() {
      if (editing == null) {
        _reminders.add(updatedReminder);
      } else {
        final index = _reminders.indexWhere((reminder) => reminder.id == editing.id);
        if (index != -1) _reminders[index] = updatedReminder;
        _alreadyNotifiedIds.remove(editing.id);
      }
    });
  }

  Future<void> _showReminderDetails(_Reminder reminder) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reminder.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${reminder.categoryName}'),
            Text('Importance: ${reminder.importance.label}'),
            Text('Next: ${formatShortDateTime(reminder.nextTriggerTime)}'),
            if (reminder.finalTime != null)
              Text('Final: ${formatShortDateTime(reminder.finalTime!)}'),
            if (reminder.snoozeLabel != null)
              Text('Snooze: ${reminder.snoozeLabel}'),
            Text(
              !reminder.nextTriggerTime.isAfter(DateTime.now())
                  ? 'Status: Due now'
                  : 'Status: Scheduled',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('close'),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('edit'),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (action == 'edit') {
      await _addReminder(editing: reminder);
    } else if (action == 'delete') {
      await _deleteReminder(reminder);
    }
  }

  Future<void> _deleteReminder(_Reminder reminder) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Delete reminder?',
      message: 'This will remove "${reminder.title}" permanently.',
    );
    if (confirmed) {
      setState(() {
        _reminders.removeWhere((r) => r.id == reminder.id);
        _alreadyNotifiedIds.remove(reminder.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final windowEnd = now.add(Duration(days: _selectedDays));
    final visibleReminders =
        _reminders.where((reminder) {
          if (_selectedCategoryId != null &&
              reminder.categoryId != _selectedCategoryId) {
            return false;
          }
          return !reminder.nextTriggerTime.isAfter(windowEnd);
        }).toList()
          ..sort((a, b) => a.nextTriggerTime.compareTo(b.nextTriggerTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Reminders update live — try adding one for 1 minute from now.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add reminder'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Your reminders',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Set any date and time — even a minute from now — and this list '
              'updates automatically the instant it becomes due.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilterChipsRow<int>(
              options: _filterOptions,
              selected: _selectedDays,
              onSelected: (value) => setState(() => _selectedDays = value),
            ),
            const SizedBox(height: 16),
            CategorySelector(
              categories: _categories,
              selectedId: _selectedCategoryId,
              onSelected: (value) =>
                  setState(() => _selectedCategoryId = value),
              onAddNewCategory: _addCategory,
            ),
            const SizedBox(height: 24),
            if (visibleReminders.isEmpty)
              EmptyStateView(
                icon: Icons.event_busy,
                title: 'No reminders match this filter',
                message:
                    'Change the category or time window, or add a new reminder.',
                actionLabel: 'Reset filters',
                onAction: () {
                  setState(() {
                    _selectedDays = 14;
                    _selectedCategoryId = null;
                  });
                },
              )
            else
              ...visibleReminders.map(
                (reminder) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ReminderListTile(
                    category: reminder.categoryName,
                    importance: reminder.importance,
                    title: reminder.title,
                    nextTriggerTime: reminder.nextTriggerTime,
                    finalTime: reminder.finalTime,
                    snoozeLabel: reminder.snoozeLabel,
                    isDue: !reminder.nextTriggerTime.isAfter(now),
                    onTap: () => _showReminderDetails(reminder),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
