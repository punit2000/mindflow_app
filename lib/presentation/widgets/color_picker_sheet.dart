import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ColorPickerRow extends StatelessWidget {
  final int selectedColorIndex;
  final ValueChanged<int> onColorSelected;

  const ColorPickerRow({
    super.key,
    required this.selectedColorIndex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < AppColors.noteColorPalettes.length; i++) ...[
            GestureDetector(
              onTap: () => onColorSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.noteColorPalettes[i].getColor(isDark),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColorIndex == i
                        ? AppColors.noteColorPalettes[i].accentColor
                        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                    width: selectedColorIndex == i ? 2.5 : 1,
                  ),
                  boxShadow: [
                    if (selectedColorIndex == i)
                      BoxShadow(
                        color: AppColors.noteColorPalettes[i].accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: selectedColorIndex == i
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.noteColorPalettes[i].accentColor,
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
