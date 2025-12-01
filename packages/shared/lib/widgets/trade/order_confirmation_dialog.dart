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
    final typeColor = isBuy ? AppColors.loss : AppColors.profit;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: context.w(16)), // 너비 확보를 위해 패딩 축소
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: context.w(24), vertical: context.h(28)), // 세로 패딩 축소
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              '주문 확인',
              textAlign: TextAlign.center,
              style: AppFonts.t1Bold.copyWith(
                color: AppColors.gray900,
                fontSize: 18, 
              ),
            ),
            SizedBox(height: context.h(8)), 

            // Subtitle (Symbol + Type)
            Text(
              '$symbol $orderType',
              textAlign: TextAlign.center,
              style: AppFonts.t2Semibold.copyWith(
                color: typeColor,
                fontSize: 17, 
              ),
            ),
            SizedBox(height: context.h(12)), 

            // 위험 문구 
            if (orderMethod == '시장가') ...[
              Text(
                '가격 급등락 시 예상 체결가와 다른 금액에 체결될 수 있어요.',
                textAlign: TextAlign.center,
                style: AppFonts.b2Regular.copyWith(
                  color: AppColors.gray600,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: context.h(24)),
            ] else ...[
              SizedBox(height: context.h(12)),
            ],

            // Details
            _buildDetailRow(context, orderMethod == '시장가' ? '주문타입' : '지정가', 
                orderMethod == '시장가' ? '시장가' : '${limitPrice ?? 'N/A'}${assetClass == 'crypto' ? ' USD' : '원'}'),
            SizedBox(height: context.h(12)), 
            
            _buildDetailRow(context, '수량', '$quantity${assetClass == 'crypto' ? '개' : '주'}'),
            
            if (totalAmount != null) ...[
              SizedBox(height: context.h(12)), 
              _buildDetailRow(context, '총액', totalAmount!),
            ],

            SizedBox(height: context.h(32)), 

            // Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 52,
                      decoration: ShapeDecoration(  
                        color: const Color(0xFFE2E2E2), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '취소',
                        style: AppFonts.t2Semibold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      height: 52,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF00C9A7), // Primary-Main
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '주문',
                        style: AppFonts.t2Semibold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
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
            fontSize: 14,   
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: AppFonts.b1Semibold.copyWith(
            color: AppColors.gray900, 
              fontSize: 14, 
            ),
        ),
      ],
    );
  }
}
