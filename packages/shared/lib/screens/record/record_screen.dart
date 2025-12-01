import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/widgets/common/header/header_basic.dart';
import 'package:qbit_shared/widgets/common/button/filter_button.dart';
import 'package:qbit_shared/widgets/record/month_navigator.dart';
import 'package:qbit_shared/widgets/record/month_summary_card.dart';
import 'package:qbit_shared/widgets/record/record_item.dart';
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
      final response = await RecordApiService.getMonthlyRecords(
        year: _selectedDate.year,
        month: _selectedDate.month,
        side: _selectedFilter == 'ALL' ? null : _selectedFilter,
      );

      if (response != null && mounted) {
        setState(() {
          _records = response.content;
          _totalTrades = response.totalElements;
          // TODO: 실제 수익률과 누적 손익은 API에서 받아와야 함
          _profitRate = 7.3; // 임시 값
          _cumulativeProfit = 3500.0; // 임시 값
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _records = [];
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

  Future<void> _navigateToEditScreen(RecordModel record) async {
    final result = await context.push<Map<String, dynamic>?>(
      '/record/edit',
      extra: record,
    );

    if (result != null && result['success'] == true) {
      _loadRecords();
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
                  labels: ['전체 보기', '매수 기록', '매도 기록'],
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
                                    onEditTap: () => _navigateToEditScreen(record),
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
