import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../core/models/investment.dart';

/// 주식 카드 위젯
class StockCardWidget extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;

  const StockCardWidget({
    super.key,
    required this.stock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = stock.changeAmount >= 0;
    final changeColor = isPositive ? AppColors.profit : AppColors.loss;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 주식 심볼과 이름
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.symbol,
                          style: AppTypography.headingSmall,
                        ),
                        Text(
                          stock.name,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    changeIcon,
                    color: changeColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // 현재 가격
              Text(
                '₩${stock.currentPrice.toStringAsFixed(0)}',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              
              // 변동 정보
              Row(
                children: [
                  Text(
                    '${isPositive ? '+' : ''}₩${stock.changeAmount.toStringAsFixed(0)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '(${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%)',
                    style: AppTypography.bodySmall.copyWith(
                      color: changeColor,
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

/// 포트폴리오 카드 위젯
class PortfolioCardWidget extends StatelessWidget {
  final PortfolioItem item;
  final VoidCallback? onTap;

  const PortfolioCardWidget({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = item.gainLoss >= 0;
    final gainLossColor = isPositive ? AppColors.profit : AppColors.loss;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 주식 정보
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.stockSymbol,
                          style: AppTypography.headingSmall,
                        ),
                        Text(
                          item.stockName,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.quantity}주',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // 총 가치
              Text(
                '₩${item.totalValue.toStringAsFixed(0)}',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              
              // 손익 정보
              Row(
                children: [
                  Text(
                    '${isPositive ? '+' : ''}₩${item.gainLoss.toStringAsFixed(0)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: gainLossColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '(${isPositive ? '+' : ''}${item.gainLossPercent.toStringAsFixed(2)}%)',
                    style: AppTypography.bodySmall.copyWith(
                      color: gainLossColor,
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

/// 뉴스 카드 위젯
class NewsCardWidget extends StatelessWidget {
  final String title;
  final String? summary;
  final String? source;
  final DateTime? publishedAt;
  final VoidCallback? onTap;

  const NewsCardWidget({
    super.key,
    required this.title,
    this.summary,
    this.source,
    this.publishedAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // 요약
              if (summary != null) ...[
                Text(
                  summary!,
                  style: AppTypography.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              
              // 출처와 날짜
              Row(
                children: [
                  if (source != null) ...[
                    Text(
                      source!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (publishedAt != null)
                    Text(
                      _formatDate(publishedAt!),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
