import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

class OrderConfirmationDialog extends StatelessWidget {
  final String symbol;
  final String orderType; // 매수, 매도
  final String orderMethod; // 지정가, 시장가
  final String quantity;
  final String? limitPrice;
  final String assetClass; // crypto, stock
  final String? totalAmount; // 총액 

  const OrderConfirmationDialog({
    super.key,
    required this.symbol,
    required this.orderType,
    required this.orderMethod,
    required this.quantity,
    this.limitPrice,
    required this.assetClass,
    this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isBuy = orderType == '매수';
    final typeColor = isBuy ? AppColors.chartRed : AppColors.chartBlue;
    
    final priceText = orderMethod == '시장가' 
        ? '시장가' 
        : '${limitPrice ?? 'N/A'}${assetClass == 'crypto' ? ' USD' : '원'}';
    final quantityText = '$quantity${assetClass == 'crypto' ? '개' : '주'}';
    final totalAmountText = totalAmount ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Container(
        width: context.w(393),
        padding: EdgeInsets.fromLTRB(
          context.w(36), 
          context.h(28), 
          context.w(36), 
          context.h(28) 
        ),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 주문 확인 타이틀
            Text(
              '주문 확인',
              textAlign: TextAlign.center,
              style: AppFonts.t1Bold.copyWith(
                color: AppColors.gray900,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            SizedBox(height: context.h(12)),

            // 심볼 + 주문타입
            Text(
              '$symbol $orderType',
              textAlign: TextAlign.center,
              style: AppFonts.t2Semibold.copyWith(
                color: typeColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.17,
              ),
            ),

            SizedBox(height: context.h(24)),

            // 지정가/시장가 라벨 & 값
            _buildDetailRow(
              context, 
              orderMethod == '시장가' ? '주문타입' : '지정가', 
              priceText
            ),
            SizedBox(height: context.h(12)),

            // 수량 라벨 & 값
            _buildDetailRow(context, '수량', quantityText),
            
            // 총액 라벨 & 값
            if (totalAmount != null) ...[
              SizedBox(height: context.h(12)),
              _buildDetailRow(context, '총액', totalAmountText),
            ],

            SizedBox(height: context.h(28)),

            // 버튼 영역
            Row(
              children: [
                // 취소 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: context.h(52),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE2E2E2), // Gray-150
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '취소',
                        style: AppFonts.t2Semibold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.w(12)), 
                // 주문 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      height: context.h(52),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF00C9A7), // Primary-Main
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '주문',
                        style: AppFonts.t2Semibold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFonts.b1Regular.copyWith(
            color: AppColors.gray600,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.25,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: AppFonts.b1Semibold.copyWith(
            color: AppColors.gray900,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
