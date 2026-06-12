import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/transaction.dart' as t;
import '../models/budget.dart';
import '../models/investment.dart';
import '../models/quick_stats.dart';
import '../models/savings_goal.dart';

class FinanceProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  
  QuickStats _quickStats = QuickStats.empty();
  QuickStats get quickStats => _quickStats;

  List<SavingsGoal> _savingsGoals = [];
  List<SavingsGoal> get savingsGoals => [..._savingsGoals];

  SavingsSummary _savingsSummary = SavingsSummary.empty();
  SavingsSummary get savingsSummary => _savingsSummary;

  bool _isLoadingSavings = false;
  bool get isLoadingSavings => _isLoadingSavings;

  InvestmentSummary _investmentSummary = InvestmentSummary.empty();
  InvestmentSummary get investmentSummary => _investmentSummary;

  bool _isLoadingInvestment = false;
  bool get isLoadingInvestment => _isLoadingInvestment;

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

  List<Budget> _budgets = [];

  List<t.Transaction> get transactions {
    // Sort transactions by date descending
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    return [..._transactions];
  }

  List<Budget> get budgets => [..._budgets];

  List<Investment> _investments = [];

  List<Investment> get investments => [..._investments];
  double get totalInvestment =>
      _investments.fold(0.0, (sum, item) => sum + item.amount);

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

  Future<void> fetchQuickStats() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/analytics/quick'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('QUICK STATS STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          _quickStats = QuickStats.fromJson(body['data']);
          notifyListeners();
          print('BERHASIL LOAD QUICK STATS');
        }
      }
    } catch (e) {
      print('ERROR FETCH QUICK STATS: $e');
    }
  }

  Future<void> fetchTransactions() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/transaction/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('FETCH TRANSACTION STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> transactionsJson =
            data['Transaction Retrieved Successfully!!'];

        _transactions = transactionsJson
            .map((item) => t.Transaction.fromApiJson(item))
            .toList();

        notifyListeners();

        print('BERHASIL LOAD ${_transactions.length} TRANSAKSI');
      }
    } catch (e) {
      print('ERROR FETCH TRANSACTION: $e');
    }
  }

  Future<void> fetchBudgets({String? month}) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    final targetMonth = month ?? "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/budget/category/by-month/$targetMonth/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _budgets = data.map((item) => Budget.fromApiJson(item)).toList();
        notifyListeners();
        print('BERHASIL LOAD ${_budgets.length} BUDGETS');
      } else {
        print('GAGAL LOAD BUDGETS: ${response.body}');
      }
    } catch (e) {
      print('ERROR BUDGET: $e');
    }
  }

  Future<bool> createCategoryBudget(String category, double limit) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    final targetMonth = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/budget/category'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'category': category,
          'limit': limit,
          'month': targetMonth,
        }),
      );

      print('CREATE BUDGET STATUS: ${response.statusCode}');
      print('CREATE BUDGET BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('BUDGET BERHASIL DITAMBAHKAN KE BACKEND');
        await fetchBudgets();
        return true;
      } else {
        print('Gagal menambahkan budget: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR CREATE BUDGET: $e');
      return false;
    }
  }

  Future<void> fetchBudgetSummary() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/budget/summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('SUMMARY STATUS: ${response.statusCode}');
      print('SUMMARY BODY: ${response.body}');
    } catch (e) {
      print('ERROR SUMMARY: $e');
    }
  }

  Future<void> fetchAllBudgetSpending() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/budget/all-spending'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('SPENDING STATUS: ${response.statusCode}');
      print('SPENDING BODY: ${response.body}');
    } catch (e) {
      print('ERROR SPENDING: $e');
    }
  }

  void addTransaction(t.Transaction transaction) {
    _transactions.add(transaction);

    // Auto update budget spent if it's an expense
    if (transaction.type == t.TransactionType.pengeluaran) {
      final budgetIndex = _budgets.indexWhere(
        (b) => b.category == transaction.category,
      );
      if (budgetIndex >= 0) {
        _budgets[budgetIndex].spent += transaction.amount;
      }
    }

    notifyListeners();
  }

  Future<bool> createTransaction(t.Transaction transaction) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    // Map transaction category to align with frontend parsing & backend categorizations
    String categoryToSend = transaction.category;
    if (transaction.type == t.TransactionType.pemasukan) {
      // Map all income categories to "pendapatan" so that they are correctly
      // parsed back as TransactionType.pemasukan by the frontend API parser.
      categoryToSend = 'pendapatan';
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/transaction/new'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': transaction.amount,
          'category': categoryToSend,
          'description': transaction.title,
          'status': 'completed',
          'date': transaction.date.toUtc().toIso8601String(),
        }),
      );

      print('CREATE TRANSACTION STATUS: ${response.statusCode}');
      print('CREATE TRANSACTION BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('TRANSAKSI BERHASIL DITAMBAHKAN KE BACKEND');
        
        // Refresh transaction list from API
        await fetchTransactions();
        
        // Refresh budget as well in case budget spent needs update
        await fetchBudgets();
        
        // Refresh quick stats
        await fetchQuickStats();
        
        notifyListeners();
        return true;
      } else {
        print('Gagal menambahkan transaksi: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR CREATE TRANSACTION: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8000/transaction/delete/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('DELETE TRANSACTION STATUS: ${response.statusCode}');
      print('DELETE TRANSACTION BODY: ${response.body}');

      if (response.statusCode == 200) {
        print('TRANSAKSI BERHASIL DIHAPUS DARI BACKEND');
        
        // Refresh transaction list from API
        await fetchTransactions();
        
        // Refresh budget as well in case budget spent needs update
        await fetchBudgets();
        
        // Refresh quick stats
        await fetchQuickStats();
        
        notifyListeners();
        return true;
      } else {
        print('Gagal menghapus transaksi: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR DELETE TRANSACTION: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(String id, t.Transaction transaction) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    // Map transaction category to align with frontend parsing & backend categorizations
    String categoryToSend = transaction.category;
    if (transaction.type == t.TransactionType.pemasukan) {
      categoryToSend = 'pendapatan';
    }

    try {
      final response = await http.patch(
        Uri.parse('http://localhost:8000/transaction/update/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': transaction.amount,
          'category': categoryToSend,
          'description': transaction.title,
          'status': 'completed',
        }),
      );

      print('UPDATE TRANSACTION STATUS: ${response.statusCode}');
      print('UPDATE TRANSACTION BODY: ${response.body}');

      if (response.statusCode == 200) {
        print('TRANSAKSI BERHASIL DIPERBAIKIN DI BACKEND');
        
        // Refresh transaction list from API
        await fetchTransactions();
        
        // Refresh budget as well in case budget spent needs update
        await fetchBudgets();
        
        // Refresh quick stats
        await fetchQuickStats();
        
        notifyListeners();
        return true;
      } else {
        print('Gagal mengubah transaksi: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR UPDATE TRANSACTION: $e');
      return false;
    }
  }

  void addBudget(Budget budget) {
    _budgets.add(budget);
    notifyListeners();
  }

  void addInvestment(Investment investment) {
    _investments.add(investment);
    notifyListeners();
  }

  Future<void> fetchSavingsGoals() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    _isLoadingSavings = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/savings_goal/get'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('SAVINGS GOALS GET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _savingsGoals = data.map((item) => SavingsGoal.fromJson(item)).toList();
        print('BERHASIL LOAD ${_savingsGoals.length} SAVINGS GOALS');
      } else {
        print('GAGAL LOAD SAVINGS GOALS: ${response.body}');
      }
    } catch (e) {
      print('ERROR FETCH SAVINGS GOALS: $e');
    } finally {
      _isLoadingSavings = false;
      notifyListeners();
    }
  }

  Future<void> fetchSavingsGoalSummary() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/savings_goal/summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('SAVINGS SUMMARY STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _savingsSummary = SavingsSummary.fromJson(data);
        notifyListeners();
        print('BERHASIL LOAD SAVINGS SUMMARY');
      } else {
        print('GAGAL LOAD SAVINGS SUMMARY: ${response.body}');
      }
    } catch (e) {
      print('ERROR FETCH SAVINGS SUMMARY: $e');
    }
  }

  Future<bool> createSavingsGoal(String name, String description, double targetAmount, DateTime targetDate, String category) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/savings_goal/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'target_amount': targetAmount,
          'target_date': targetDate.toUtc().toIso8601String(),
          'category': category,
          'priority': 2,
        }),
      );

      print('CREATE SAVINGS GOAL STATUS: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('SAVINGS GOAL BERHASIL DITAMBAHKAN');
        await fetchSavingsGoals();
        await fetchSavingsGoalSummary();
        return true;
      } else {
        print('Gagal menambahkan savings goal: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR CREATE SAVINGS GOAL: $e');
      return false;
    }
  }

  Future<void> fetchInvestments() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    _isLoadingInvestment = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/investment/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('INVESTMENT GET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _investments = data.map((item) => Investment.fromJson(item)).toList();
        print('BERHASIL LOAD ${_investments.length} INVESTMENTS');
      } else {
        print('GAGAL LOAD INVESTMENTS: ${response.body}');
      }
    } catch (e) {
      print('ERROR FETCH INVESTMENTS: $e');
    } finally {
      _isLoadingInvestment = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvestmentSummary() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/investment/summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('INVESTMENT SUMMARY STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _investmentSummary = InvestmentSummary.fromJson(data);
        notifyListeners();
        print('BERHASIL LOAD INVESTMENT SUMMARY');
      } else {
        print('GAGAL LOAD INVESTMENT SUMMARY: ${response.body}');
      }
    } catch (e) {
      print('ERROR FETCH INVESTMENT SUMMARY: $e');
    }
  }

  Future<void> fetchPortfolio() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    _isLoadingInvestment = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/investment/portfolio'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('INVESTMENT PORTFOLIO STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        
        final List<dynamic> investmentsJson = body['investments'] ?? [];
        _investments = investmentsJson.map((item) => Investment.fromJson(item)).toList();
        
        if (body['summary'] != null) {
          _investmentSummary = InvestmentSummary.fromJson(body['summary']);
        }
        
        notifyListeners();
        print('BERHASIL LOAD PORTFOLIO: ${_investments.length} INVESTMENTS');
      } else {
        print('GAGAL LOAD PORTFOLIO: ${response.body}');
      }
    } catch (e) {
      print('ERROR FETCH PORTFOLIO: $e');
    } finally {
      _isLoadingInvestment = false;
      notifyListeners();
    }
  }

  Future<bool> createInvestment(String name, String symbol, String type, double quantity, double averageCost, double currentPrice, String exchange) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    final backendType = type.toLowerCase() == 'saham' ? 'stock' : type.toLowerCase();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/investment/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'symbol': symbol.toUpperCase(),
          'type': backendType,
          'quantity': quantity,
          'average_cost': averageCost,
          'current_price': currentPrice,
          'currency': 'IDR',
          'exchange': exchange,
          'is_active': true,
        }),
      );

      print('CREATE INVESTMENT STATUS: ${response.statusCode}');
      print('CREATE INVESTMENT BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('INVESTASI BERHASIL DITAMBAHKAN');
        await fetchInvestments();
        await fetchInvestmentSummary();
        return true;
      } else {
        print('Gagal menambahkan investasi: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR CREATE INVESTMENT: $e');
      return false;
    }
  }

  Future<bool> deleteInvestment(String id) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8000/investment/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('DELETE INVESTMENT STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('INVESTASI BERHASIL DIHAPUS');
        await fetchInvestments();
        await fetchInvestmentSummary();
        return true;
      } else {
        print('Gagal menghapus investasi: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR DELETE INVESTMENT: $e');
      return false;
    }
  }
}
