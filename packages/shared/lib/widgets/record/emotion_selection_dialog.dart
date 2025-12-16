import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_services/models/record_model.dart';

/// 감정 선택 다이얼로그
class EmotionSelectionDialog extends StatelessWidget {
  const EmotionSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final emotions = [
      TradeEmotion.laugh,
      TradeEmotion.love,
      TradeEmotion.cool,
      TradeEmotion.excellent,
      TradeEmotion.sobbing,
      TradeEmotion.slump,
      TradeEmotion.anger,
      TradeEmotion.neutral,
      TradeEmotion.awkward,
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: context.w(340),
        padding: EdgeInsets.only(
          left: context.w(20),
          right: context.w(20),
          top: context.h(20),
          bottom: context.h(16),
        ),
        decoration: BoxDecoration(
          color: AppColors.gray0,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: AppShadows.main,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '매매 감정 선택',
                  style: AppFonts.b2Semibold,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '취소',
                    style: AppFonts.btn3.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(8)),
            // 감정 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: context.w(20),
                mainAxisSpacing: context.h(8),
                childAspectRatio: 1,
              ),
              itemCount: emotions.length,
              itemBuilder: (context, index) {
                final emotion = emotions[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(emotion),
                  child: Center(
                    child: SvgPicture.asset(
                      emotion.assetPath,
                      width: context.w(60),
                      height: context.h(48),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

