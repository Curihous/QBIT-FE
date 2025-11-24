import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/widgets/common/padding/horizontal_inset.dart';
import 'package:qbit_services/websocket/crypto_market_websocket.dart';

class StockMarketTab extends StatefulWidget {
  final String symbol; // 화면 표시용 기본 심볼
  final String name;
  final String? assetClass;
  final String? binanceSymbol; // crypto일 때 WS 연결용

  const StockMarketTab({
    super.key,
    required this.symbol,
    required this.name,
    this.assetClass,
    this.binanceSymbol,
  });

  @override
  State<StockMarketTab> createState() => _StockMarketTabState();
}

class _StockMarketTabState extends State<StockMarketTab> {
  CryptoMarketWebSocket? _marketWs;
  double? _lastPrice;

  @override
  void initState() {
    super.initState();
    _maybeConnectWs();
  }

  @override
  void dispose() {
    _marketWs?.disconnect();
    _marketWs?.dispose();
    super.dispose();
  }

  Future<void> _maybeConnectWs() async {
    // crypto일 때 binanceSymbol 우선으로 WS 연결
    if ((widget.assetClass == 'crypto') && (widget.binanceSymbol?.isNotEmpty ?? false)) {
      _marketWs = CryptoMarketWebSocket();
      await _marketWs!.connect(widget.binanceSymbol!);
      _marketWs!.lastPriceStream.listen((price) {
        if (!mounted) return;
        setState(() {
          _lastPrice = price;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HorizontalInset.text(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                color: AppColors.gray900,
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _lastPrice != null ? '최근 체결가: ${_lastPrice!.toStringAsFixed(6)}' : '실시간 체결 데이터 대기 중',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray600,
                fontSize: 14,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

