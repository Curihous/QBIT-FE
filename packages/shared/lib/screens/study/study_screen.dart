import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/widgets/common/header_basic.dart';
import 'package:qbit_shared/widgets/common/padded_scaffold.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return PaddedScaffold(
      appBar: const HeaderBasic(
        title: '이론학습',
        onAlarmPressed: null,
        onSettingPressed: null,
      ),
      body: const Center(
        child: Text(
          '학습 화면',
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
