import 'package:flutter/material.dart';

/// 모든 페이지에 기본 좌우 패딩을 적용하는 Scaffold
class PaddedScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final double horizontalPadding;

  const PaddedScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// 기본 패딩이 적용된 Container
class PaddedContainer extends StatelessWidget {
  final Widget child;
  final double horizontalPadding;
  final double? verticalPadding;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const PaddedContainer({
    super.key,
    required this.child,
    this.horizontalPadding = 16.0,
    this.verticalPadding,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding ?? 0,
      ),
      child: child,
    );
  }
}
