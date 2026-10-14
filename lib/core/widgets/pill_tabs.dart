import 'package:customer_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// One segment of a [PillTabs].
class PillTabItem<T> {
  const PillTabItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Single-select segmented tabs: a light grey track with the selected segment
/// as a brand-red gradient pill (e.g. the login screen's "เบอร์โทร / อีเมล").
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<PillTabItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: _PillTab(
                  label: item.label,
                  active: item.value == selected,
                  onTap: () => onChanged(item.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            height: 44,
            decoration: active
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.foundationRed800, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  )
                : const BoxDecoration(color: Colors.transparent),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF6A6E83),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
