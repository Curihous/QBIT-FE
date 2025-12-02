import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/common/header/header_basic.dart';
import 'package:qbit_shared/widgets/common/button/filter_button.dart';
import 'package:qbit_shared/widgets/record/month_navigator.dart';
import 'package:qbit_shared/widgets/record/month_summary_card.dart';
import 'package:qbit_shared/widgets/record/record_item.dart';
import 'package:qbit_shared/widgets/record/record_action_dialog.dart';
import 'package:qbit_shared/screens/record/order_selection_screen.dart';
import 'package:qbit_shared/screens/record/record_writing_screen.dart';
import 'package:qbit_services/api/record_api_service.dart';
import 'package:qbit_services/models/record_model.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_shared/layout/horizontal_inset.dart';
import 'package:go_router/go_router.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'ALL'; // 'ALL', 'BUY', 'SELL'
  List<RecordModel> _records = [];
  bool _isLoading = false;
  int _totalTrades = 0;
  double _profitRate = 0.0;
  double _cumulativeProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recordsFuture = RecordApiService.getMonthlyRecords(
        year: _selectedDate.year,
        month: _selectedDate.month,
        side: _selectedFilter == 'ALL' ? null : _selectedFilter,
      );
      
      final statisticsFuture = RecordApiService.getMonthlyStatistics(
        year: _selectedDate.year,
        month: _selectedDate.month,
      );

      final results = await Future.wait([recordsFuture, statisticsFuture]);
      final response = results[0] as RecordPageResponse?;
      final statistics = results[1] as MonthlyTradeStatisticsResponse?;

      if (mounted) {
        setState(() {
          if (response != null) {
            _records = response.content;
            _totalTrades = response.totalElements;
          } else {
            _records = [];
            _totalTrades = 0;
          }
          
          // 통계 데이터 적용
          if (statistics != null) {
            _totalTrades = statistics.totalTradeCount;
            _profitRate = statistics.profitRate;
            _cumulativeProfit = statistics.cumulativeProfitLoss;
          } else {
            // 통계가 없으면 기본값
            _profitRate = 0.0;
            _cumulativeProfit = 0.0;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPreviousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
    _loadRecords();
  }

  void _onNextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
    _loadRecords();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadRecords();
  }

  Future<void> _navigateToWriteScreen() async {
    final orderId = await context.push<int>(
      '/record/order-selection',
    );

    if (orderId != null) {
      // 주문 선택 후 기록 작성 화면으로 이동
      final result = await context.push<Map<String, dynamic>?>(
        '/record/write',
        extra: orderId,
      );

      if (result != null && result['success'] == true) {
        _loadRecords();
      }
    }
  }

  Future<void> _showRecordActionMenu(RecordModel record, BuildContext itemContext) async {
    final RenderBox? renderBox = itemContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    // 연필 아이콘 위치 계산 (우측 상단)
    final iconX = offset.dx + size.width - 24;
    final iconY = offset.dy;
    final iconSize = 24.0;
    
    // 팝업 메뉴 너비 추정 (텍스트 + 패딩)
    final estimatedPopupWidth = 70.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final popupLeft = iconX - estimatedPopupWidth;
    final popupTop = iconY + iconSize + 20;

    final action = await showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      position: RelativeRect.fromLTRB(
        popupLeft,
        popupTop,
        screenWidth - iconX, // 팝업 오른쪽 끝이 iconX와 맞춤
        screenHeight - popupTop - 100, // 대략적인 높이
      ),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Text(
            '수정',
            style: AppFonts.b2Regular.copyWith(
              color: AppColors.gray900,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Text(
            '삭제',
            style: AppFonts.b2Regular.copyWith(
              color: AppColors.chartRed,
            ),
          ),
        ),
      ],
    );

    if (action == null) return;

    if (action == 'edit') {
      await _navigateToEditScreen(record);
    } else if (action == 'delete') {
      await _deleteRecord(record);
    }
  }

  Future<void> _navigateToEditScreen(RecordModel record) async {
    final result = await context.push<Map<String, dynamic>?>(
      '/record/edit',
      extra: record,
    );

    if (result != null && result['success'] == true) {
      _loadRecords();
    }
  }

  Future<void> _deleteRecord(RecordModel record) async {
    // 삭제 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(24),
            vertical: context.h(24),
          ),
          decoration: BoxDecoration(
            color: AppColors.gray0,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '정말 삭제하시겠어요?',
                style: AppFonts.b1Bold.copyWith(
                  color: AppColors.gray900,
                ),
              ),
              SizedBox(height: context.h(8)),
              // 설명
              Text(
                '삭제된 거래 기록은 다시 복구할 수 없어요.',
                style: AppFonts.b2Regular.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              SizedBox(height: context.h(24)),
              // 버튼
              Row(
                children: [
                  // 삭제 버튼
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: context.h(14),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '삭제',
                            style: AppFonts.b2Semibold.copyWith(
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  // 취소 버튼
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: context.h(14),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '취소',
                            style: AppFonts.b2Semibold.copyWith(
                              color: AppColors.gray0,
                            ),
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
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await RecordApiService.deleteRecord(
        recordId: record.recordId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래 기록이 삭제되었습니다')),
        );
        _loadRecords();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBasic(
        title: '기록',
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 월별 네비게이터
              MonthNavigator(
                selectedDate: _selectedDate,
                onPreviousMonth: _onPreviousMonth,
                onNextMonth: _onNextMonth,
              ),
              // 월별 요약 카드
              MonthSummaryCard(
                totalTrades: _totalTrades,
                profitRate: _profitRate,
                cumulativeProfit: _cumulativeProfit,
              ),
              // 필터 버튼
              Inset.block(
                child: FilterButtonGroup(
                  labels: ['전체', '매수', '매도'],
                  values: ['ALL', 'BUY', 'SELL'],
                  initialValue: _selectedFilter,
                  onChanged: _onFilterChanged,
                  groupPadding: EdgeInsets.only(top: context.h(0), bottom: context.h(6)),
                ),
              ),
              // 거래 기록 목록
              Expanded(
                child: Container(
                  color: AppColors.gray50,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _records.isEmpty
                          ? Center(
                              child: Text(
                                '거래 기록이 없습니다',
                                style: TextStyle(color: AppColors.gray600),
                              ),
                            )
                          : HorizontalInset.block(
                              child: ListView.builder(
                                padding: EdgeInsets.only(
                                  top: context.h(8),
                                  bottom: context.h(100), 
                                ),
                                itemCount: _records.length,
                                itemBuilder: (context, index) {
                                  final record = _records[index];
                                  return RecordItem(
                                    record: record,
                                    onTap: () {
                                      // 상세 보기 (필요시 구현)
                                    },
                                    onEditTap: (itemContext) => _showRecordActionMenu(record, itemContext),
                                  );
                                },
                              ),
                            ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
