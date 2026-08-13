# reusable_reminder_kit

Standalone, reminder-agnostic pieces pulled out of the Offline Smart Reminder
app's design (see the requirements doc, §12.5 "What can be built reusable").
Nothing in here knows what a "reminder" is — it just needs data and a config
— so it can be used in this app now, and copied whole into a future app
later without rewriting anything.

**Fully offline.** No third-party packages — only Flutter's own SDK. `flutter
pub get` needs no network access beyond fetching the Flutter/Dart SDK itself,
which you already have once Flutter is installed.

## What's in here

| File | Type | What it does |
|---|---|---|
| `lib/core/result.dart` | pure Dart | `Result<T>` type so use-cases return Ok/Fail instead of throwing |
| `lib/core/date_time_helpers.dart` | pure Dart | Leap-year/month-end-safe date math + dependency-free date formatting |
| `lib/core/importance.dart` | Flutter | Shared `Importance` enum (high/medium/low) + colour/label mapping |
| `lib/recurrence/recurrence_engine.dart` | pure Dart | Given a rule + last trigger date, returns the next trigger date |
| `lib/widgets/importance_color_tag.dart` | Flutter widget | Red/blue/green colour-coded pill |
| `lib/widgets/reminder_list_tile.dart` | Flutter widget | "[Category • Importance] Title" two-line row |
| `lib/widgets/category_selector.dart` | Flutter widget | Dropdown with a built-in "+ Add new category" option |
| `lib/widgets/confirm_action_dialog.dart` | Flutter widget | One confirm/cancel dialog used for every delete action |
| `lib/widgets/empty_state_view.dart` | Flutter widget | Icon + message + optional action, for empty lists |
| `lib/widgets/filter_chips_row.dart` | Flutter widget | Generic single-select chip row (used for the 1wk/2wk/3wk/1mo filter) |

`lib/reusable_reminder_kit.dart` is a barrel file — import that one file to
get everything.

## Using it in the Offline Smart Reminder app (now)

1. Copy this whole folder into your project, e.g. as a local package at
   `packages/reusable_reminder_kit/`.
2. In the main app's `pubspec.yaml`, add:
   ```yaml
   dependencies:
     reusable_reminder_kit:
       path: packages/reusable_reminder_kit
   ```
3. Import what you need:
   ```dart
   import 'package:reusable_reminder_kit/reusable_reminder_kit.dart';
   ```
4. This matches the folder structure already proposed in the requirements
   doc §12.2 — `core`, `recurrence`, and the shared widgets are exactly the
   pieces marked reusable in §12.5.

## Using it in a future app (later)

Because there are zero reminder-specific assumptions baked in:

- Drop the whole `reusable_reminder_kit/` folder into a new Flutter project.
- `recurrence_engine.dart` works for any "when does this repeat" feature —
  subscriptions, medication schedules, habit streaks.
- The widgets work for any tagged/dated/categorised list, not just reminders.
- `Result<T>` and the date helpers are generically useful in any Dart project,
  Flutter or not (`date_time_helpers.dart` and `result.dart` have zero
  Flutter imports).

## Running the tests

```
flutter test test/recurrence_engine_test.dart
```

No packages beyond `flutter_test` (bundled with the Flutter SDK) are
required, so this runs fully offline. Tests cover:

- Leap-year Feb 29 handling for yearly recurrence
- End-of-month clamping for monthly recurrence (Jan 31 → Feb 28/29)
- Fixed-interval-day recurrence
- The `notAfter` upper bound stopping a recurring series
- The dependency-free date formatters

> Note: these tests were written and manually traced through by hand: this
> environment doesn't have the Dart/Flutter SDK installed to execute them.
> Run `flutter test` yourself after copying the kit in — if anything doesn't
> match, it's worth double-checking before wiring it into the app.
