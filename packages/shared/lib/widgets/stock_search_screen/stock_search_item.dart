import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/stock_model.dart';

/// 종목 검색 결과 아이템 컴포넌트
class StockSearchItem extends StatelessWidget {
  final StockModel stock;
  final String searchQuery;

  const StockSearchItem({
    super.key,
    required this.stock,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final encodedSymbol = Uri.encodeComponent(stock.symbol);
        final encodedName = Uri.encodeComponent(stock.name);
        final encodedAssetClass = Uri.encodeComponent(stock.assetClass ?? 'us_equity');
        context.push('/stock-detail/$encodedSymbol?name=$encodedName&assetClass=$encodedAssetClass');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            // 로고
            Container(
              width: 42,
              height: 42,
              decoration: const ShapeDecoration(
                shape: OvalBorder(),
              ),
              child: ClipOval(
                child: stock.logoUrl != null && stock.logoUrl!.isNotEmpty
                    ? Image.network(
                        stock.logoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return SvgPicture.asset(
                            'assets/icons/stock_search_screen/company-logo-basic.svg',
                            width: 42,
                            height: 42,
                          );
                        },
                      )
                    : SvgPicture.asset(
                        'assets/icons/stock_search_screen/company-logo-basic.svg',
                        width: 42,
                        height: 42,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // 이름과 심볼
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHighlightedText(
                    text: stock.name,
                    searchQuery: searchQuery,
                    style: AppFonts.b1Regular,
                    defaultColor: AppColors.gray900,
                    highlightColor: AppColors.primaryDark,
                  ),
                  const SizedBox(height: 2),
                  _buildHighlightedText(
                    text: stock.symbol,
                    searchQuery: searchQuery,
                    style: AppFonts.b2Regular,
                    defaultColor: AppColors.gray600,
                    highlightColor: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 검색어와 일치하는 부분만 하이라이트하는 텍스트 위젯
  Widget _buildHighlightedText({
    required String text,
    required String searchQuery,
    required TextStyle style,
    required Color defaultColor,
    required Color highlightColor,
  }) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: style.copyWith(color: defaultColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final queryLower = searchQuery.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(queryLower)) {
      return Text(
        text,
        style: style.copyWith(color: defaultColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) break;

      // 검색어 이전 텍스트
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: style.copyWith(color: defaultColor),
          ),
        );
      }

      // 검색어 (하이라이트)
      spans.add(
        TextSpan(
          text: text.substring(index, index + searchQuery.length),
          style: style.copyWith(color: highlightColor),
        ),
      );

      start = index + searchQuery.length;
    }

    // 남은 텍스트
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: style.copyWith(color: defaultColor),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

