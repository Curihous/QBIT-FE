// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockDetailModel _$StockDetailModelFromJson(Map<String, dynamic> json) =>
    StockDetailModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      binanceSymbol: json['binanceSymbol'] as String?,
      exchange: json['exchange'] as String,
      assetClass: json['assetClass'] as String,
      status: json['status'] as bool,
      tradable: json['tradable'] as bool,
      fractionable: json['fractionable'] as String,
      minOrderSize: json['minOrderSize'] as String?,
      minTradeIncrement: json['minTradeIncrement'] as String?,
      priceIncrement: json['priceIncrement'] as String?,
      logoUrl: json['logoUrl'] as String?,
    );

Map<String, dynamic> _$StockDetailModelToJson(StockDetailModel instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'binanceSymbol': instance.binanceSymbol,
      'exchange': instance.exchange,
      'assetClass': instance.assetClass,
      'status': instance.status,
      'tradable': instance.tradable,
      'fractionable': instance.fractionable,
      'minOrderSize': instance.minOrderSize,
      'minTradeIncrement': instance.minTradeIncrement,
      'priceIncrement': instance.priceIncrement,
      'logoUrl': instance.logoUrl,
    };
