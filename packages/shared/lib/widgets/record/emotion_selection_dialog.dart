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
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.large,
      ),
      child: Container(
        padding: EdgeInsets.all(context.w(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '매매 감정 선택',
                  style: AppFonts.t2Bold,
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '취소',
                    style: AppFonts.btn2.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(20)),
            // 감정 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: emotions.length,
              itemBuilder: (context, index) {
                final emotion = emotions[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(emotion),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: AppBorderRadius.medium,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        emotion.assetPath,
                        width: context.w(50),
                        height: context.h(38),
                      ),
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

