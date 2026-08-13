import 'package:flutter/material.dart';

/// A single filter option: what to show ([label]) and the value it
/// represents ([value]), e.g. "Next 1 week" -> Duration(days: 7).
class FilterOption<T> {
  final String label;
  final T value;
  const FilterOption(this.label, this.value);
}

/// Horizontal scrollable row of choice chips — used for the Home/See All
/// "next 1 week / 2 weeks / 3 weeks / 1 month" filter (\u00a77.1), but generic
/// over T so it works for any single-select filter set.
///
/// Reusable beyond this app: any time-range or category filter row.
class FilterChipsRow<T> extends StatelessWidget {
  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selected;
          return ChoiceChip(
            label: Text(option.label),
            selected: isSelected,
            onSelected: (_) => onSelected(option.value),
          );
        },
      ),
    );
  }
}
