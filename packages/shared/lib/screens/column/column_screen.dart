import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/common/header_back.dart';

class ColumnScreen extends StatelessWidget {
  const ColumnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray30,
      appBar: const HeaderBack(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 영역
            Container(
              width: double.infinity,
              height: 162,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: Text(
                '🪙 이더리움, 다시 뜨거워질까?',
                style: AppFonts.t2Bold.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 부제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '불붙는 코인 시장, 유동성 신호등이 켜졌다.',
                style: AppFonts.b1Regular.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            
            const SizedBox(height: 22),
            
            // 날짜
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '2025.10.21',
                style: AppFonts.c2.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // 구분선
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 1,
              decoration: const BoxDecoration(
                color: AppColors.gray150,
              ),
            ),
            
            const SizedBox(height: 22),
            
            // 오늘의 투자 한입 뉴스 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '💡 오늘의 투자 한입 뉴스',
                style: AppFonts.b1Semibold.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 뉴스 내용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '"이더리움, 다시 뜨거워질까?"\n\n이더리움(ETH) 은 암호화폐 시장의 \'기반 기술 코인\'이에요. 비트코인이 "디지털 금"이라면, 이더리움은 "블록체인의 운영체제" 같은 존재죠.\n\nUSDT(테더) 는 1달러에 맞춰 움직이는 스테이블 코인이에요.\n가격이 거의 안 변해서, \'달러 대신 쓸 수 있는 코인\'처럼 쓰여요.\n그래서 ETH/USDT로 거래한다는 건, "달러 기반의 안정된 코인으로 이더리움을 산다"는 뜻이에요.',
                style: AppFonts.b2Regular.copyWith(
                  color: AppColors.gray900,
                  height: 1.21,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 최근 무슨 일이야? 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '📈 최근 무슨 일이야?',
                style: AppFonts.b1Bold.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 최근 내용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '최근 10월 중순, 이더리움 네트워크에서 10억 달러 가까운 테더(USDT)가 새로 발행됐어요.\n👉 시장에 돈(유동성)이 더 풀렸다는 신호예요. 이건 이더리움 가격이 움직일 수 있다는 의미로 해석돼요.\n\n하지만 동시에 "경기 불안" 때문에 안전자산(USDT)으로 옮겨타는 사람도 많아요.\n즉, 이더리움 vs 테더 싸움은 지금도 팽팽하다는 뜻이죠.\n\nARK Invest는 최근 보고서에서 이렇게 말했어요.\n\n"이더리움은 단순한 코인이 아니라 미 재무부 채권(Treasury)에 가까운 디지털 자산 기반으로 자리 잡고 있다."\n\n이건 코인을 \'투기\'로만 보던 시선에서, \'디지털 인프라 자산\'으로 바뀌는 흐름이에요.',
                style: AppFonts.b2Regular.copyWith(
                  color: AppColors.gray900,
                  height: 1.21,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 초보 투자자 포인트 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '🧠 초보 투자자가 알아두면 좋은 포인트',
                style: AppFonts.b1Bold.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 초보 투자자 내용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '1. USDT는 안정적이지만 완전 무풍은 아님\n달러 연동을 지향하지만, \'진짜로 1달러가 다 담보돼 있냐\'는 논란이 아직 있어요.\n\n2. 이더리움은 성장 가능성 vs. 변동성의 대표주자\n기술 발전에 따라 오를 수도 있지만, 규제, 업그레이드 지연 등 변수에 따라 출렁일 수 있어요.\n\n3. ETH/USDT 페어는 \'균형 감각\'이 핵심\n이건 \'불확실한 자산(ETH)\'을 \'안정적인 기준(USDT)\'으로 사고파는 구조예요. 즉, 시장 분위기에 따라 수익도 손실도 커질 수 있습니다.',
                style: AppFonts.b2Regular.copyWith(
                  color: AppColors.gray900,
                  height: 1.21,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 한줄 요약 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '✍️ 한줄 요약',
                style: AppFonts.b1Bold.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 한줄 요약 내용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '이더리움은 기회, 테더는 안전. ETH/USDT는 그 사이에서 \'균형감각\'을 배우는 거래예요.\n\n📚 함께 보면 좋은 키워드: 스테이블코인, 유동성, 리스크 관리',
                style: AppFonts.b2Regular.copyWith(
                  color: AppColors.gray900,
                  height: 1.21,
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            
            // 구분선
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 1,
              decoration: const BoxDecoration(
                color: AppColors.gray150,
              ),
            ),
            
            const SizedBox(height: 13),
            
            // 원문 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '원문이 궁금하다면?',
                style: AppFonts.c2.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Ethereum Network Sees Nearly \$1B in USDT Mints – Fresh Liquidity Amid Market Downturn (Mitrade, 2025년 10월 18일)',
                style: AppFonts.c2.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
