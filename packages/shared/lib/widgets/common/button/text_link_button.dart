import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';

/// 텍스트 링크 스타일 버튼
class TextLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final IconData? icon;
  final Widget? leadingIcon;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool underline;

  const TextLinkButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.icon,
    this.leadingIcon,
    this.fontSize,
    this.fontWeight,
    this.underline = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? AppColors.primary;
    final bool isDisabled = onPressed == null;
    
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: effectiveTextColor,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        disabledForegroundColor: AppColors.gray400,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon!,
            const SizedBox(width: AppSpacing.xs),
          ],
          if (icon != null) ...[
            Icon(icon, size: fontSize ?? 14),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: AppFonts.b2Regular.copyWith(
              fontSize: fontSize ?? 14,
              fontWeight: fontWeight ?? FontWeight.w500,
              color: isDisabled ? AppColors.gray400 : effectiveTextColor,
              decoration: underline ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}

