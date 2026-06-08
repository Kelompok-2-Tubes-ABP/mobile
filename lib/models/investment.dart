import 'package:flutter/material.dart';

class Investment {
  final String id;
  final String name;
  final String symbol;
  final String type; // 'crypto', 'saham'
  final double amount; // Current Value in IDR
  final double profitPercentage; // e.g. 15.5 for +15.5%
  final IconData icon;
  final Color color;
  
  // Detailed fields for the card
  final String platform; // e.g. "Binance", "Ajaib"
  final double holdings; // e.g. 0.15
  final double avgCost; // e.g. 110000000
  final double currentPrice; // e.g. 120000000

  Investment({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.amount,
    required this.profitPercentage,
    required this.icon,
    required this.color,
    this.platform = 'Binance',
    this.holdings = 0.15,
    this.avgCost = 110000000,
    this.currentPrice = 120000000,
  });
}
