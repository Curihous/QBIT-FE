import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/common/header/header_basic.dart';
import 'package:qbit_shared/layout/horizontal_inset.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderBasic(
        title: '마이페이지',
        onAlarmPressed: null,
        onSettingPressed: null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Inset.text(
              child: Text(
                '계정 설정',
                style: AppFonts.t2Bold.copyWith(color: AppColors.gray900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}