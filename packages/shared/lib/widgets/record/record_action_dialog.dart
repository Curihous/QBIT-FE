import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

/// 거래 기록 수정/삭제 선택 다이얼로그
class RecordActionDialog extends StatelessWidget {
  const RecordActionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: context.w(320),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(20),
          vertical: context.h(20),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 수정 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pop('edit'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(12),
                ),
                minimumSize: Size(double.infinity, context.h(48)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '수정',
                style: AppFonts.b2Semibold.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            SizedBox(height: context.h(8)),
            // 삭제 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(12),
                ),
                minimumSize: Size(double.infinity, context.h(48)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '삭제',
                style: AppFonts.b2Semibold.copyWith(
                  color: AppColors.chartRed,
                ),
              ),
            ),
            SizedBox(height: context.h(8)),
            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(12),
                ),
                minimumSize: Size(double.infinity, context.h(48)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '취소',
                style: AppFonts.b2Semibold.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

