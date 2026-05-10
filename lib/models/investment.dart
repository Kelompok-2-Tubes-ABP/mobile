import 'package:flutter/material.dart';

class Investment {
  final String id;
  final String name;
  final String symbol;
  final String type; // 'crypto', 'saham'
  final double amount; // Value in IDR
  final double profitPercentage; // e.g. 15.5 for +15.5%, -5.2 for -5.2%
  final IconData icon;
  final Color color;

  Investment({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.amount,
    required this.profitPercentage,
    required this.icon,
    required this.color,
  });
}
