import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_services/models/record_model.dart';
import 'package:intl/intl.dart';

/// 거래 기록 개별 항목 카드 위젯
class RecordItem extends StatelessWidget {
  final RecordModel record;
  final VoidCallback onTap;
  final VoidCallback onEditTap;

  const RecordItem({
    super.key,
    required this.record,
    required this.onTap,
    required this.onEditTap,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy.MM.dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatUpdatedDate(String? updatedAt) {
    if (updatedAt == null) return '';
    try {
      final date = DateTime.parse(updatedAt);
      return DateFormat('yyyy.MM.dd').format(date);
    } catch (e) {
      return '';
    }
  }

  String _getStatusText() {
    final sideText = record.side == 'BUY' ? '매수' : '매도';
    final statusText = record.status == 'FILLED' ? '완료' : '대기';
    final totalText = record.totalAmount != null 
        ? '총액 \$${(double.tryParse(record.totalAmount.toString()) ?? 0.0).toStringAsFixed(2)}' 
        : '';
    return '$sideText·$statusText${totalText.isNotEmpty ? ' | $totalText' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final isModified = record.updatedAt != null && 
        record.updatedAt != record.createdAt;
    final dateText = isModified
        ? '${_formatDate(record.createdAt)} (${_formatUpdatedDate(record.updatedAt)} 수정)'
        : _formatDate(record.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.h(12)),
        padding: EdgeInsets.all(context.w(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorderRadius.medium,
          boxShadow: AppShadows.main,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 표시 점
            Container(
              width: context.w(8),
              height: context.h(8),
              margin: EdgeInsets.only(
                top: context.h(6),
                right: context.w(8),
              ),
              decoration: BoxDecoration(
                color: isModified 
                    ? AppColors.chartRed 
                    : AppColors.chartBlue,
                shape: BoxShape.circle,
              ),
            ),
            // 감정 아이콘
            SvgPicture.asset(
              record.tradeEmotion.assetPath,
              width: context.w(50),
              height: context.h(38),
            ),
            SizedBox(width: context.w(12)),
            // 내용 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜
                  Text(
                    dateText,
                    style: AppFonts.c1.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  // 종목명
                  Text(
                    '${record.symbol}',
                    style: AppFonts.b1Semibold.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  // 상태
                  Text(
                    _getStatusText(),
                    style: AppFonts.c1.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  // 내용이 있으면 표시
                  if (record.content.isNotEmpty) ...[
                    SizedBox(height: context.h(8)),
                    Text(
                      record.content,
                      style: AppFonts.b2Regular.copyWith(
                        color: AppColors.gray900,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // 수정 아이콘
            GestureDetector(
              onTap: onEditTap,
              child: Padding(
                padding: EdgeInsets.all(context.w(8)),
                child: SvgPicture.asset(
                  'assets/icons/record/record-gray200.svg',
                  width: context.w(20),
                  height: context.h(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

