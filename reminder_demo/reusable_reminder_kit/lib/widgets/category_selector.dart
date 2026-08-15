import 'package:flutter/material.dart';
import '../core/importance.dart';
import 'importance_color_tag.dart';

/// A single selectable category (name + its importance-derived colour).
class CategoryOption {
  final String id;
  final String name;
  final Importance importance;

  const CategoryOption({
    required this.id,
    required this.name,
    required this.importance,
  });
}

/// Dropdown-style category picker that always ends with an
/// "+ Add new category" entry, so a user is never blocked mid-creation-flow
/// if the category they need doesn't exist yet (\u00a73.3 / \u00a77.5 confirmed
/// requirement).
///
/// Reusable beyond this app: any categorised-content app (expenses, notes,
/// recipes) can reuse this by swapping in its own CategoryOption list.
class CategorySelector extends StatelessWidget {
  final List<CategoryOption> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddNewCategory;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onAddNewCategory,
  });

  static const _addNewValue = '__add_new__';

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(labelText: 'Category'),
      items: [
        for (final c in categories)
          DropdownMenuItem(
            value: c.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ImportanceColorTag(importance: c.importance),
                const SizedBox(width: 8),
                Text(c.name),
              ],
            ),
          ),
        const DropdownMenuItem(
          value: _addNewValue,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 6),
              Text('Add new category'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        if (value == _addNewValue) {
          onAddNewCategory();
        } else {
          onSelected(value);
        }
      },
    );
  }
}
