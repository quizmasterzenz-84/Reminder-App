import 'dart:async';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:reusable_reminder_kit/reusable_reminder_kit.dart';

import 'alarm/alarm_handler.dart';
import 'alarm/alarm_scheduler.dart';
import 'audio/cleanup/audio_cleanup_service.dart';
import 'audio/picker/audio_picker.dart';
import 'audio/recording/voice_recorder.dart';
import 'audio/system/system_alarm_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  AlarmHandler.initialize();
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

  // Link to the alarm's audio source (system tone, recording, or picked file).
  // Null means "no audio chosen yet" — existing reminders keep working as-is.
  final String? audioPath;
  final String? audioId;

  const _Reminder({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.importance,
    required this.title,
    required this.nextTriggerTime,
    this.finalTime,
    this.snoozeLabel,
    this.audioPath,
    this.audioId,
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
    String? audioPath = editing?.audioPath;
    String? audioId = editing?.audioId;

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
                const SizedBox(height: 12),
                Text(
                  'Alarm sound',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  audioId == null ? 'Default tone' : audioId!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.alarm),
                      label: const Text('System tone'),
                      onPressed: () async {
                        final picked = await _pickSystemTone(context);
                        if (picked != null) {
                          setDialogState(() {
                            audioPath = picked.path;
                            audioId = picked.id;
                          });
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.mic),
                      label: const Text('Record voice'),
                      onPressed: () async {
                        final recorded = await _recordVoiceMessage(context);
                        if (recorded != null) {
                          setDialogState(() {
                            audioPath = recorded.path;
                            audioId = recorded.id;
                          });
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Pick file'),
                      onPressed: () async {
                        final picked = await AudioPicker.pickAudioFile();
                        if (picked != null) {
                          setDialogState(() {
                            audioPath = picked.path;
                            audioId = picked.id;
                          });
                        }
                      },
                    ),
                    if (audioPath != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        onPressed: () => setDialogState(() {
                          audioPath = null;
                          audioId = null;
                        }),
                      ),
                  ],
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
      audioPath: audioPath,
      audioId: audioId,
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

    // Best-effort: native alarm scheduling only works on a real Android build.
    try {
      await AlarmScheduler.scheduleReminder(
        id: updatedReminder.id,
        dateTime: updatedReminder.nextTriggerTime,
        audioPath: updatedReminder.audioPath,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule alarm: $error')),
      );
    }
  }

  Future<({String path, String id})?> _pickSystemTone(
    BuildContext dialogContext,
  ) async {
    List<FileSystemEntity> tones;
    try {
      tones = await SystemAlarmLoader.loadSystemAlarmTones();
    } catch (error) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Could not load alarm tones: $error')),
        );
      }
      return null;
    }
    if (!dialogContext.mounted) return null;
    if (tones.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('No system alarm tones found on this device.'),
        ),
      );
      return null;
    }

    return showDialog<({String path, String id})>(
      context: dialogContext,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a system tone'),
        children: [
          for (final tone in tones)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop((
                path: tone.path,
                id: p.basenameWithoutExtension(tone.path),
              )),
              child: Text(p.basename(tone.path)),
            ),
        ],
      ),
    );
  }

  Future<({String path, String id})?> _recordVoiceMessage(
    BuildContext dialogContext,
  ) async {
    final recorder = VoiceRecorder();
    String? started;
    try {
      started = await recorder.startRecording();
    } catch (error) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Could not start recording: $error')),
        );
      }
      await recorder.dispose();
      return null;
    }
    if (!dialogContext.mounted || started == null) return null;

    final stop = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recording\u2026'),
        content: const Text('Tap stop when you\'re done.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (stop != true) return null;
    final path = await recorder.stopRecording();
    await recorder.dispose();
    if (path == null) return null;
    return (path: path, id: p.basenameWithoutExtension(path));
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
      await AudioCleanupService.deleteAudioIfUnused(
        deletedId: reminder.id,
        audioPath: reminder.audioPath,
        audioId: reminder.audioId,
        others: _reminders
            .where((r) => r.id != reminder.id)
            .map((r) => (id: r.id, audioId: r.audioId))
            .toList(),
      );
      try {
        await AlarmScheduler.cancelReminder(reminder.id);
      } catch (_) {
        // Ignore on platforms/tests where the alarm plugin isn't available.
      }
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
            tooltip: 'Where are my recordings stored?',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Where are my recorded messages stored?'),
                  content: const Text(
                    'Your recorded reminder messages are saved in your '
                    "phone's Music folder.\n\n"
                    'To view or delete them:\n'
                    'Open File Manager → Audio → Music → ReminderApp',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
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
