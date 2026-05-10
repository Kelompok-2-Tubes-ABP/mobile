import 'package:flutter/material.dart';
import '../models/transaction.dart' as t;
import '../models/budget.dart';

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
}
