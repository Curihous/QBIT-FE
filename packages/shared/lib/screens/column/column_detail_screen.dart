import 'package:flutter/material.dart';
import 'package:qbit_shared/widgets/common/header_back.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_services/api/ai_api_service.dart';
import 'package:qbit_services/models/column.dart' as models;
import 'package:qbit_services/models/recommend_column_response.dart';
import 'package:qbit_services/models/api_error_response.dart';

class ColumnDetailScreen extends StatefulWidget {
  final String ticker;

  const ColumnDetailScreen({
    super.key,
    required this.ticker,
  });

  @override
  State<ColumnDetailScreen> createState() => _ColumnDetailScreenState();
}

class _ColumnDetailScreenState extends State<ColumnDetailScreen> {
  models.Column? _column;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadColumn();
  }

  Future<void> _loadColumn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final column = await AiApiService.getColumnByTicker(widget.ticker);
      
      if (mounted) {
        if (column != null) {
          setState(() {
            _column = column;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = '칼럼을 찾을 수 없습니다.';
            _isLoading = false;
          });
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '칼럼을 불러오는 중 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      // 날짜가 없으면 현재 날짜 사용
      final now = DateTime.now();
      return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    }
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      // 파싱 실패 시 현재 날짜 사용
      final now = DateTime.now();
      return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatSourceDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}년 ${date.month}월 ${date.day}일';
    } catch (e) {
      return '';
    }
  }

  bool _hasSourceInfo() {
    return (_column!.sourceTitle != null && _column!.sourceTitle!.isNotEmpty) ||
           (_column!.sourcePublisher != null && _column!.sourcePublisher!.isNotEmpty) ||
           (_column!.sourcePublishedAt != null && _column!.sourcePublishedAt!.isNotEmpty) ||
           (_column!.sourceUrl != null && _column!.sourceUrl!.isNotEmpty);
  }

  String _buildSourceText() {
    final parts = <String>[];
    
    // source_title이 있으면 우선 사용
    if (_column!.sourceTitle != null && _column!.sourceTitle!.isNotEmpty) {
      parts.add(_column!.sourceTitle!);
    }
    
    // source_publisher가 있으면 추가
    if (_column!.sourcePublisher != null && _column!.sourcePublisher!.isNotEmpty) {
      parts.add(_column!.sourcePublisher!);
    }
    
    // source_published_at이 있으면 추가
    final dateStr = _formatSourceDate(_column!.sourcePublishedAt);
    if (dateStr.isNotEmpty) {
      parts.add(dateStr);
    }
    
    // 위 정보가 없고 source_url만 있으면 URL 표시
    if (parts.isEmpty && _column!.sourceUrl != null && _column!.sourceUrl!.isNotEmpty) {
      return _column!.sourceUrl!;
    }
    
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const HeaderBack(title: '칼럼'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: AppFonts.b1Regular.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadColumn,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _column == null
                  ? Center(
                      child: Text(
                        '칼럼이 없습니다.',
                        style: AppFonts.b1Regular.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단 이미지 (가로 꽉 차고 높이 짧게)
                          if (_column!.imageUrl != null && _column!.imageUrl!.isNotEmpty)
                            Image.network(
                              _column!.imageUrl!,
                              width: double.infinity,
                              height: context.h(137),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: context.h(137),
                                  color: AppColors.gray100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: context.h(137),
                                color: AppColors.gray100,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.gray400,
                                  size: context.w(40),
                                ),
                              ),
                            ),
                          
                          // 내용 영역
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: context.h(16)),
                                
                                // 제목
                                Text(
                                  _column!.title,
                                  style: TextStyle(
                                    color: AppColors.gray900,
                                    fontSize: 18,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    height: 1.17,
                                  ),
                                ),
                                SizedBox(height: context.h(8)),
                                
                                // 부제목
                                if (_column!.subtitle != null && _column!.subtitle!.isNotEmpty)
                                  Text(
                                    _column!.subtitle!,
                                    style: TextStyle(
                                      color: AppColors.gray600,
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      height: 1.50,
                                    ),
                                  ),
                                SizedBox(height: context.h(4)),
                                
                                // 날짜 ∙ 심볼명
                                Text(
                                  '${_formatDate(_column!.generatedAt ?? _column!.sourcePublishedAt)} ∙ ${_column!.ticker}',
                                  style: TextStyle(
                                    color: AppColors.gray400,
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                    height: 2.10,
                                  ),
                                ),
                                SizedBox(height: context.h(16)),
                                
                                // 구분선
                                Container(
                                  width: double.infinity,
                                  height: 0.5,
                                  color: AppColors.gray150,
                                ),
                                SizedBox(height: context.h(24)),
                                
                                // 섹션들
                                ..._column!.sections.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final section = entry.value;
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index < _column!.sections.length - 1
                                          ? context.h(32)
                                          : 0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 섹션 헤더
                                        if (section.header != null && section.header!.isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(bottom: context.h(8)),
                                            child: Text(
                                              section.header!,
                                              style: TextStyle(
                                                color: AppColors.gray900,
                                                fontSize: 15,
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w600,
                                                height: 1.40,
                                              ),
                                            ),
                                          ),
                                        
                                        // 섹션 본문 (body)
                                        if (section.body != null && section.body!.isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(bottom: context.h(8)),
                                            child: Text(
                                              section.body!,
                                              style: TextStyle(
                                                color: AppColors.gray600,
                                                fontSize: 14,
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w500,
                                                height: 1.50,
                                              ),
                                            ),
                                          ),
                                        
                                        // 섹션 본문 (list)
                                        if (section.list != null && section.list!.isNotEmpty)
                                          ...section.list!.map((item) => Padding(
                                                padding: EdgeInsets.only(bottom: context.h(4)),
                                                child: Text(
                                                  item,
                                                  style: TextStyle(
                                                    color: AppColors.gray600,
                                                    fontSize: 14,
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.43,
                                                  ),
                                                ),
                                              )),
                                      ],
                                    ),
                                  );
                                }),
                                
                                SizedBox(height: context.h(32)),
                                
                                // 구분선
                                Container(
                                  width: double.infinity,
                                  height: 0.5,
                                  color: AppColors.gray150,
                                ),
                                SizedBox(height: context.h(16)),
                                
                                // 원본이 궁금하다면?
                                // TODO: 향후 개선사항
                                // - source_title을 "원문: [제목]" 형태로 표시
                                // - source_published_at을 "발행일: YYYY-MM-DD" 형태로 표시
                                // - source_url과 함께 "원문 보기" 버튼 제공
                                // - source_publisher 로고/이름 표시
                                if (_hasSourceInfo())
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '원본이 궁금하다면?',
                                        style: AppFonts.c2.copyWith(
                                          color: AppColors.gray600,
                                        ),
                                      ),
                                      SizedBox(height: context.h(8)),
                                      Text(
                                        _buildSourceText(),
                                        style: AppFonts.c2.copyWith(
                                          color: AppColors.gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                SizedBox(height: context.h(32)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
