import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const FilterButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height, // 고정 높이 제거, 필요 시 외부에서 전달
        constraints: const BoxConstraints(minHeight: 28), // 최소 28px 보장
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration( // 활성화, 비활성화별로 버튼 색 차이
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20), 
        ),
        child: Center(
          child: Text(
            label,
            style: AppFonts.b2Regular.copyWith(
              color: isSelected ? Colors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

class FilterButtonGroup extends StatefulWidget {
  final List<String> labels;
  final List<String> values;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? groupPadding;
  final bool scrollable;

  FilterButtonGroup({
    super.key,
    required this.labels,
    required this.values,
    required this.initialValue,
    required this.onChanged,
    this.height,
    this.padding,
    this.groupPadding,
    this.scrollable = true,
  }) : assert(labels.length == values.length, 'labels and values must have the same length'),
       assert(values.contains(initialValue), 'initialValue must be one of values');

  @override
  State<FilterButtonGroup> createState() => _FilterButtonGroupState();
}

class _FilterButtonGroupState extends State<FilterButtonGroup> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(FilterButtonGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _selectedValue = widget.initialValue;
    }
  }

  void _handleTap(String value) {
    if (_selectedValue != value) {
      setState(() {
        _selectedValue = value;
      });
      widget.onChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.groupPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: widget.scrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (int i = 0; i < widget.labels.length; i++) ...[
                    FilterButton(
                      label: widget.labels[i],
                      isSelected: _selectedValue == widget.values[i],
                      onTap: () => _handleTap(widget.values[i]),
                      height: widget.height,
                      padding: widget.padding,
                    ),
                    if (i < widget.labels.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (int i = 0; i < widget.labels.length; i++) ...[
                  FilterButton(
                    label: widget.labels[i],
                    isSelected: _selectedValue == widget.values[i],
                    onTap: () => _handleTap(widget.values[i]),
                    height: widget.height,
                    padding: widget.padding,
                  ),
                  if (i < widget.labels.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
    );
  }
}
