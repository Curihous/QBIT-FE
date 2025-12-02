import 'package:flutter/material.dart';
import 'package:qbit_shared/widgets/common/header/header_back.dart';
import 'package:qbit_shared/widgets/record/emotion_selection_dialog.dart';
import 'package:qbit_shared/screens/record/order_selection_screen.dart';
import 'package:qbit_shared/models/order_history_model.dart';
import 'package:qbit_services/api/record_api_service.dart';
import 'package:qbit_services/api/order_api_service.dart';
import 'package:qbit_services/models/record_model.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

/// 거래 기록 작성 화면
class TradeRecordWriteScreen extends StatefulWidget {
  final RecordModel? record; // 수정 모드일 경우
  final int? orderId; // 주문 선택 화면에서 넘어온 경우

  const TradeRecordWriteScreen({
    super.key,
    this.record,
    this.orderId,
  });

  @override
  State<TradeRecordWriteScreen> createState() => _TradeRecordWriteScreenState();
}

class _TradeRecordWriteScreenState extends State<TradeRecordWriteScreen> {
  final TextEditingController _contentController = TextEditingController();
  TradeEmotion _selectedEmotion = TradeEmotion.neutral; // 기본값으로 neutral 설정
  OrderHistoryModel? _selectedOrder;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.record != null;
    if (_isEditMode && widget.record != null) {
      _contentController.text = widget.record!.content;
      _selectedEmotion = widget.record!.tradeEmotion;
      // 수정 모드에서는 주문 정보를 불러와야 함
      _loadOrderInfo();
    } else if (widget.orderId != null) {
      // 주문 선택 화면에서 넘어온 경우 주문 정보 로드
      _loadOrderFromId(widget.orderId!);
    }
  }

  Future<void> _loadOrderFromId(int orderId) async {
    try {
      final orderData = await OrderApiService.getOrder(orderId.toString());
      if (orderData != null && mounted) {
        try {
          final order = OrderHistoryModel.fromJson(
            orderData as Map<String, dynamic>,
          );
          setState(() {
            _selectedOrder = order;
          });
        } catch (e) {
          // 변환 실패 시 처리
        }
      }
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> _loadOrderInfo() async {
    if (widget.record == null) return;

    try {
      final orderData = await OrderApiService.getOrder(
        widget.record!.orderId.toString(),
      );
      if (orderData != null && mounted) {
        // OrderHistoryModel로 변환 (필요시)
      }
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> _selectOrder() async {
    final orderId = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => const OrderSelectionScreen(),
      ),
    );
    if (orderId != null && mounted) {
      // 주문 정보 로드
      final orderData = await OrderApiService.getOrder(orderId.toString());
      if (orderData != null && mounted) {
        // 주문 정보를 OrderHistoryModel로 변환
        try {
          final order = OrderHistoryModel.fromJson(
            orderData as Map<String, dynamic>,
          );
          setState(() {
            _selectedOrder = order;
          });
        } catch (e) {
          // 변환 실패 시 처리
        }
      }
    }
  }

  Future<void> _selectEmotion() async {
    final emotion = await showDialog<TradeEmotion>(
      context: context,
      builder: (context) => const EmotionSelectionDialog(),
    );

    if (emotion != null && mounted) {
      setState(() {
        _selectedEmotion = emotion;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    if (!_isEditMode && _selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주문을 선택해주세요')),
      );
      return;
    }

    // 감정은 항상 기본값(neutral) 또는 선택된 값 사용
    final emotionToSave = _selectedEmotion;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditMode && widget.record != null) {
        // 수정
        final result = await RecordApiService.updateRecord(
          recordId: widget.record!.recordId,
          content: _contentController.text.trim(),
          tradeEmotion: emotionToSave,
        );

        if (result != null && mounted) {
          Navigator.of(context).pop({'success': true});
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('수정에 실패했습니다')),
          );
        }
      } else {
        // 생성
        final result = await RecordApiService.createRecord(
          orderId: _selectedOrder!.orderId,
          content: _contentController.text.trim(),
          tradeEmotion: emotionToSave,
        );

        if (result != null && mounted) {
          Navigator.of(context).pop({'success': true});
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('작성에 실패했습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatOrderDate() {
    if (_isEditMode && widget.record != null) {
      try {
        final date = DateTime.parse(widget.record!.createdAt);
        return DateFormat('yy.MM.dd').format(date);
      } catch (e) {
        return DateFormat('yy.MM.dd').format(DateTime.now());
      }
    } else if (_selectedOrder != null) {
      try {
        final date = DateTime.parse(_selectedOrder!.createdAt);
        return DateFormat('yy.MM.dd').format(date);
      } catch (e) {
        return DateFormat('yy.MM.dd').format(DateTime.now());
      }
    }
    return DateFormat('yy.MM.dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBack(
        title: '매매 기록',
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: context.w(4)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '취소',
              style: AppFonts.btn4.copyWith(
                color: AppColors.gray400,
              ),
            ),
          ),
          SizedBox(width: context.w(8)),
          TextButton(
            onPressed: _isLoading ? null : _saveRecord,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: context.w(4)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '완료',
              style: AppFonts.btn4.copyWith(
                color: _isLoading
                    ? AppColors.gray400
                    : AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 주문 정보 카드
            Container(
              margin: EdgeInsets.only(
                left: context.w(16),
                right: context.w(16),
                top: context.h(16),
              ),
              width: context.w(361),
              padding: EdgeInsets.all(context.w(16)),
              decoration: BoxDecoration(
                color: AppColors.secondaryBG,
                borderRadius: BorderRadius.circular(8),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 날짜와 oval (secondaryBG 내부)
                if (_selectedOrder != null || _isEditMode) ...[
                  Builder(
                    builder: (context) {
                      final isBuy = _isEditMode
                          ? widget.record!.side == 'BUY'
                          : _selectedOrder!.side.toLowerCase() == 'buy';
                      return Row(
                        children: [
                          // 매수/매도에 따라 다른 색상의 oval 아이콘 표시
                          SvgPicture.asset(
                            isBuy
                                ? 'assets/icons/record/oval-red.svg'
                                : 'assets/icons/record/oval-blue.svg',
                            width: context.w(11),
                            height: context.w(11),
                          ),
                          SizedBox(width: context.w(8)),
                          Text(
                            _formatOrderDate(),
                            style: AppFonts.c1.copyWith(
                              color: AppColors.gray600,
                              fontSize: 13,
                              height: 1.23,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: context.h(12)),
                ],
                // 감정 아이콘과 주문 정보
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 감정 아이콘 또는 선택 버튼
                    GestureDetector(
                      onTap: _selectEmotion,
                      child: Container(
                        width: context.w(65),
                        height: context.h(45),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SvgPicture.asset(
                          _selectedEmotion.assetPath,
                          width: context.w(65),
                          height: context.h(45),
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(12)),
                    // 주문 정보 또는 선택 버튼
                    Expanded(
                      child: _isEditMode
                          ? Builder(
                              builder: (context) {
                                final isBuy = widget.record!.side == 'BUY';
                                final sideColor = isBuy 
                                    ? AppColors.chartRed 
                                    : AppColors.chartBlue;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.record!.symbol,
                                      style: AppFonts.b1Semibold,
                                    ),
                                    SizedBox(height: context.h(4)),
                                    Text(
                                      '${widget.record!.side == 'BUY' ? '매수' : '매도'}·대기 | 총액 \$${(double.tryParse(widget.record!.totalAmount?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                      style: AppFonts.c1.copyWith(
                                        color: sideColor,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : _selectedOrder != null
                              ? Builder(
                                  builder: (context) {
                                    final order = _selectedOrder!;
                                    final isBuy = order.side.isNotEmpty && order.side.toLowerCase() == 'buy';
                                    final sideColor = isBuy 
                                        ? AppColors.chartRed 
                                        : AppColors.chartBlue;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          order.symbol,
                                          style: AppFonts.b1Semibold,
                                        ),
                                        SizedBox(height: context.h(4)),
                                        Text(
                                          '${order.sideInKorean}·${order.statusInKorean} | 총액 \$${(double.tryParse(order.filledAvgPrice ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                          style: AppFonts.c1.copyWith(
                                            color: sideColor,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : GestureDetector(
                                  onTap: _selectOrder,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: AppColors.gray400,
                                        size: 20,
                                      ),
                                      SizedBox(width: context.w(8)),
                                      Text(
                                        '주문 선택',
                                        style: AppFonts.b1Semibold.copyWith(
                                          color: AppColors.gray400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            // 내용 입력 필드
            Container(
              margin: EdgeInsets.only(
                left: context.w(16),
                right: context.w(16),
                top: context.h(16),
                bottom: context.h(16),
              ),
              constraints: BoxConstraints(
                minHeight: context.h(311),
              ),
              padding: EdgeInsets.only(
                left: context.w(18),
                right: context.w(18),
                top: context.h(16),
                bottom: context.h(32),
              ),
              decoration: BoxDecoration(
                color: AppColors.gray30,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: null,
                    maxLength: 200,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '투자 결정 과정, 느낀 점 등을 기록해보세요.',
                      hintStyle: AppFonts.b1Regular.copyWith(
                        color: AppColors.gray600,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppFonts.b2Regular,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      '${_contentController.text.length}/200',
                      style: AppFonts.b2Regular.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

