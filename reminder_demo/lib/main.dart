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

class _DemoReminder {
  final String categoryId;
  final String categoryName;
  final Importance importance;
  final String title;
  final DateTime nextTriggerTime;
  final DateTime? finalTime;
  final String? snoozeLabel;

  const _DemoReminder({
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
  static final List<CategoryOption> _categories = [
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

  static final List<_DemoReminder> _demoReminders = [
    _DemoReminder(
      categoryId: 'work',
      categoryName: 'Work',
      importance: Importance.high,
      title: 'Client follow-up',
      nextTriggerTime: DateTime(2026, 8, 17, 9, 0),
      finalTime: DateTime(2026, 8, 31, 9, 0),
      snoozeLabel: '10 min',
    ),
    _DemoReminder(
      categoryId: 'health',
      categoryName: 'Health',
      importance: Importance.medium,
      title: 'Take medicine',
      nextTriggerTime: DateTime(2026, 8, 14, 8, 30),
      snoozeLabel: '5 min',
    ),
    _DemoReminder(
      categoryId: 'home',
      categoryName: 'Home',
      importance: Importance.low,
      title: 'Water the plants',
      nextTriggerTime: DateTime(2026, 8, 20, 18, 0),
    ),
  ];

  int _selectedDays = 14;
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final windowEnd = DateTime.now().add(Duration(days: _selectedDays));
    final visibleReminders = _demoReminders.where((reminder) {
      if (_selectedCategoryId != null &&
          reminder.categoryId != _selectedCategoryId) {
        return false;
      }
      return !reminder.nextTriggerTime.isAfter(windowEnd);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Demo'),
        actions: [
          IconButton(
            tooltip: 'Setup help',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This app proves the reusable reminder kit runs in a host app.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Reusable reminder kit demo',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Shared widgets and recurrence logic running inside a real Flutter host app.',
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
              onAddNewCategory: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Add-category flow would open here in the full app.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            if (visibleReminders.isEmpty)
              EmptyStateView(
                icon: Icons.event_busy,
                title: 'No reminders match this filter',
                message:
                    'Change the category or time window to see the demo items.',
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
