import 'package:flutter/material.dart';

/// 自定义下拉列表组件，支持自定义字体大小和间距
class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemBuilder;
  final void Function(T?) onChanged;
  final String? hintText;
  final double fontSize;
  final double itemVerticalPadding;
  final double itemHorizontalPadding;
  final double inputVerticalPadding;
  final double inputHorizontalPadding;
  final double? menuMaxHeight;
  final Color? dropdownColor;
  final FontWeight? fontWeight;
  final Color? textColor;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.hintText,
    this.fontSize = 14.0,
    this.itemVerticalPadding = 8.0,
    this.itemHorizontalPadding = 4.0,
    this.inputVerticalPadding = 8.0,
    this.inputHorizontalPadding = 8.0,
    this.menuMaxHeight = 200.0,
    this.dropdownColor,
    this.fontWeight = FontWeight.w500,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hintText ?? '请选择',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: inputHorizontalPadding,
          vertical: inputVerticalPadding,
        ),
        isDense: true,
      ),
      style: TextStyle(
        fontSize: fontSize,
        color: textColor ?? Colors.black87,
        fontWeight: fontWeight,
      ),
      dropdownColor: dropdownColor ?? Colors.white,
      menuMaxHeight: menuMaxHeight,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: itemVerticalPadding,
              horizontal: itemHorizontalPadding,
            ),
            child: Text(
              itemBuilder(item),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textColor ?? Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

/// 预设样式的下拉列表组件
class CompactDropdown<T> extends CustomDropdown<T> {
  const CompactDropdown({
    super.key,
    required super.value,
    required super.items,
    required super.itemBuilder,
    required super.onChanged,
    super.hintText,
  }) : super(
         fontSize: 12.0,
         itemVerticalPadding: 6.0,
         itemHorizontalPadding: 4.0,
         inputVerticalPadding: 6.0,
         inputHorizontalPadding: 6.0,
         menuMaxHeight: 150.0,
         fontWeight: FontWeight.w400,
       );
}

/// 大号样式的下拉列表组件
class LargeDropdown<T> extends CustomDropdown<T> {
  const LargeDropdown({
    super.key,
    required super.value,
    required super.items,
    required super.itemBuilder,
    required super.onChanged,
    super.hintText,
  }) : super(
         fontSize: 16.0,
         itemVerticalPadding: 12.0,
         itemHorizontalPadding: 8.0,
         inputVerticalPadding: 12.0,
         inputHorizontalPadding: 12.0,
         menuMaxHeight: 250.0,
         fontWeight: FontWeight.w600,
       );
}
