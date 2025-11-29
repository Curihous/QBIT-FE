import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/widgets/common/header/header_basic.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBasic(
        title: '기록',
      ),
      body: const Center(
        child: Text(
          '기록 화면',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppColors.gray900,
          ),
        ),
      ),
    );
  }
}
