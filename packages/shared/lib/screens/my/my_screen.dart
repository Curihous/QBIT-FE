import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/widgets/common/header_home.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopAppBar(),
      body: const Center(
        child: Text(
          'MY 화면',
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
