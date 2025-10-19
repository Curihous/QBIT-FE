import 'package:flutter/material.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

/// 전역 간격 규칙
class AppInset {
  static double text(BuildContext context) => context.w(20);   // 텍스트용
  static double block(BuildContext context) => context.w(16);  // 비텍스트(박스/카드/섹션)용
}

/// 좌우 여백을 일관되게 주는 래퍼
class HorizontalInset extends StatelessWidget {
  final Widget child;
  final double? start;
  final double? end;
  final bool isText;
  final bool isBlock;
  final bool isStartOnly;
  final bool isEndOnly;

  // Private 생성자
  const HorizontalInset._({
    required this.child,
    this.start,
    this.end,
    this.isText = false,
    this.isBlock = false,
    this.isStartOnly = false,
    this.isEndOnly = false,
    super.key,
  });

  /// 텍스트용: 좌우 20px
  const HorizontalInset.text({Key? key, required Widget child})
      : this._(child: child, isText: true, key: key);

  /// 비텍스트용: 좌우 16px
  const HorizontalInset.block({Key? key, required Widget child})
      : this._(child: child, isBlock: true, key: key);

  /// 좌측만: 텍스트용
  const HorizontalInset.startText({Key? key, required Widget child})
      : this._(child: child, isText: true, isStartOnly: true, key: key);

  /// 좌측만: 비텍스트용
  const HorizontalInset.startBlock({Key? key, required Widget child})
      : this._(child: child, isBlock: true, isStartOnly: true, key: key);

  /// 우측만: 텍스트용
  const HorizontalInset.endText({Key? key, required Widget child})
      : this._(child: child, isText: true, isEndOnly: true, key: key);

  /// 우측만: 비텍스트용
  const HorizontalInset.endBlock({Key? key, required Widget child})
      : this._(child: child, isBlock: true, isEndOnly: true, key: key);

  /// 커스텀 값 지정
  const HorizontalInset.custom({
    Key? key,
    required Widget child,
    double? start,
    double? end,
  }) : this._(child: child, start: start, end: end, key: key);

  @override
  Widget build(BuildContext context) {
    double startValue = 0;
    double endValue = 0;

    if (start != null) {
      startValue = start!;
      endValue = end ?? 0;
    } else {
      if (isText) {
        startValue = isStartOnly ? AppInset.text(context) : (isEndOnly ? 0 : AppInset.text(context));
        endValue = isEndOnly ? AppInset.text(context) : (isStartOnly ? 0 : AppInset.text(context));
      } else if (isBlock) {
        startValue = isStartOnly ? AppInset.block(context) : (isEndOnly ? 0 : AppInset.block(context));
        endValue = isEndOnly ? AppInset.block(context) : (isStartOnly ? 0 : AppInset.block(context));
      }
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(start: startValue, end: endValue),
      child: child,
    );
  }
}

// 짧은 별칭
typedef Inset = HorizontalInset;
