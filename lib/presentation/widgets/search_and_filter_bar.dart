import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SearchAndFilterBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final List<String> filterOptions;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterSelected;

  const SearchAndFilterBar({
    super.key,
    required this.hintText,
    required this.onSearchChanged,
    this.filterOptions = const [],
    this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search TextField
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: isDark ? AppColors.darkInput : AppColors.lightInput,
            ),
          ),

          // Horizontal Filter Chips
          if (filterOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedFilter == null,
                    onSelected: (_) => onFilterSelected(null),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selectedFilter == null
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      fontWeight: selectedFilter == null ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  for (final option in filterOptions) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('#$option'),
                      selected: selectedFilter == option,
                      onSelected: (selected) {
                        onFilterSelected(selected ? option : null);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selectedFilter == option
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        fontWeight: selectedFilter == option ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
