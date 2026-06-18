import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/app_drawer.dart';

class HutangScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HutangScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<HutangScreen> createState() => _HutangScreenState();
}

class _HutangScreenState extends State<HutangScreen> {
  static const String apiBaseUrl = 'http://172.24.217.180:8000';

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool loadingSummary = false;
  bool loadingDebts = false;
  bool loadingCreate = false;

  String? loadingPayId;
  String? loadingDeleteId;

  String summaryError = '';
  String debtsError = '';
  String actionError = '';
  String actionSuccess = '';

  DebtSummary debtSummary = DebtSummary.empty();
  List<DebtItem> debtList = [];

  String filterAktif = 'semua';

  List<DebtItem> get filteredList {
    if (filterAktif == 'semua') {
      return debtList;
    }

    return debtList.where((item) => item.type == filterAktif).toList();
  }

  double get totalPaymentWithInterest {
    return debtList
        .where((item) => item.isActive && !item.isPaidOff)
        .fold(0.0, (total, item) => total + getPaymentWithInterest(item));
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<Map<String, String>> _headers() async {
    final token = await storage.read(key: 'token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      fetchDebtSummary(),
      fetchDebts(),
    ]);
  }

  Future<void> fetchDebtSummary() async {
    if (!mounted) return;

    setState(() {
      loadingSummary = true;
      summaryError = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/debt/summary'),
        headers: await _headers(),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      print('DEBT SUMMARY STATUS: ${response.statusCode}');
      print('DEBT SUMMARY BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal mengambil summary hutang',
        );
      }

      if (!mounted) return;

      setState(() {
        debtSummary = DebtSummary.fromJson(data);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        summaryError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingSummary = false;
        });
      }
    }
  }

  Future<void> fetchDebts() async {
    if (!mounted) return;

    setState(() {
      loadingDebts = true;
      debtsError = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/debt/'),
        headers: await _headers(),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : [];

      print('DEBT LIST STATUS: ${response.statusCode}');
      print('DEBT LIST BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal mengambil list hutang',
        );
      }

      if (!mounted) return;

      setState(() {
        if (data is List) {
          debtList = data.map((item) => DebtItem.fromJson(item)).toList();
        } else if (data is Map<String, dynamic>) {
          final listData = data['data'] ?? data['Message'] ?? data['message'];

          if (listData is List) {
            debtList = listData.map((item) => DebtItem.fromJson(item)).toList();
          } else {
            debtList = [];
          }
        } else {
          debtList = [];
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        debtsError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingDebts = false;
        });
      }
    }
  }

  Future<void> createDebt(Map<String, dynamic> payload) async {
    if (!mounted) return;

    setState(() {
      loadingCreate = true;
      actionError = '';
      actionSuccess = '';
    });

    try {
      print('CREATE DEBT PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/debt/'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      print('CREATE DEBT STATUS: ${response.statusCode}');
      print('CREATE DEBT BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal menambahkan hutang',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Hutang berhasil ditambahkan';
      });

      await Future.wait([
        fetchDebtSummary(),
        fetchDebts(),
      ]);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          loadingCreate = false;
        });
      }
    }
  }

  Future<void> payDebt(DebtItem item) async {
    if (item.id.isEmpty) {
      setState(() {
        actionError = 'ID hutang tidak ditemukan';
      });
      return;
    }

    final amount = getPaymentWithInterest(item);

    if (amount <= 0) {
      setState(() {
        actionError = 'Nominal pembayaran tidak valid';
      });
      return;
    }

    setState(() {
      loadingPayId = item.id;
      actionError = '';
      actionSuccess = '';
    });

    try {
      final payload = {
        'amount': amount,
      };

      print('PAY DEBT PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/debt/${item.id}/pay'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      print('PAY DEBT STATUS: ${response.statusCode}');
      print('PAY DEBT BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal melakukan pembayaran hutang',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess =
        'Pembayaran ${item.name} berhasil. Sisa bayar sudah diperbarui.';
      });

      await Future.wait([
        fetchDebtSummary(),
        fetchDebts(),
      ]);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingPayId = null;
        });
      }
    }
  }

  Future<void> deleteDebt(DebtItem item) async {
    if (item.id.isEmpty) {
      setState(() {
        actionError = 'ID hutang tidak ditemukan';
      });
      return;
    }

    setState(() {
      loadingDeleteId = item.id;
      actionError = '';
      actionSuccess = '';
    });

    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/debt/${item.id}'),
        headers: await _headers(),
      );

      dynamic data = {};
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }

      print('DELETE DEBT STATUS: ${response.statusCode}');
      print('DELETE DEBT BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal menghapus hutang',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = '${item.name} berhasil dihapus';
      });

      await Future.wait([
        fetchDebtSummary(),
        fetchDebts(),
      ]);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingDeleteId = null;
        });
      }
    }
  }

  void openPayConfirm(DebtItem item) {
    final amount = getPaymentWithInterest(item);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Konfirmasi Pembayaran'),
          content: Text(
            'Bayar cicilan ${item.name} sebesar ${formatCurrency(amount)}?\n\n'
                'Nominal ini sudah termasuk bunga ${item.interestRate}%.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                payDebt(item);
              },
              child: const Text('Bayar'),
            ),
          ],
        );
      },
    );
  }

  void openDeleteConfirm(DebtItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Hapus Hutang?'),
          content: Text(
            'Hutang "${item.name}" akan dihapus permanen. Data yang sudah dihapus tidak bisa dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteDebt(item);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void openCreateDebtSheet() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return CreateDebtSheet(
          onSubmit: createDebt,
        );
      },
    );
  }

  double getPaymentWithInterest(DebtItem item) {
    final payment = item.paymentAmount;
    final interest = item.interestRate;

    return (payment + (payment * interest / 100)).roundToDouble();
  }

  int getTenorCount(DebtItem item) {
    if (item.tenorMonths > 0) {
      return item.tenorMonths;
    }

    if (item.remainingPayments > 0) {
      return item.remainingPayments;
    }

    return 0;
  }

  int getPaidInstallments(DebtItem item) {
    final paymentWithInterest = getPaymentWithInterest(item);
    final totalPaid = item.totalPaid;

    if (paymentWithInterest <= 0) {
      return 0;
    }

    return (totalPaid / paymentWithInterest).floor();
  }

  int getRemainingPayments(DebtItem item) {
    if (item.isPaidOff) {
      return 0;
    }

    final tenor = getTenorCount(item);
    final paidInstallments = getPaidInstallments(item);

    return (tenor - paidInstallments).clamp(0, tenor);
  }

  double getTotalEstimatedPayment(DebtItem item) {
    final paymentWithInterest = getPaymentWithInterest(item);
    final tenor = getTenorCount(item);

    return paymentWithInterest * tenor;
  }

  int getProgress(DebtItem item) {
    final tenor = getTenorCount(item);
    final paidInstallments = getPaidInstallments(item);

    if (tenor <= 0) {
      return 0;
    }

    return ((paidInstallments / tenor) * 100).round().clamp(0, 100);
  }

  DateTime getValidStartDate(DebtItem item) {
    if (item.startDate != null) {
      return item.startDate!;
    }

    if (item.createdAt != null) {
      return item.createdAt!;
    }

    return DateTime.now();
  }

  DateTime addFrequencyToDate(
      DateTime dateValue,
      String frequency,
      int count,
      ) {
    final amount = count;

    if (frequency == 'weekly') {
      return dateValue.add(Duration(days: amount * 7));
    }

    if (frequency == 'yearly') {
      return DateTime(
        dateValue.year + amount,
        dateValue.month,
        dateValue.day,
      );
    }

    return DateTime(
      dateValue.year,
      dateValue.month + amount,
      dateValue.day,
    );
  }

  DateTime getComputedEndDate(DebtItem item) {
    final startDate = getValidStartDate(item);
    final tenor = getTenorCount(item);

    return addFrequencyToDate(
      startDate,
      item.paymentFrequency,
      tenor,
    );
  }

  DateTime? getComputedNextPaymentDate(DebtItem item) {
    if (item.isPaidOff) {
      return null;
    }

    final startDate = getValidStartDate(item);
    final paidInstallments = getPaidInstallments(item);
    final nextInstallmentNumber = paidInstallments + 1;

    return addFrequencyToDate(
      startDate,
      item.paymentFrequency,
      nextInstallmentNumber,
    );
  }

  int getRemainingDays(DateTime? dateValue) {
    if (dateValue == null) {
      return 0;
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final targetOnly = DateTime(
      dateValue.year,
      dateValue.month,
      dateValue.day,
    );

    final diff = targetOnly.difference(todayOnly).inDays;

    return diff > 0 ? diff : 0;
  }

  String getFrequencyLabel(String frequency) {
    if (frequency == 'monthly') return 'Bulanan';
    if (frequency == 'weekly') return 'Mingguan';
    if (frequency == 'yearly') return 'Tahunan';

    return '-';
  }

  String getTenorUnitLabel(String frequency) {
    if (frequency == 'monthly') return 'bulan';
    if (frequency == 'weekly') return 'minggu';
    if (frequency == 'yearly') return 'tahun';

    return 'periode';
  }

  String getNextPaymentLabel(String frequency) {
    if (frequency == 'monthly') return 'Pembayaran bulan berikutnya';
    if (frequency == 'weekly') return 'Pembayaran minggu berikutnya';
    if (frequency == 'yearly') return 'Pembayaran tahun berikutnya';

    return 'Pembayaran berikutnya';
  }

  String formatCurrency(double value) {
    return CurrencyFormat.convertToIdr(value);
  }

  String formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final day = value.day.toString().padLeft(2, '0');
    final month = months[value.month - 1];
    final year = value.year;

    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

      drawer: AppDrawer(
        onNavigate: widget.onNavigate,
        currentIndex: 5,
      ),

      appBar: AppBar(
        title: const Text('Hutang'),
        actions: [
          IconButton(
            onPressed: openCreateDebtSheet,
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitialData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummarySection(),
                      const SizedBox(height: 16),
                      if (summaryError.isNotEmpty)
                        _buildMessageBox(
                          summaryError,
                          AppTheme.danger,
                          Icons.error_outline,
                        ),
                      if (actionError.isNotEmpty)
                        _buildMessageBox(
                          actionError,
                          AppTheme.danger,
                          Icons.error_outline,
                        ),
                      if (actionSuccess.isNotEmpty)
                        _buildMessageBox(
                          actionSuccess,
                          AppTheme.success,
                          Icons.check_circle_outline,
                        ),
                      _buildSmallSummaryRow(),
                      const SizedBox(height: 16),
                      _buildFilterRow(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (loadingDebts)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (debtsError.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildMessageBox(
                      debtsError,
                      AppTheme.danger,
                      Icons.error_outline,
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Belum ada data hutang',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildDebtCard(filteredList[index]);
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final summaryCards = [
      _SummaryData(
        title: 'Loan',
        amount: debtSummary.loan,
        icon: Icons.account_balance,
        color: AppTheme.danger,
        loading: loadingSummary,
      ),
      _SummaryData(
        title: 'Personal',
        amount: debtSummary.personal,
        icon: Icons.person,
        color: AppTheme.primaryColor,
        loading: loadingSummary,
      ),
      _SummaryData(
        title: 'Total Hutang',
        amount: debtSummary.totalDebt,
        icon: Icons.credit_card,
        color: AppTheme.danger,
        loading: loadingSummary,
      ),
      _SummaryData(
        title: 'Cicilan + Bunga',
        amount: totalPaymentWithInterest,
        icon: Icons.payments,
        color: AppTheme.warning,
        loading: loadingDebts,
      ),
    ];

    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaryCards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildSummaryCard(summaryCards[index]);
        },
      ),
    );
  }

  Widget _buildSummaryCard(_SummaryData data) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (data.loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              formatCurrency(data.amount),
              style: TextStyle(
                color: data.color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallSummaryCard(
            title: 'Total Data',
            value: '${debtSummary.totalDebts} hutang',
            icon: Icons.list_alt,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallSummaryCard(
            title: 'Status',
            value: loadingSummary ? 'Memuat...' : 'Terupdate',
            icon: Icons.verified_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton('semua', 'Semua'),
          const SizedBox(width: 8),
          _buildFilterButton('loan', 'Loan'),
          const SizedBox(width: 8),
          _buildFilterButton('personal', 'Personal'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String value, String label) {
    final isActive = filterAktif == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();

        setState(() {
          filterAktif = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDebtCard(DebtItem item) {
    final progress = getProgress(item);
    final paymentWithInterest = getPaymentWithInterest(item);
    final nextPaymentDate = getComputedNextPaymentDate(item);
    final isLoan = item.type == 'loan';
    final isPaidOff = item.isPaidOff || item.currentBalance <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isLoan
                ? AppTheme.danger.withOpacity(0.1)
                : AppTheme.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLoan ? Icons.account_balance : Icons.person,
            color: isLoan ? AppTheme.danger : AppTheme.success,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sisa: ${formatCurrency(item.currentBalance)}',
                style: TextStyle(
                  color: item.currentBalance <= 0
                      ? AppTheme.success
                      : AppTheme.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _buildBadge(
                    isLoan ? 'LOAN' : 'PERSONAL',
                    isLoan ? AppTheme.danger : AppTheme.success,
                  ),
                  _buildBadge(
                    isPaidOff ? 'LUNAS' : 'AKTIF',
                    isPaidOff ? AppTheme.success : AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          const SizedBox(height: 4),
          _buildProgressSection(progress, isLoan),
          const SizedBox(height: 16),
          _buildImportantInfoSection(
            item: item,
            paymentWithInterest: paymentWithInterest,
            nextPaymentDate: nextPaymentDate,
            isPaidOff: isPaidOff,
          ),
          const SizedBox(height: 14),
          _buildMetaWrap(item, paymentWithInterest),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item.notes,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildActionButtons(
            item: item,
            isPaidOff: isPaidOff,
            paymentWithInterest: paymentWithInterest,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(int progress, bool isLoan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Progress Pembayaran',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$progress%',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 9,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isLoan ? AppTheme.danger : AppTheme.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportantInfoSection({
    required DebtItem item,
    required double paymentWithInterest,
    required DateTime? nextPaymentDate,
    required bool isPaidOff,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Creditor',
            item.creditor.isEmpty ? '-' : item.creditor,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Cicilan + Bunga',
            formatCurrency(paymentWithInterest),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            getNextPaymentLabel(item.paymentFrequency),
            isPaidOff
                ? 'Lunas'
                : '${formatDate(nextPaymentDate)} (${getRemainingDays(nextPaymentDate)} hari lagi)',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Mulai - Selesai',
            '${formatDate(getValidStartDate(item))} - ${formatDate(getComputedEndDate(item))}',
          ),
        ],
      ),
    );
  }

  Widget _buildMetaWrap(DebtItem item, double paymentWithInterest) {
    final metaItems = [
      _MetaData('Original', formatCurrency(item.originalAmount)),
      _MetaData('Cicilan Pokok', formatCurrency(item.paymentAmount)),
      _MetaData('Frequency', getFrequencyLabel(item.paymentFrequency)),
      _MetaData(
        'Tenor',
        '${getTenorCount(item)} ${getTenorUnitLabel(item.paymentFrequency)}',
      ),
      _MetaData('Sisa Bayar', '${getRemainingPayments(item)}x'),
      _MetaData('Bunga', '${item.interestRate}%'),
      _MetaData('Total Dibayar', formatCurrency(item.totalPaid)),
      _MetaData(
        'Estimasi Total',
        formatCurrency(getTotalEstimatedPayment(item)),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metaItems.map((meta) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 64) / 2,
          child: _buildMetaItem(meta.title, meta.value),
        );
      }).toList(),
    );
  }

  Widget _buildMetaItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required DebtItem item,
    required bool isPaidOff,
    required double paymentWithInterest,
  }) {
    return Column(
      children: [
        if (!isPaidOff)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed:
              loadingPayId == item.id ? null : () => openPayConfirm(item),
              icon: loadingPayId == item.id
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.payments, size: 18),
              label: Text(
                loadingPayId == item.id
                    ? 'Membayar...'
                    : 'Bayar ${formatCurrency(paymentWithInterest)}',
              ),
            ),
          ),
        if (!isPaidOff) const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.danger,
              side: const BorderSide(color: AppTheme.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: loadingDeleteId == item.id
                ? null
                : () => openDeleteConfirm(item),
            icon: loadingDeleteId == item.id
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.delete_outline, size: 18),
            label: Text(
              loadingDeleteId == item.id ? 'Menghapus...' : 'Hapus',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBox(String message, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateDebtSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const CreateDebtSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<CreateDebtSheet> createState() => _CreateDebtSheetState();
}

class _CreateDebtSheetState extends State<CreateDebtSheet> {
  final TextEditingController debtNameController = TextEditingController();
  final TextEditingController creditorController = TextEditingController();
  final TextEditingController paymentAmountController = TextEditingController();
  final TextEditingController tenorController = TextEditingController();
  final TextEditingController interestRateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String debtType = 'loan';
  String paymentFrequency = 'monthly';

  bool loading = false;
  String errorMessage = '';

  @override
  void dispose() {
    debtNameController.dispose();
    creditorController.dispose();
    paymentAmountController.dispose();
    tenorController.dispose();
    interestRateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  double toRupiahNumber(String value) {
    return double.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ??
        0.0;
  }

  double toDecimalNumber(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> submit() async {
    setState(() {
      errorMessage = '';
    });

    final debtName = debtNameController.text.trim();
    final creditor = creditorController.text.trim();
    final paymentAmount = toRupiahNumber(paymentAmountController.text);
    final tenor = int.tryParse(tenorController.text.trim()) ?? 0;
    final interestRate = toDecimalNumber(interestRateController.text.trim());
    final notes = notesController.text.trim();

    if (debtName.isEmpty) {
      setState(() => errorMessage = 'Nama hutang wajib diisi');
      return;
    }

    if (creditor.isEmpty) {
      setState(() => errorMessage = 'Creditor wajib diisi');
      return;
    }

    if (paymentAmount <= 0) {
      setState(() => errorMessage = 'Payment amount wajib diisi');
      return;
    }

    if (tenor <= 0) {
      setState(() => errorMessage = 'Tenor wajib diisi');
      return;
    }

    final payload = {
      'name': debtName,
      'creditor': creditor,
      'type': debtType,
      'payment_amount': paymentAmount,
      'tenor_months': tenor,
      'payment_frequency': paymentFrequency,
      'interest_rate': interestRate,
      'notes': notes,
    };

    setState(() {
      loading = true;
    });

    try {
      await widget.onSubmit(payload);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String get tenorHint {
    if (paymentFrequency == 'weekly') return 'Contoh: 12 minggu';
    if (paymentFrequency == 'yearly') return 'Contoh: 2 tahun';

    return 'Contoh: 12 bulan';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tambah Hutang',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            label: 'LOAN',
                            value: 'loan',
                            color: AppTheme.danger,
                            icon: Icons.account_balance,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeButton(
                            label: 'PERSONAL',
                            value: 'personal',
                            color: AppTheme.primaryColor,
                            icon: Icons.person,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      label: 'Nama Hutang',
                      controller: debtNameController,
                      hint: 'Contoh: Kredit HP',
                      icon: Icons.edit_note,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Creditor',
                      controller: creditorController,
                      hint: 'Contoh: Ibox',
                      icon: Icons.store,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Payment Amount',
                      controller: paymentAmountController,
                      hint: '0',
                      icon: Icons.payments,
                      prefixText: 'Rp ',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Tenor',
                            controller: tenorController,
                            hint: tenorHint,
                            icon: Icons.calendar_month,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Bunga',
                            controller: interestRateController,
                            hint: '1.2',
                            icon: Icons.percent,
                            suffixText: '%',
                            keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownFrequency(),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Notes',
                      controller: notesController,
                      hint: 'Contoh: Cicilan lewat creditor Ibox',
                      icon: Icons.notes,
                      maxLines: 3,
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : submit,
                        child: Text(loading ? 'Menyimpan...' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = debtType == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();

        setState(() {
          debtType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    String? suffixText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            prefixText: prefixText,
            suffixText: suffixText,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFrequency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Frequency',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: paymentFrequency,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.repeat),
          ),
          items: const [
            DropdownMenuItem(
              value: 'monthly',
              child: Text('Monthly'),
            ),
            DropdownMenuItem(
              value: 'weekly',
              child: Text('Weekly'),
            ),
            DropdownMenuItem(
              value: 'yearly',
              child: Text('Yearly'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              paymentFrequency = value;
            });
          },
        ),
      ],
    );
  }
}

class _SummaryData {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool loading;

  _SummaryData({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.loading,
  });
}

class _MetaData {
  final String title;
  final String value;

  _MetaData(this.title, this.value);
}

class DebtSummary {
  final double loan;
  final double personal;
  final double totalDebt;
  final int totalDebts;
  final double totalMonthlyPayment;

  DebtSummary({
    required this.loan,
    required this.personal,
    required this.totalDebt,
    required this.totalDebts,
    required this.totalMonthlyPayment,
  });

  factory DebtSummary.empty() {
    return DebtSummary(
      loan: 0,
      personal: 0,
      totalDebt: 0,
      totalDebts: 0,
      totalMonthlyPayment: 0,
    );
  }

  factory DebtSummary.fromJson(Map<String, dynamic> json) {
    final byType = json['by_type'] ?? {};

    return DebtSummary(
      loan: _toDouble(byType['loan']),
      personal: _toDouble(byType['personal']),
      totalDebt: _toDouble(json['total_debt']),
      totalDebts: _toInt(json['total_debts']),
      totalMonthlyPayment: _toDouble(json['total_monthly_payment']),
    );
  }
}

class DebtItem {
  final String id;
  final String name;
  final String creditor;
  final String type;
  final String currency;
  final double originalAmount;
  final double currentBalance;
  final double interestRate;
  final double paymentAmount;
  final String paymentFrequency;
  final double minimumPayment;
  final DateTime? nextPaymentDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final bool isActive;
  final bool isPaidOff;
  final int tenorMonths;
  final int remainingPayments;
  final double totalPaid;
  final String notes;

  DebtItem({
    required this.id,
    required this.name,
    required this.creditor,
    required this.type,
    required this.currency,
    required this.originalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.paymentAmount,
    required this.paymentFrequency,
    required this.minimumPayment,
    required this.nextPaymentDate,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.isActive,
    required this.isPaidOff,
    required this.tenorMonths,
    required this.remainingPayments,
    required this.totalPaid,
    required this.notes,
  });

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    final rawType = _readString(json, ['type', 'Type']);

    return DebtItem(
      id: _readString(json, ['id', '_id', 'ID']),
      name: _readString(json, ['name', 'Name']),
      creditor: _readString(json, ['creditor', 'Creditor']),
      type: rawType.isEmpty ? 'loan' : rawType,
      currency: _readString(json, ['currency', 'Currency']),
      originalAmount:
      _toDouble(json['original_amount'] ?? json['OriginalAmount']),
      currentBalance:
      _toDouble(json['current_balance'] ?? json['CurrentBalance']),
      interestRate: _toDouble(json['interest_rate'] ?? json['InterestRate']),
      paymentAmount:
      _toDouble(json['payment_amount'] ?? json['PaymentAmount']),
      paymentFrequency:
      _readString(json, ['payment_frequency', 'PaymentFrequency']).isEmpty
          ? 'monthly'
          : _readString(json, ['payment_frequency', 'PaymentFrequency']),
      minimumPayment:
      _toDouble(json['minimum_payment'] ?? json['MinimumPayment']),
      nextPaymentDate: _parseDate(
        json['next_payment_date'] ?? json['NextPaymentDate'],
      ),
      startDate: _parseDate(json['start_date'] ?? json['StartDate']),
      endDate: _parseDate(json['end_date'] ?? json['EndDate']),
      createdAt: _parseDate(json['created_at'] ?? json['CreatedAt']),
      isActive: _toBool(json['is_active'] ?? json['IsActive']),
      isPaidOff: _toBool(json['is_paid_off'] ?? json['IsPaidOff']),
      tenorMonths: _toInt(json['tenor_months'] ?? json['TenorMonths']),
      remainingPayments:
      _toInt(json['remaining_payments'] ?? json['RemainingPayments']),
      totalPaid: _toDouble(json['total_paid'] ?? json['TotalPaid']),
      notes: _readString(json, ['notes', 'Notes']),
    );
  }
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];

    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }

  return '';
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;

  if (value is int) return value.toDouble();
  if (value is double) return value;

  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }

  return 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;
  if (value is double) return value.toInt();

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

bool _toBool(dynamic value) {
  if (value == null) return false;

  if (value is bool) return value;

  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }

  if (value is int) {
    return value == 1;
  }

  return false;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  final text = value.toString();

  if (text.isEmpty || text == '0001-01-01T00:00:00Z') {
    return null;
  }

  try {
    final date = DateTime.parse(text).toLocal();

    if (date.year <= 1900) {
      return null;
    }

    return date;
  } catch (_) {
    return null;
  }
}