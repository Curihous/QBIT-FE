import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_services/models/portfolio_position_model.dart';
import 'package:qbit_shared/layout/horizontal_inset.dart';

class PortfolioPositionsWidget extends StatelessWidget {
  final List<PortfolioPosition> positions;
  final VoidCallback? onViewAll;
  final Function(PortfolioPosition)? onItemTap;

  const PortfolioPositionsWidget({
    super.key,
    required this.positions,
    this.onViewAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) {
      return const SizedBox.shrink();
    }

    // marketValue 기준으로 정렬 (내림차순)
    final sortedPositions = List<PortfolioPosition>.from(positions)
      ..sort((a, b) {
        final aValue = double.tryParse(a.marketValue) ?? 0.0;
        final bValue = double.tryParse(b.marketValue) ?? 0.0;
        return bValue.compareTo(aValue);
      });

    // 상위 3개만 표시
    final topPositions = sortedPositions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        GestureDetector(
          onTap: onViewAll,
          child: Inset.text(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: context.h(9),
              ),
              child: Row(
                children: [
                  Text(
                    '내 종목 보기',
                    style: AppFonts.t2Semibold.copyWith(color: AppColors.gray900),
                  ),
                  SizedBox(width: context.w(4)),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.gray400,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // 포지션 리스트
        ...topPositions.asMap().entries.map((entry) {
          final index = entry.key;
          final position = entry.value;
          return Column(
            children: [
              _buildPositionItem(context, position, isFirst: index == 0),
              // 마지막 아이템이 아니면 여백 추가
              if (index < topPositions.length - 1)
                SizedBox(height: context.h(8)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPositionItem(BuildContext context, PortfolioPosition position, {bool isFirst = false}) {
    final marketValue = double.tryParse(position.marketValue) ?? 0.0;
    final unrealizedPlpc = double.tryParse(position.unrealizedPlpc) ?? 0.0;
    final avgEntryPrice = double.tryParse(position.avgEntryPrice) ?? 0.0;
    final quantity = double.tryParse(position.quantity) ?? 0.0;
    
    // 암호화폐인지 확인 ('/'가 포함되어 있으면 암호화폐 거래 페어)
    final isCrypto = position.symbol.contains('/');
    
    // 수량 포맷팅: 소수점 4자리까지만 표시하고 불필요한 0 제거
    String quantityText;
    if (isCrypto) {
      quantityText = quantity.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      quantityText += '개';
    } else {
      quantityText = '${quantity.toStringAsFixed(0)}주';
    }
    
    // 평균가 포맷팅: 1보다 작으면 소수점 4자리, 아니면 2자리 (불필요한 0 제거)
    String avgPriceText;
    if (avgEntryPrice < 1) {
      avgPriceText = avgEntryPrice.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } else {
      avgPriceText = avgEntryPrice.toStringAsFixed(2);
    }

    // 손익률 포맷팅 (퍼센트로 변환: -0.004972 -> -0.497%)
    final plpcPercent = unrealizedPlpc * 100;
    final plpcText = plpcPercent >= 0 
        ? '+${plpcPercent.toStringAsFixed(2)}%'
        : '${plpcPercent.toStringAsFixed(2)}%';
    
    // 손익률 색상 (양수: 수익 색상, 음수: 손실 색상)
    final plpcColor = unrealizedPlpc >= 0 ? AppColors.chartRed : AppColors.chartBlue;

    return GestureDetector(
      onTap: () => onItemTap?.call(position),
      behavior: HitTestBehavior.opaque,
      child: Inset.block(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: context.w(4), vertical: context.h(12)),
          decoration: BoxDecoration(
            border: Border(
              top: isFirst ? const BorderSide(
                width: 1,
                color: AppColors.gray100,
              ) : BorderSide.none,
              bottom: const BorderSide(
                width: 1,
                color: AppColors.gray100,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 왼쪽: 심볼과 평균가/수량
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.symbol,
                      style: AppFonts.b1Regular.copyWith(
                        color: AppColors.gray900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      '내 평균 $avgPriceText • $quantityText',
                      style: AppFonts.c1.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 오른쪽: 시장가치와 손익률
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$ ${marketValue.toStringAsFixed(2)}',
                    style: AppFonts.b1Regular.copyWith(
                      color: AppColors.gray900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    plpcText,
                    style: AppFonts.c1.copyWith(
                      color: plpcColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

