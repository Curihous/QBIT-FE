import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';

class StockMarketTab extends StatefulWidget {
  final String symbol;
  final String name;

  const StockMarketTab({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  State<StockMarketTab> createState() => _StockMarketTabState();
}

class _StockMarketTabState extends State<StockMarketTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text(
          '시세 영역\n(구현 예정)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}

