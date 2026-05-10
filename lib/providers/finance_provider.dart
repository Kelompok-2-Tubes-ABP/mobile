import 'package:flutter/material.dart';
import '../models/transaction.dart' as t;
import '../models/budget.dart';
import '../models/investment.dart';

class FinanceProvider with ChangeNotifier {
  List<t.Transaction> _transactions = [
    t.Transaction(
      id: 't1',
      title: 'Gaji Bulanan',
      amount: 15000000,
      type: t.TransactionType.pemasukan,
      category: 'Pemasukan',
      date: DateTime.now().subtract(const Duration(days: 2)),
      time: '08:00',
      paymentMethod: 'BCA',
    ),
    t.Transaction(
      id: 't2',
      title: 'Belanja Groceries',
      amount: 250000,
      type: t.TransactionType.pengeluaran,
      category: 'Makanan',
      date: DateTime.now(),
      time: '14:30',
      paymentMethod: 'BCA',
    ),
    t.Transaction(
      id: 't3',
      title: 'Bensin Motor',
      amount: 50000,
      type: t.TransactionType.pengeluaran,
      category: 'Transportasi',
      date: DateTime.now(),
      time: '09:15',
      paymentMethod: 'Cash',
    ),
    t.Transaction(
      id: 't4',
      title: 'Belanja Online',
      amount: 450000,
      type: t.TransactionType.pengeluaran,
      category: 'Belanja',
      date: DateTime.now().subtract(const Duration(days: 3)),
      time: '20:45',
      paymentMethod: 'GoPay',
    ),
    t.Transaction(
      id: 't5',
      title: 'Pulsa & Paket Data',
      amount: 150000,
      type: t.TransactionType.pengeluaran,
      category: 'Tagihan',
      date: DateTime.now().subtract(const Duration(days: 3)),
      time: '18:30',
      paymentMethod: 'OVO',
    ),
    t.Transaction(
      id: 't6',
      title: 'Listrik & Air',
      amount: 550000,
      type: t.TransactionType.pengeluaran,
      category: 'Tagihan',
      date: DateTime.now().subtract(const Duration(days: 3)),
      time: '10:00',
      paymentMethod: 'BCA',
    ),
  ];

  List<Budget> _budgets = [
    Budget(id: 'b1', category: 'Makanan', limit: 1000000, spent: 850000),
    Budget(id: 'b2', category: 'Transportasi', limit: 800000, spent: 300000),
    Budget(id: 'b3', category: 'Hiburan', limit: 500000, spent: 650000),
    Budget(id: 'b4', category: 'Belanja', limit: 1200000, spent: 450000),
    Budget(id: 'b5', category: 'Tagihan', limit: 700000, spent: 300000),
    Budget(id: 'b6', category: 'Kesehatan', limit: 500000, spent: 0),
  ];

  List<t.Transaction> get transactions {
    // Sort transactions by date descending
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    return [..._transactions];
  }

  List<Budget> get budgets => [..._budgets];

  final List<Investment> _investments = [
    Investment(id: 'i1', name: 'Bitcoin', symbol: 'BTC', type: 'crypto', amount: 18000000, profitPercentage: 15.0, icon: Icons.currency_bitcoin, color: Colors.orange, platform: 'Binance', holdings: 0.15, avgCost: 110000000, currentPrice: 120000000),
    Investment(id: 'i2', name: 'Ethereum', symbol: 'ETH', type: 'crypto', amount: 5150000, profitPercentage: 8.2, icon: Icons.currency_exchange, color: Colors.blueAccent, platform: 'Indodax', holdings: 1.2, avgCost: 35000000, currentPrice: 40000000),
    Investment(id: 'i3', name: 'Bank Central Asia', symbol: 'BBCA', type: 'saham', amount: 10000000, profitPercentage: 5.4, icon: Icons.account_balance, color: Colors.blue, platform: 'Ajaib', holdings: 1000, avgCost: 9000, currentPrice: 9500),
    Investment(id: 'i4', name: 'Telkom Indonesia', symbol: 'TLKM', type: 'saham', amount: 5000000, profitPercentage: -2.1, icon: Icons.cell_tower, color: Colors.redAccent, platform: 'Ajaib', holdings: 1500, avgCost: 3500, currentPrice: 3300),
  ];

  List<Investment> get investments => [..._investments];
  double get totalInvestment => _investments.fold(0.0, (sum, item) => sum + item.amount);

  double get totalPemasukan {
    return _transactions
        .where((tx) => tx.type == t.TransactionType.pemasukan)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalPengeluaran {
    return _transactions
        .where((tx) => tx.type == t.TransactionType.pengeluaran)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalSaldo => totalPemasukan - totalPengeluaran;

  void addTransaction(t.Transaction transaction) {
    _transactions.add(transaction);
    
    // Auto update budget spent if it's an expense
    if (transaction.type == t.TransactionType.pengeluaran) {
      final budgetIndex = _budgets.indexWhere((b) => b.category == transaction.category);
      if (budgetIndex >= 0) {
        _budgets[budgetIndex].spent += transaction.amount;
      }
    }
    
    notifyListeners();
  }

  void addBudget(Budget budget) {
    _budgets.add(budget);
    notifyListeners();
  }

  void addInvestment(Investment investment) {
    _investments.add(investment);
    notifyListeners();
  }
}
