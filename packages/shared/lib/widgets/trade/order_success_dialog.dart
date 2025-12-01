import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_shared/widgets/common/button/big_black_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io' show Platform;

class OrderSuccessDialog extends StatelessWidget {
  final String symbol;
  final String orderType; // 매수, 매도
  final String orderMethod; // 지정가, 시장가
  final String price;
  final String quantity;
  final String totalAmount;
  final String currency;

  final String? logoUrl;

  const OrderSuccessDialog({
    super.key,
    required this.symbol,
    required this.orderType,
    required this.orderMethod,
    required this.price,
    required this.quantity,
    required this.totalAmount,
    required this.currency,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        minHeight: context.h(427),
      ),
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      child: SingleChildScrollView(
          child: Padding(
          padding: EdgeInsets.only(
            left: context.w(20),
            right: context.w(20),
            top: context.h(24),
            bottom: MediaQuery.of(context).padding.bottom + context.h(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: context.h(24)),
                    // 로고
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30), 
                        border: Border.all(color: AppColors.gray100),
                      ),
                      child: ClipOval(
                        child: logoUrl != null && logoUrl!.isNotEmpty
                            ? Image.network(
                                logoUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultLogo();
                                },
                              )
                            : _buildDefaultLogo(),
                      ),
                    ),
                    SizedBox(height: context.h(16)),
                    
                    // 성공 메시지
                    Text(
                      '$symbol $orderType 주문 요청 성공',
                      style: AppFonts.t1Bold.copyWith(
                        color: orderType == '매수' ? AppColors.chartRed : AppColors.chartBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.h(8)),
                    Text(
                      '가격 급등락 시 예상 체결가와 다른 금액에 체결될 수 있어요.',
                      style: AppFonts.c1.copyWith(
                        color: AppColors.gray600,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.h(32)),
                    
                    // 주문 상세 정보
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.w(40)),
                      child: Column(
                        children: [
                          _buildOrderDetailRow(
                            orderMethod == '시장가' ? '시장가' : '지정가',
                            orderMethod == '시장가' ? orderMethod : '$price$currency',
                          ),
                          SizedBox(height: context.h(12)),
                          _buildOrderDetailRow(
                            '수량',
                            '$quantity${currency == '원' ? '주' : '개'}',
                          ),
                          SizedBox(height: context.h(12)),
                          _buildOrderDetailRow(
                            '총액',
                            totalAmount == '체결 후 확인 가능' ? totalAmount : '$totalAmount$currency',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.h(60)),
                    
                    // 매매 일지 작성하기 버튼
                    BigBlackButton(
                      text: '매매 일지 작성하기',
                      onPressed: () {
                        // TODO: 매매 일지 작성 페이지로 이동
                        Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(height: context.h(20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF8E1),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFonts.b2Regular.copyWith(
            color: AppColors.gray600,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: AppFonts.b2Regular.copyWith(
            color: AppColors.gray900,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
