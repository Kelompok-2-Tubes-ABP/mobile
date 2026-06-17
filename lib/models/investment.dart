import 'package:flutter/material.dart';

class Investment {
  final String id;
  final String name;
  final String symbol;
  final String type; // 'crypto', 'stock'
  final double amount; // Current Value in IDR
  final double quatity; //Quantity
  final double profitPercentage; // e.g. 15.5 for +15.5%
  final IconData icon;
  final Color color;

  // Detailed fields for the card
  final String platform; // e.g. "Binance", "Ajaib"
  final double holdings; // e.g. 0.15
  final double avgCost; // e.g. 110000000
  final double currentPrice; // e.g. 120000000
  final double totalCost;
  final double gainLoss;

  double get totalValue => amount;

  Investment({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.quatity,
    required this.amount,
    required this.profitPercentage,
    required this.icon,
    required this.color,
    this.platform = 'Binance',
    this.holdings = 0.15,
    this.avgCost = 110000000,
    this.currentPrice = 120000000,
    required this.totalCost,
    required this.gainLoss,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    final symbol = json['symbol'] ?? '';
    final type = json['type'] ?? '';

    // Dynamically assign icon & color based on symbol or type
    IconData iconData = Icons.trending_up;
    Color colorData = Colors.blueGrey;

    if (symbol.toLowerCase() == 'btc') {
      iconData = Icons.currency_bitcoin;
      colorData = Colors.orange;
    } else if (symbol.toLowerCase() == 'eth') {
      iconData = Icons.currency_exchange;
      colorData = Colors.blueAccent;
    } else if (symbol.toLowerCase() == 'bbca') {
      iconData = Icons.account_balance;
      colorData = Colors.blue;
    } else if (symbol.toLowerCase() == 'tlkm') {
      iconData = Icons.cell_tower;
      colorData = Colors.redAccent;
    } else if (type.toLowerCase() == 'crypto') {
      iconData = Icons.currency_bitcoin;
      colorData = Colors.orange;
    } else if (type.toLowerCase() == 'stock' || type.toLowerCase() == 'saham') {
      iconData = Icons.show_chart;
      colorData = Colors.blue;
    }

    return Investment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: symbol,
      type: type,
      quatity: (json['quantity'] ?? json['quatity'] ?? 0.0).toDouble(),
      amount: (json['total_value'] ?? json['amount'] ?? 0.0).toDouble(),
      profitPercentage:
          (json['gain_loss_percent'] ?? json['profitPercentage'] ?? 0.0)
              .toDouble(),
      icon: iconData,
      color: colorData,
      platform: json['exchange'] ?? json['platform'] ?? 'Binance',
      holdings: (json['quantity'] ?? json['holdings'] ?? 0.0).toDouble(),
      avgCost: (json['average_cost'] ?? json['avgCost'] ?? 0.0).toDouble(),
      currentPrice: (json['current_price'] ?? json['currentPrice'] ?? 0.0)
          .toDouble(),
      totalCost: (json['total_cost'] ??
              (json['quantity'] ?? json['holdings'] ?? 0.0) *
                  (json['average_cost'] ?? json['avgCost'] ?? 0.0))
          .toDouble(),
      gainLoss: (json['gain_loss'] ??
              (json['total_value'] ?? json['amount'] ?? 0.0) -
                  (json['total_cost'] ?? 0.0))
          .toDouble(),
    );
  }
}

class InvestmentSummary {
  final int totalInvestments;
  final double totalValue;
  final double totalCost;
  final double gainLoss;
  final double gainLossPercent;
  final Map<String, double> byType;

  InvestmentSummary({
    required this.totalInvestments,
    required this.totalValue,
    required this.totalCost,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.byType,
  });

  factory InvestmentSummary.fromJson(Map<String, dynamic> json) {
    final rawByType = json['by_type'] as Map<String, dynamic>? ?? {};
    final Map<String, double> mappedByType = {};
    rawByType.forEach((key, value) {
      mappedByType[key] = (value as num).toDouble();
    });

    return InvestmentSummary(
      totalInvestments: json['total_investments'] ?? 0,
      totalValue: (json['total_value'] ?? 0.0).toDouble(),
      totalCost: (json['total_cost'] ?? 0.0).toDouble(),
      gainLoss: (json['gain_loss'] ?? 0.0).toDouble(),
      gainLossPercent: (json['gain_loss_percent'] ?? 0.0).toDouble(),
      byType: mappedByType,
    );
  }

  factory InvestmentSummary.empty() {
    return InvestmentSummary(
      totalInvestments: 0,
      totalValue: 0.0,
      totalCost: 0.0,
      gainLoss: 0.0,
      gainLossPercent: 0.0,
      byType: {},
    );
  }
}
