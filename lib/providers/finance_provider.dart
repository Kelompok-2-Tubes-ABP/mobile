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

  double _monthlyIncome = 0;
  double _monthlyOutcome = 0;
  double _monthlyNet = 0;

  double get monthlyIncome => _monthlyIncome;
  double get monthlyOutcome => _monthlyOutcome;
  double get monthlyNet => _monthlyNet;

  bool _isLoadingMonthlySummary = false;
  bool get isLoadingMonthlySummary => _isLoadingMonthlySummary;

  String _monthlySummaryError = '';
  String get monthlySummaryError => _monthlySummaryError;

  String? _activeMonthlySummaryMonth;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    fetchBudgets(month: month);
    notifyListeners();
  }

  String _getBackendMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[date.month - 1];
  }

  String _getBackendType(t.TransactionType type) {
    return type == t.TransactionType.pemasukan ? 'income' : 'expense';
  }

  String _mapCategoryToBackend(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return 'food';
      case 'transportasi':
        return 'transport';
      case 'belanja':
        return 'shopping';
      case 'tagihan':
        return 'bills';
      case 'kesehatan':
        return 'health';
      case 'hiburan':
        return 'entertainment';
      case 'investasi':
        return 'investment';
      case 'lainnya':
        return 'other';
      case 'gaji':
      case 'bonus':
      case 'pendapatan':
        return 'income';
      default:
        return category.toLowerCase();
    }
  }

  double _toDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  Future<void> fetchMonthlySummary({required String month}) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    _activeMonthlySummaryMonth = month;
    _isLoadingMonthlySummary = true;
    _monthlySummaryError = '';
    notifyListeners();

    try {
      final uri = Uri.parse(
        'http://172.24.217.180:8000/transaction/getMonthly',
      ).replace(
        queryParameters: {
          'month': month,
        },
      );

      print('MONTHLY SUMMARY URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('MONTHLY SUMMARY STATUS: ${response.statusCode}');
      print('MONTHLY SUMMARY BODY: ${response.body}');

      final Map<String, dynamic> data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final message = data['Message'] ?? data['message'] ?? {};

        _monthlyIncome = _toDoubleValue(message['income']);
        _monthlyOutcome = _toDoubleValue(message['outcome']);
        _monthlyNet = _toDoubleValue(message['net']);

        print('MONTHLY INCOME: $_monthlyIncome');
        print('MONTHLY OUTCOME: $_monthlyOutcome');
        print('MONTHLY NET: $_monthlyNet');
      } else {
        _monthlySummaryError =
            data['Error']?.toString() ??
                data['error']?.toString() ??
                data['message']?.toString() ??
                'Gagal mengambil summary bulanan';

        _monthlyIncome = 0;
        _monthlyOutcome = 0;
        _monthlyNet = 0;
      }
    } catch (e) {
      print('ERROR FETCH MONTHLY SUMMARY: $e');
      _monthlySummaryError =
      'Terjadi kesalahan saat mengambil summary bulanan';

      _monthlyIncome = 0;
      _monthlyOutcome = 0;
      _monthlyNet = 0;
    } finally {
      _isLoadingMonthlySummary = false;
      notifyListeners();
    }
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

  List<t.Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Investment> _investments = [];

  List<t.Transaction> get transactions {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    return [..._transactions];
  }

  List<Budget> get budgets => [..._budgets];

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
        Uri.parse('http://172.24.217.180:8000/analytics/quick'),
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
        Uri.parse('http://172.24.217.180:8000/transaction/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('FETCH TRANSACTION STATUS: ${response.statusCode}');
      print('FETCH TRANSACTION BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> transactionsJson = [];

        if (data is List) {
          transactionsJson = data;
        } else if (data is Map<String, dynamic>) {
          if (data['Transaction Retrieved Successfully!!'] is List) {
            transactionsJson = data['Transaction Retrieved Successfully!!'];
          } else if (data['Message'] is List) {
            transactionsJson = data['Message'];
          } else if (data['data'] is List) {
            transactionsJson = data['data'];
          }
        }

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
          'http://172.24.217.180:8000/budget/category/by-month/$targetMonth/all',
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
        print('BERHASIL LOAD ${_budgets.length} BUDGETS');
      } else {
        print('GAGAL LOAD BUDGETS: ${response.body}');
      }

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
        Uri.parse('http://172.24.217.180:8000/budget/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded ?? [];

        _allMonthlyBudgets = data
            .map((item) => MonthlyBudget.fromApiJson(item))
            .toList();

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
          'http://172.24.217.180:8000/budget/by-month/$targetMonth/spending',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('MONTHLY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _monthlyBudget = MonthlyBudget.fromApiJson(decoded);
      } else {
        _monthlyBudget = null;
      }

      notifyListeners();
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
        Uri.parse('http://172.24.217.180:8000/budget/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'month': targetMonth,
          'limit': limit,
        }),
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

      final response = await http.post(
        Uri.parse('http://172.24.217.180:8000/budget/category'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: reqBody,
      );

      print('CREATE CATEGORY BUDGET STATUS: ${response.statusCode}');
      print('CREATE CATEGORY BUDGET BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBudgets(month: targetMonth);
        return true;
      }

      return false;
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
        Uri.parse('http://172.24.217.180:8000/budget/summary'),
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
        Uri.parse('http://172.24.217.180:8000/budget/all-spending'),
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

    try {
      final categoryToSend = _mapCategoryToBackend(transaction.category);
      final monthToSend = _getBackendMonthName(transaction.date);
      final typeToSend = _getBackendType(transaction.type);

      final reqBody = jsonEncode({
        'amount': transaction.amount,
        'category': categoryToSend,
        'description': transaction.title,
        'month': monthToSend,
        'type': typeToSend,
      });

      print('CREATE TRANSACTION REQUEST BODY: $reqBody');

      final response = await http.post(
        Uri.parse('http://172.24.217.180:8000/transaction/new'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: reqBody,
      );

      print('CREATE TRANSACTION STATUS: ${response.statusCode}');
      print('CREATE TRANSACTION BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTransactions();

        if (_activeMonthlySummaryMonth != null) {
          await fetchMonthlySummary(month: _activeMonthlySummaryMonth!);
        } else {
          await fetchMonthlySummary(month: monthToSend);
        }

        await fetchQuickStats();

        notifyListeners();
        return true;
      }

      return false;
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

    if (id.isEmpty) {
      print('DELETE TRANSACTION GAGAL: ID kosong');
      return false;
    }

    try {
      final url = 'http://172.24.217.180:8000/transaction/delete/$id';

      print('DELETE TRANSACTION ID: $id');
      print('DELETE TRANSACTION URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request delete transaction timeout');
        },
      );

      print('DELETE TRANSACTION STATUS: ${response.statusCode}');
      print('DELETE TRANSACTION BODY: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _transactions.removeWhere((tx) => tx.id == id);
        notifyListeners();

        Future.microtask(() async {
          try {
            await fetchTransactions();

            if (_activeMonthlySummaryMonth != null) {
              await fetchMonthlySummary(month: _activeMonthlySummaryMonth!);
            }

            await fetchQuickStats();
          } catch (e) {
            print('ERROR REFRESH AFTER DELETE TRANSACTION: $e');
          }
        });

        return true;
      }

      return false;
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

    try {
      final categoryToSend = _mapCategoryToBackend(transaction.category);
      final monthToSend = _getBackendMonthName(transaction.date);
      final typeToSend = _getBackendType(transaction.type);

      final response = await http.patch(
        Uri.parse('http://172.24.217.180:8000/transaction/update/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': transaction.amount,
          'category': categoryToSend,
          'description': transaction.title,
          'month': monthToSend,
          'type': typeToSend,
        }),
      );

      print('UPDATE TRANSACTION STATUS: ${response.statusCode}');
      print('UPDATE TRANSACTION BODY: ${response.body}');

      if (response.statusCode == 200) {
        await fetchTransactions();

        if (_activeMonthlySummaryMonth != null) {
          await fetchMonthlySummary(month: _activeMonthlySummaryMonth!);
        } else {
          await fetchMonthlySummary(month: monthToSend);
        }

        await fetchQuickStats();

        notifyListeners();
        return true;
      }

      return false;
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
        Uri.parse('http://172.24.217.180:8000/savings_goal/get'),
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
        Uri.parse('http://172.24.217.180:8000/savings_goal/summary'),
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
        Uri.parse('http://172.24.217.180:8000/savings_goal/'),
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
        await fetchSavingsGoals();
        await fetchSavingsGoalSummary();
        return true;
      }

      return false;
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
        Uri.parse('http://172.24.217.180:8000/investment/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('INVESTMENT GET STATUS: ${response.statusCode}');
      print('INVESTMENT GET BODY: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data = [];

        if (decoded is List) {
          data = decoded;
        } else if (decoded == null) {
          data = [];
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['investments'] is List) {
            data = decoded['investments'];
          } else if (decoded['Investment Retrieved Successfully!!'] is List) {
            data = decoded['Investment Retrieved Successfully!!'];
          }
        }

        _investments = data.map((item) => Investment.fromJson(item)).toList();
        print('BERHASIL LOAD ${_investments.length} INVESTMENTS');
      } else {
        _investments = [];
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
        Uri.parse('http://172.24.217.180:8000/investment/summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('INVESTMENT SUMMARY STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _investmentSummary = InvestmentSummary.fromJson(data);
        notifyListeners();
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
          Uri.parse('http://172.24.217.180:8000/investment/'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('http://172.24.217.180:8000/investment/summary'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      final responseList = results[0];
      final responseSummary = results[1];

      if (responseList.statusCode == 200) {
        final decoded = jsonDecode(responseList.body);

        List<dynamic> data = [];

        if (decoded is List) {
          data = decoded;
        } else if (decoded == null) {
          data = [];
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['investments'] is List) {
            data = decoded['investments'];
          } else if (decoded['Investment Retrieved Successfully!!'] is List) {
            data = decoded['Investment Retrieved Successfully!!'];
          }
        }

        _investments = data.map((item) => Investment.fromJson(item)).toList();
      } else {
        _investments = [];
      }

      if (responseSummary.statusCode == 200) {
        final decodedSummary = jsonDecode(responseSummary.body);

        if (decodedSummary is Map<String, dynamic>) {
          _investmentSummary = InvestmentSummary.fromJson(decodedSummary);
        } else {
          _investmentSummary = InvestmentSummary.empty();
        }
      } else {
        _investmentSummary = InvestmentSummary.empty();
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

    final backendType =
    type.toLowerCase() == 'saham' ? 'stock' : type.toLowerCase();

    try {
      final response = await http.post(
        Uri.parse('http://172.24.217.180:8000/investment/'),
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
        await fetchInvestments();
        await fetchInvestmentSummary();
        return true;
      }

      return false;
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
        Uri.parse('http://172.24.217.180:8000/investment/transaction'),
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
        await fetchPortfolio();
        return true;
      }

      return false;
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

    if (id.isEmpty) {
      print('DELETE INVESTMENT GAGAL: ID kosong');
      return false;
    }

    try {
      final url = 'http://172.24.217.180:8000/investment/$id';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('DELETE INVESTMENT STATUS: ${response.statusCode}');
      print('DELETE INVESTMENT BODY: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _investments.removeWhere((item) => item.id == id);
        notifyListeners();

        await fetchPortfolio();

        return true;
      }

      return false;
    } catch (e) {
      print('ERROR DELETE INVESTMENT: $e');
      return false;
    }
  }

  Future<bool> deleteMonthlyBudget(String id, String month) async {
    final token = await storage.read(key: 'token');
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('http://172.24.217.180:8000/budget/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('DELETE MONTHLY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        await fetchAllMonthlyBudgets();

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
      }

      return false;
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
        Uri.parse('http://172.24.217.180:8000/budget/category/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('DELETE CATEGORY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        await fetchBudgets(month: month);
        return true;
      }

      return false;
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
        Uri.parse('http://172.24.217.180:8000/budget/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'limit': limit,
        }),
      );

      print('UPDATE MONTHLY BUDGET STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        await fetchAllMonthlyBudgets();
        await fetchBudgets(month: month);
        return true;
      }

      return false;
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
        Uri.parse('http://172.24.217.180:8000/budget/category/$id'),
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
        await fetchBudgets(month: month);
        return true;
      }

      return false;
    } catch (e) {
      print('ERROR UPDATE CATEGORY BUDGET: $e');
      return false;
    }
  }
}