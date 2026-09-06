import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'importance': importance.index,
        'title': title,
        'nextTriggerTime': nextTriggerTime.toIso8601String(),
        'finalTime': finalTime?.toIso8601String(),
        'snoozeLabel': snoozeLabel,
        'audioPath': audioPath,
        'audioId': audioId,
      };

  static _Reminder? fromJson(Map<String, dynamic> json) {
    try {
      final importanceIndex = json['importance'] as int;
      if (importanceIndex < 0 || importanceIndex >= Importance.values.length) {
        return null;
      }
      return _Reminder(
        id: json['id'] as int,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        importance: Importance.values[importanceIndex],
        title: json['title'] as String,
        nextTriggerTime: DateTime.parse(json['nextTriggerTime'] as String),
        finalTime: json['finalTime'] == null
            ? null
            : DateTime.parse(json['finalTime'] as String),
        snoozeLabel: json['snoozeLabel'] as String?,
        audioPath: json['audioPath'] as String?,
        audioId: json['audioId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

class _AudioEntry {
  final String id;
  final String path;
  final String tag;

  const _AudioEntry({required this.id, required this.path, required this.tag});

  Map<String, dynamic> toJson() => {'id': id, 'path': path, 'tag': tag};

  static _AudioEntry? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final path = json['path'];
    final tag = json['tag'];
    if (id is! String || path is! String || tag is! String) return null;
    return _AudioEntry(id: id, path: path, tag: tag);
  }
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

  final List<_Reminder> _reminders = [];
  final List<_AudioEntry> _audioLibrary = [];

  int _nextId = 1;
  bool _isLoadingReminders = true;
  int _selectedDays = 14;
  String? _selectedCategoryId;
  late Timer _clockTimer;
  final Set<int> _alreadyNotifiedIds = {};
  String _appVersion = '';

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
    _loadAppVersion();
    _loadReminders();
    _loadAudioLibrary();
  }

  Future<File> _remindersFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, 'reminders.json'));
  }

  Future<void> _loadReminders() async {
    try {
      final file = await _remindersFile();
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          final loaded = decoded
              .whereType<Map>()
              .map((item) => _Reminder.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .whereType<_Reminder>()
              .toList();
          _reminders
            ..clear()
            ..addAll(loaded);
          if (loaded.isNotEmpty) {
            _nextId = loaded.map((reminder) => reminder.id).reduce(
                  (largest, id) => id > largest ? id : largest,
                ) +
                1;
            for (final reminder in loaded) {
              if (reminder.nextTriggerTime.isAfter(DateTime.now())) {
                await AlarmScheduler.scheduleReminder(
                  id: reminder.id,
                  dateTime: reminder.nextTriggerTime,
                  audioPath: reminder.audioPath,
                );
              }
            }
          }
        }
      }
    } catch (error) {
      debugPrint('ReminderStorage: unable to load reminders: $error');
    }
    if (!mounted) return;
    setState(() => _isLoadingReminders = false);
  }

  Future<void> _saveReminders() async {
    try {
      final file = await _remindersFile();
      await file.writeAsString(jsonEncode(
        _reminders.map((reminder) => reminder.toJson()).toList(),
      ));
    } catch (error) {
      debugPrint('ReminderStorage: unable to save reminders: $error');
    }
  }

  Future<File> _audioLibraryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, 'audio_library.json'));
  }

  Future<void> _loadAudioLibrary() async {
    try {
      final file = await _audioLibraryFile();
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          _audioLibrary
            ..clear()
            ..addAll(decoded
                .whereType<Map>()
                .map((item) => _AudioEntry.fromJson(
                      Map<String, dynamic>.from(item),
                    ))
                .whereType<_AudioEntry>());
        }
      }
    } catch (error) {
      debugPrint('AudioLibrary: unable to load: $error');
    }
  }

  Future<void> _saveAudioLibrary() async {
    try {
      final file = await _audioLibraryFile();
      await file.writeAsString(jsonEncode(
        _audioLibrary.map((entry) => entry.toJson()).toList(),
      ));
    } catch (error) {
      debugPrint('AudioLibrary: unable to save: $error');
    }
  }

  Future<void> _addAudioEntry({required String path, required String tag}) async {
    final entry = _AudioEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      path: path,
      tag: tag,
    );
    _audioLibrary.removeWhere((item) => item.path == path);
    _audioLibrary.add(entry);
    await _saveAudioLibrary();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version}+${info.buildNumber}');
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
    debugPrint(
      'ReminderFlow: opening ${editing == null ? 'add' : 'edit'} dialog',
    );
    final hasExactAlarmPermission =
        await AlarmScheduler.ensureExactAlarmPermission();
    if (!hasExactAlarmPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Allow Alarms & reminders, then add the reminder again.',
          ),
        ),
      );
      return;
    }
    final saved = await showDialog<_ReminderDraft>(
      context: context,
      builder: (context) => _ReminderEditorDialog(
        editing: editing,
        categories: _categories,
        onAddCategory: _addCategory,
        onPickSystemTone: _pickSystemTone,
        onPickSavedAudio: _pickSavedAudio,
        onPickFile: AudioPicker.pickAudioFile,
        onSaveAudio: (path, tag) => _addAudioEntry(path: path, tag: tag),
      ),
    );

    debugPrint('ReminderFlow: dialog returned saved=${saved != null}');
    if (saved == null || saved.categoryId == null) {
      debugPrint('ReminderFlow: reminder was not saved');
      return;
    }

    final category = _categories.firstWhere((c) => c.id == saved.categoryId);
    final updatedReminder = _Reminder(
      id: editing?.id ?? _nextId++,
      categoryId: category.id,
      categoryName: category.name,
      importance: category.importance,
      title: saved.title,
      nextTriggerTime: saved.nextTriggerTime,
      finalTime: editing?.finalTime,
      snoozeLabel: saved.snoozeLabel,
      audioPath: saved.audioPath,
      audioId: saved.audioId,
    );

    // Schedule first so an unscheduled reminder is never persisted to the UI.
    try {
      debugPrint('ReminderFlow: scheduling id=${updatedReminder.id}');
      await AlarmScheduler.scheduleReminder(
        id: updatedReminder.id,
        dateTime: updatedReminder.nextTriggerTime,
        audioPath: updatedReminder.audioPath,
      );
      debugPrint('ReminderFlow: scheduling succeeded id=${updatedReminder.id}');
    } catch (error) {
      debugPrint('ReminderFlow: scheduling failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule alarm: $error')),
      );
      return;
    }

    setState(() {
      if (editing == null) {
        _reminders.add(updatedReminder);
      } else {
        final index = _reminders.indexWhere((reminder) => reminder.id == editing.id);
        if (index != -1) _reminders[index] = updatedReminder;
        _alreadyNotifiedIds.remove(editing.id);
      }
    });
    await _saveReminders();
  }

  /*
    The editor dialog is a dedicated StatefulWidget below. Keeping its async
    form state out of the page prevents dialog teardown from retaining stale
    inherited-widget dependents.
  */
  /* OLD_EDITOR_REMOVED
        builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editing == null ? 'Add reminder' : 'Edit reminder'),
          scrollable: true,
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
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
                Text(
                  'Alarm sound',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  audioId == null ? 'Default tone' : audioId!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // On narrow screens (mobile), stack buttons vertically
                    if (constraints.maxWidth < 300) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.alarm),
                            label: const Text('System tone'),
                            onPressed: () async {
                              debugPrint('ReminderFlow: system tone tapped');
                              final picked = await _pickSystemTone(context);
                              if (picked != null) {
                                if (!context.mounted) return;
                                setDialogState(() {
                                  audioPath = picked.path;
                                  audioId = picked.id;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.library_music),
                            label: const Text('Saved audio'),
                            onPressed: () async {
                              final saved = await _pickSavedAudio(context);
                              if (saved != null) {
                                if (!context.mounted) return;
                                setDialogState(() {
                                  audioPath = saved.path;
                                  audioId = saved.tag;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.mic),
                            label: const Text('Record voice'),
                            onPressed: () async {
                              debugPrint('ReminderFlow: record voice tapped');
                              final recorded = await _recordVoiceMessage(context);
                              if (recorded != null) {
                                if (!context.mounted) return;
                                setDialogState(() {
                                  audioPath = recorded.path;
                                  audioId = recorded.tag;
                                });
                                unawaited(_addAudioEntry(
                                  path: recorded.path,
                                  tag: recorded.tag,
                                ));
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Pick file'),
                            onPressed: () async {
                              debugPrint('ReminderFlow: pick file tapped');
                              final picked = await AudioPicker.pickAudioFile();
                              if (picked != null) {
                                if (!context.mounted) return;
                                setDialogState(() {
                                  audioPath = picked.path;
                                  audioId = picked.id;
                                });
                              }
                            },
                          ),
                          if (audioPath != null) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                              onPressed: () => setDialogState(() {
                                audioPath = null;
                                audioId = null;
                              }),
                            ),
                          ],
                        ],
                      );
                    }
                    // On wider screens, use Wrap for horizontal layout
                    return Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.alarm),
                          label: const Text('System tone'),
                          onPressed: () async {
                            debugPrint('ReminderFlow: system tone tapped');
                            final picked = await _pickSystemTone(context);
                            if (picked != null) {
                              if (!context.mounted) return;
                              setDialogState(() {
                                audioPath = picked.path;
                                audioId = picked.id;
                              });
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.library_music),
                          label: const Text('Saved audio'),
                          onPressed: () async {
                            final saved = await _pickSavedAudio(context);
                            if (saved != null) {
                              if (!context.mounted) return;
                              setDialogState(() {
                                audioPath = saved.path;
                                audioId = saved.tag;
                              });
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.mic),
                          label: const Text('Record voice'),
                          onPressed: () async {
                            debugPrint('ReminderFlow: record voice tapped');
                            final recorded = await _recordVoiceMessage(context);
                            if (recorded != null) {
                              if (!context.mounted) return;
                              setDialogState(() {
                                audioPath = recorded.path;
                                audioId = recorded.tag;
                              });
                              unawaited(_addAudioEntry(
                                path: recorded.path,
                                tag: recorded.tag,
                              ));
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Pick file'),
                          onPressed: () async {
                            debugPrint('ReminderFlow: pick file tapped');
                            final picked = await AudioPicker.pickAudioFile();
                            if (picked != null) {
                              if (!context.mounted) return;
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
                    );
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
                  debugPrint('ReminderFlow: save rejected by validation');
                  return;
                }
                debugPrint('ReminderFlow: save tapped, closing dialog');
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    debugPrint('ReminderFlow: dialog returned saved=$saved');
    if (saved != true || categoryId == null) {
      debugPrint('ReminderFlow: reminder was not saved');
      return;
    }

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

    // Schedule first so an unscheduled reminder is never persisted to the UI.
    try {
      debugPrint(
        'ReminderFlow: scheduling id=${updatedReminder.id}',
      );
      await AlarmScheduler.scheduleReminder(
        id: updatedReminder.id,
        dateTime: updatedReminder.nextTriggerTime,
        audioPath: updatedReminder.audioPath,
      );
      debugPrint('ReminderFlow: scheduling succeeded id=${updatedReminder.id}');
    } catch (error) {
      debugPrint('ReminderFlow: scheduling failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule alarm: $error')),
      );
      return;
    }

    setState(() {
      if (editing == null) {
        _reminders.add(updatedReminder);
      } else {
        final index = _reminders.indexWhere((reminder) => reminder.id == editing.id);
        if (index != -1) _reminders[index] = updatedReminder;
        _alreadyNotifiedIds.remove(editing.id);
      }
    });
    await _saveReminders();
  }

  */

  Future<void> _showAudioDialogMessage(
    BuildContext dialogContext, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<({String path, String id})?> _pickSystemTone(
    BuildContext dialogContext,
  ) async {
    List<FileSystemEntity> tones;
    try {
      tones = await SystemAlarmLoader.loadSystemAlarmTones();
    } catch (error) {
      if (dialogContext.mounted) {
        await _showAudioDialogMessage(
          dialogContext,
          title: 'System tones unavailable',
          message: 'Could not load alarm tones: $error',
        );
      }
      return null;
    }
    if (!dialogContext.mounted) return null;
    if (tones.isEmpty) {
      await _showAudioDialogMessage(
        dialogContext,
        title: 'System tones unavailable',
        message:
            'This Android device does not expose system alarm tones to apps. '
            'Use Record voice or Pick file instead.',
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

  Future<({String path, String tag})?> _pickSavedAudio(
    BuildContext dialogContext,
  ) async {
    final available = _audioLibrary
        .where((entry) => File(entry.path).existsSync())
        .toList();
    if (available.isEmpty) {
      await _showAudioDialogMessage(
        dialogContext,
        title: 'No saved audio',
        message: 'Record a voice message first, then save it with a tag.',
      );
      return null;
    }

    return showDialog<({String path, String tag})>(
      context: dialogContext,
      builder: (context) => SimpleDialog(
        title: const Text('Choose saved audio'),
        children: [
          for (final entry in available)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(
                (path: entry.path, tag: entry.tag),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.tag),
                subtitle: Text(p.basename(entry.path)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAudioLibrary() async {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Saved voice messages'),
          content: SizedBox(
            width: double.maxFinite,
            child: _audioLibrary.isEmpty
                ? const Text('No saved voice messages yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _audioLibrary.length,
                    itemBuilder: (context, index) {
                      final entry = _audioLibrary[index];
                      final usedBy = _reminders
                          .where((reminder) => reminder.audioPath == entry.path)
                          .map((reminder) => reminder.title)
                          .toList();
                      return ListTile(
                        title: Text(entry.tag),
                        subtitle: Text(
                          usedBy.isEmpty
                              ? p.basename(entry.path)
                              : 'Used by: ${usedBy.join(', ')}',
                        ),
                        trailing: IconButton(
                          tooltip: usedBy.isEmpty
                              ? 'Delete recording'
                              : 'Used by a reminder',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: usedBy.isNotEmpty
                              ? null
                              : () async {
                                  final file = File(entry.path);
                                  if (await file.exists()) await file.delete();
                                  setState(() => _audioLibrary.removeAt(index));
                                  setDialogState(() {});
                                  await _saveAudioLibrary();
                                },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
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
      await _saveReminders();
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
        title: Text(_appVersion.isEmpty ? 'Reminders' : 'Reminders  $_appVersion'),
        actions: [
          IconButton(
            tooltip: 'Saved voice messages',
            icon: const Icon(Icons.library_music_outlined),
            onPressed: _showAudioLibrary,
          ),
          IconButton(
            tooltip: 'Recording privacy',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Recording privacy'),
                  content: const Text(
                    'Your recorded reminder messages are stored privately '
                    'inside this app. Use Saved voice messages to reuse or '
                    'delete them.',
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
            if (_isLoadingReminders)
              const Center(child: CircularProgressIndicator())
            else if (visibleReminders.isEmpty)
              EmptyStateView(
                icon: Icons.event_busy,
                title: _reminders.isEmpty
                    ? 'No reminders yet'
                    : 'No reminders match this filter',
                message: _reminders.isEmpty
                    ? 'Add a reminder to get started.'
                    : 'Change the category or time window, or add a new reminder.',
                actionLabel: _reminders.isEmpty ? 'Add reminder' : 'Reset filters',
                onAction: () {
                  if (_reminders.isEmpty) {
                    _addReminder();
                  } else {
                    setState(() {
                      _selectedDays = 14;
                      _selectedCategoryId = null;
                    });
                  }
                },
              )
            else
              ...visibleReminders.map(
                (reminder) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ReminderListTile(
                        category: reminder.categoryName,
                        importance: reminder.importance,
                        title: reminder.title,
                        nextTriggerTime: reminder.nextTriggerTime,
                        finalTime: reminder.finalTime,
                        snoozeLabel: reminder.snoozeLabel,
                        isDue: !reminder.nextTriggerTime.isAfter(now),
                        onTap: () => _showReminderDetails(reminder),
                      ),
                      if (reminder.audioId != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              const Icon(Icons.mic_none, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Audio: ${reminder.audioId}',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderDraft {
  final String title;
  final String? categoryId;
  final DateTime nextTriggerTime;
  final String? snoozeLabel;
  final String? audioPath;
  final String? audioId;

  const _ReminderDraft({
    required this.title,
    required this.categoryId,
    required this.nextTriggerTime,
    required this.snoozeLabel,
    required this.audioPath,
    required this.audioId,
  });
}

class _ReminderEditorDialog extends StatefulWidget {
  final _Reminder? editing;
  final List<CategoryOption> categories;
  final Future<void> Function() onAddCategory;
  final Future<({String path, String id})?> Function(BuildContext)
      onPickSystemTone;
  final Future<({String path, String tag})?> Function(BuildContext)
      onPickSavedAudio;
  final Future<PickedAudio?> Function() onPickFile;
  final Future<void> Function(String path, String tag) onSaveAudio;

  const _ReminderEditorDialog({
    required this.editing,
    required this.categories,
    required this.onAddCategory,
    required this.onPickSystemTone,
    required this.onPickSavedAudio,
    required this.onPickFile,
    required this.onSaveAudio,
  });

  @override
  State<_ReminderEditorDialog> createState() => _ReminderEditorDialogState();
}

class _ReminderEditorDialogState extends State<_ReminderEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _snoozeController;
  String? _categoryId;
  late DateTime _pickedDate;
  late TimeOfDay _pickedTime;
  String? _audioPath;
  String? _audioId;
  bool _busy = false;
  VoiceRecorder? _recorder;
  final TextEditingController _recordingTagController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    final initial = editing?.nextTriggerTime ??
        DateTime.now().add(const Duration(minutes: 1));
    _titleController = TextEditingController(text: editing?.title);
    _snoozeController = TextEditingController(text: editing?.snoozeLabel);
    _categoryId = editing?.categoryId ??
        (widget.categories.isEmpty ? null : widget.categories.first.id);
    _pickedDate = DateTime(initial.year, initial.month, initial.day);
    _pickedTime = TimeOfDay.fromDateTime(initial);
    _audioPath = editing?.audioPath;
    _audioId = editing?.audioId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _snoozeController.dispose();
    _recordingTagController.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_busy) return;
    setState(() => _busy = true);
    final recorder = VoiceRecorder();
    try {
      final started = await recorder.startRecording();
      if (!mounted || started == null) {
        await recorder.dispose();
        return;
      }
      _recorder = recorder;
      setState(() => _busy = false);
    } catch (error) {
      await recorder.dispose();
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $error')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final recorder = _recorder;
    if (recorder == null || _recordingTagController.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final path = await recorder.stopRecording();
    await recorder.dispose();
    _recorder = null;
    if (!mounted || path == null) return;
    final tag = _recordingTagController.text.trim();
    setState(() {
      _audioPath = path;
      _audioId = tag;
      _busy = false;
      _recordingTagController.clear();
    });
    unawaited(widget.onSaveAudio(path, tag));
  }

  Future<void> _selectSystemTone() async {
    final selected = await widget.onPickSystemTone(context);
    if (!mounted || selected == null) return;
    setState(() {
      _audioPath = selected.path;
      _audioId = selected.id;
    });
  }

  Future<void> _selectSavedAudio() async {
    final selected = await widget.onPickSavedAudio(context);
    if (!mounted || selected == null) return;
    setState(() {
      _audioPath = selected.path;
      _audioId = selected.tag;
    });
  }

  Future<void> _selectFile() async {
    final selected = await widget.onPickFile();
    if (!mounted || selected == null) return;
    setState(() {
      _audioPath = selected.path;
      _audioId = selected.id;
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty || _categoryId == null || _busy) return;
    Navigator.of(context).pop(_ReminderDraft(
      title: title,
      categoryId: _categoryId,
      nextTriggerTime: DateTime(
        _pickedDate.year,
        _pickedDate.month,
        _pickedDate.day,
        _pickedTime.hour,
        _pickedTime.minute,
      ),
      snoozeLabel: _snoozeController.text.trim().isEmpty
          ? null
          : _snoozeController.text.trim(),
      audioPath: _audioPath,
      audioId: _audioId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final audioButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.alarm),
          label: const Text('System tone'),
          onPressed: _busy ? null : _selectSystemTone,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.library_music),
          label: const Text('Saved audio'),
          onPressed: _busy ? null : _selectSavedAudio,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.mic),
          label: const Text('Record voice'),
          onPressed: _busy || _recorder != null ? null : _startRecording,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('Pick file'),
          onPressed: _busy ? null : _selectFile,
        ),
        if (_audioPath != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
            onPressed: _busy || _recorder != null
                ? null
                : () => setState(() {
                      _audioPath = null;
                      _audioId = null;
                    }),
          ),
      ],
    );

    return AlertDialog(
      title: Text(widget.editing == null ? 'Add reminder' : 'Edit reminder'),
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            CategorySelector(
              categories: widget.categories,
              selectedId: _categoryId,
              onSelected: (value) => setState(() => _categoryId = value),
              onAddNewCategory: widget.onAddCategory,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${formatShortDate(_pickedDate)}'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _pickedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (mounted && selected != null) {
                  setState(() => _pickedDate = selected);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Time: ${_pickedTime.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: _pickedTime,
                );
                if (mounted && selected != null) {
                  setState(() => _pickedTime = selected);
                }
              },
            ),
            const SizedBox(height: 12),
            Text('Alarm sound', style: Theme.of(context).textTheme.labelLarge),
            Text(_audioId ?? 'Default tone',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            audioButtons,
            if (_recorder != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _recordingTagController,
                decoration: const InputDecoration(
                  labelText: 'Voice message name',
                  hintText: 'e.g. Dentist appointment',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _stopRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Stop and save recording'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _snoozeController,
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
            onPressed: _busy || _recorder != null
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
