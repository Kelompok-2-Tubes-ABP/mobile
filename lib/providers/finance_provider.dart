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

  MonthlyBudget? _monthlyBudget;
  MonthlyBudget? get monthlyBudget => _monthlyBudget;

  List<MonthlyBudget> _allMonthlyBudgets = [];
  List<MonthlyBudget> get allMonthlyBudgets => _allMonthlyBudgets;

  String? _selectedMonth;
  String get selectedMonth =>
      _selectedMonth ??
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    fetchBudgets(month: month);
    notifyListeners();
  }

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
      _investments.fold(0.0, (sum, item) => sum + item.totalValue);

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
        print('FLUTTER: raw response /analytics/quick: \${response.body}');
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          _quickStats = QuickStats.fromJson(body['data']);
          print(
            'FLUTTER: parsed QuickStats: monthIncome=\${_quickStats.monthIncome}, monthSpending=\${_quickStats.monthSpending}, netWorth=\${_quickStats.netWorth}',
          );
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

    final targetMonth =
        month ??
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8000/budget/category/by-month/$targetMonth/all',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('BUDGET CATEGORY STATUS: ${response.statusCode}');
      print('BUDGET CATEGORY BODY: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded ?? [];
        _budgets = data.map((item) => Budget.fromApiJson(item)).toList();
        notifyListeners();
        print('PARSED BUDGET COUNT: ${_budgets.length}');
        print('BERHASIL LOAD ${_budgets.length} BUDGETS');
      } else {
        print('GAGAL LOAD BUDGETS: ${response.body}');
      }

      // Also fetch monthly budget
      await fetchMonthlyBudget(month: targetMonth);
    } catch (e) {
      print('ERROR BUDGET: $e');
    }
  }

  Future<void> fetchAllMonthlyBudgets() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/budget/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded ?? [];
        _allMonthlyBudgets = data
            .map((item) => MonthlyBudget.fromApiJson(item))
            .toList();
        // Sort descending by month
        _allMonthlyBudgets.sort((a, b) => b.month.compareTo(a.month));
        notifyListeners();
      }
    } catch (e) {
      print('ERROR FETCH ALL MONTHLY BUDGETS: $e');
    }
  }

  Future<void> fetchMonthlyBudget({String? month}) async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    final targetMonth =
        month ??
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8000/budget/by-month/$targetMonth/spending',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('MONTHLY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _monthlyBudget = MonthlyBudget.fromApiJson(decoded);
        notifyListeners();
      } else {
        _monthlyBudget = null;
        notifyListeners();
      }
    } catch (e) {
      print('ERROR FETCH MONTHLY BUDGET: $e');
      _monthlyBudget = null;
      notifyListeners();
    }
  }

  Future<bool> createMonthlyBudget(double limit, {String? month}) async {
    final token = await storage.read(key: 'token');
    if (token == null) return false;

    final targetMonth =
        month ??
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/budget/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'month': targetMonth, 'limit': limit}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchAllMonthlyBudgets();
        setSelectedMonth(targetMonth);
        return true;
      }
      return false;
    } catch (e) {
      print('ERROR CREATE MONTHLY BUDGET: $e');
      return false;
    }
  }

  Future<bool> createCategoryBudget(
    String category,
    double limit, {
    String? month,
  }) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    final targetMonth = month ?? selectedMonth;

    try {
      final reqBody = jsonEncode({
        'category': category,
        'limit': limit,
        'month': targetMonth,
      });
      print('REQUEST URL: http://localhost:8000/budget/category');
      print('REQUEST BODY: $reqBody');

      final response = await http.post(
        Uri.parse('http://localhost:8000/budget/category'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: reqBody,
      );

      print('RESPONSE STATUS: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');
      print('BUDGET RESPONSE JSON: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('BUDGET CREATE SUCCESS');
        print('BUDGET BERHASIL DITAMBAHKAN KE BACKEND');
        await fetchBudgets(month: targetMonth);
        return true;
      } else {
        print('BUDGET CREATE FAILED');
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

      print('BUDGET SUMMARY STATUS: ${response.statusCode}');
      print('BUDGET SUMMARY BODY: ${response.body}');
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
      final formattedDate =
          '${transaction.date.year.toString().padLeft(4, '0')}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}T00:00:00Z';
      print('FRONTEND SENT DATE: $formattedDate');

      final reqBody = jsonEncode({
        'amount': transaction.amount,
        'category': categoryToSend,
        'description': transaction.title,
        'status': 'completed',
        'date': formattedDate,
        'type': transaction.type == t.TransactionType.pemasukan
            ? 'income'
            : 'outcome',
      });
      print('REQUEST BODY: $reqBody');

      final response = await http.post(
        Uri.parse('http://localhost:8000/transaction/new'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: reqBody,
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
      final url = 'http://localhost:8000/transaction/delete/$id';
      print('DELETE ID: $id');
      print('DELETE URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('DELETE RESPONSE: ${response.statusCode}');
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
      final formattedDate =
          '${transaction.date.year.toString().padLeft(4, '0')}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}T00:00:00Z';
      print('UPDATE FRONTEND SENT DATE: $formattedDate');
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
          'date': formattedDate,
          'type': transaction.type == t.TransactionType.pemasukan
              ? 'income'
              : 'outcome',
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

  Future<bool> createSavingsGoal(
    String name,
    String description,
    double targetAmount,
    DateTime targetDate,
    String category,
  ) async {
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
      final results = await Future.wait([
        http.get(
          Uri.parse('http://localhost:8000/investment/'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('http://localhost:8000/investment/summary'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      final responseList = results[0];
      final responseSummary = results[1];

      print('INVESTMENT GET STATUS: ${responseList.statusCode}');
      print('INVESTMENT SUMMARY STATUS: ${responseSummary.statusCode}');

      if (responseList.statusCode == 200) {
        final List<dynamic> data = jsonDecode(responseList.body);
        _investments = data.map((item) => Investment.fromJson(item)).toList();
        print('BERHASIL LOAD ${_investments.length} INVESTMENTS');
      } else {
        print('GAGAL LOAD INVESTMENTS: ${responseList.body}');
      }

      if (responseSummary.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseSummary.body);
        _investmentSummary = InvestmentSummary.fromJson(data);
        print('BERHASIL LOAD INVESTMENT SUMMARY');
      } else {
        print('GAGAL LOAD INVESTMENT SUMMARY: ${responseSummary.body}');
      }
    } catch (e) {
      print('ERROR FETCH PORTFOLIO: $e');
    } finally {
      _isLoadingInvestment = false;
      notifyListeners();
    }
  }

  Future<bool> createInvestment(
    String name,
    String symbol,
    String type,
    double quantity,
    double averageCost,
    double currentPrice,
    String exchange,
    String selectedCurrency,
  ) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    final backendType = type.toLowerCase() == 'saham'
        ? 'stock'
        : type.toLowerCase();

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
          'currency': '',
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

  Future<bool> buyInvestment(
    String investmentId,
    double quantity,
    double price,
    double fee,
    String currency,
    String notes,
  ) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/investment/transaction'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'investment_id': investmentId,
          'type': 'buy',
          'quantity': quantity,
          'price': price,
          'total_amount': quantity * price,
          'fee': fee,
          'currency': currency,
          'notes': notes,
        }),
      );

      print('BUY INVESTMENT TRANSACTION STATUS: ${response.statusCode}');
      print('BUY INVESTMENT TRANSACTION BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('TRANSAKSI BUY BERHASIL DITAMBAHKAN');
        await fetchPortfolio();
        return true;
      } else {
        print('Gagal menambahkan transaksi buy: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR BUY INVESTMENT: $e');
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

  // ==================== BUDGET CRUD ====================

  Future<bool> deleteMonthlyBudget(String id, String month) async {
    final token = await storage.read(key: 'token');
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8000/budget/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('DELETE MONTHLY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('MONTHLY BUDGET BERHASIL DIHAPUS');
        await fetchAllMonthlyBudgets();
        // If the deleted month was the selected one, pick another
        if (_selectedMonth == month) {
          if (_allMonthlyBudgets.isNotEmpty) {
            setSelectedMonth(_allMonthlyBudgets.first.month);
          } else {
            _selectedMonth = null;
            _monthlyBudget = null;
            _budgets = [];
            notifyListeners();
          }
        }
        return true;
      } else {
        print('GAGAL DELETE MONTHLY BUDGET: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR DELETE MONTHLY BUDGET: $e');
      return false;
    }
  }

  Future<bool> deleteCategoryBudget(String id, String month) async {
    final token = await storage.read(key: 'token');
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8000/budget/category/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('DELETE CATEGORY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('CATEGORY BUDGET BERHASIL DIHAPUS');
        await fetchBudgets(month: month);
        return true;
      } else {
        print('GAGAL DELETE CATEGORY BUDGET: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR DELETE CATEGORY BUDGET: $e');
      return false;
    }
  }

  Future<bool> updateMonthlyBudget(
    String id,
    double limit,
    String month,
  ) async {
    final token = await storage.read(key: 'token');
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('http://localhost:8000/budget/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'limit': limit}),
      );

      print('UPDATE MONTHLY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('MONTHLY BUDGET BERHASIL DIUPDATE');
        await fetchAllMonthlyBudgets();
        await fetchBudgets(month: month);
        return true;
      } else {
        print('GAGAL UPDATE MONTHLY BUDGET: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR UPDATE MONTHLY BUDGET: $e');
      return false;
    }
  }

  Future<bool> updateCategoryBudget(
    String id,
    String category,
    double limit,
    String month,
  ) async {
    final token = await storage.read(key: 'token');
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('http://localhost:8000/budget/category/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'category': category,
          'limit': limit,
          'month': month,
        }),
      );

      print('UPDATE CATEGORY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('CATEGORY BUDGET BERHASIL DIUPDATE');
        await fetchBudgets(month: month);
        return true;
      } else {
        print('GAGAL UPDATE CATEGORY BUDGET: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR UPDATE CATEGORY BUDGET: $e');
      return false;
    }
  }
}
