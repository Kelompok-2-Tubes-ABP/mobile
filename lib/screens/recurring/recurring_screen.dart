import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/app_drawer.dart';

class RecurringScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const RecurringScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  static const String apiBaseUrl = 'http://172.24.217.180:8000';

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool loadingSummary = false;
  bool loadingList = false;
  bool loadingCreate = false;
  bool loadingUpdate = false;

  String? loadingActionId;

  String summaryError = '';
  String listError = '';
  String actionError = '';
  String actionSuccess = '';

  RecurringSummary recurringSummary = RecurringSummary.empty();
  List<RecurringItem> recurringList = [];

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
      fetchRecurringSummary(),
      fetchRecurringList(),
    ]);
  }

  Future<void> fetchRecurringSummary() async {
    if (!mounted) return;

    setState(() {
      loadingSummary = true;
      summaryError = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/recurring/summary'),
        headers: await _headers(),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      print('RECURRING SUMMARY STATUS: ${response.statusCode}');
      print('RECURRING SUMMARY BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal mengambil summary recurring',
        );
      }

      if (!mounted) return;

      setState(() {
        recurringSummary = RecurringSummary.fromJson(data);
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

  Future<void> fetchRecurringList() async {
    if (!mounted) return;

    setState(() {
      loadingList = true;
      listError = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/recurring/'),
        headers: await _headers(),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : [];

      print('RECURRING LIST STATUS: ${response.statusCode}');
      print('RECURRING LIST BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal mengambil list recurring',
        );
      }

      if (!mounted) return;

      setState(() {
        if (data is List) {
          recurringList =
              data.map((item) => RecurringItem.fromJson(item)).toList();
        } else if (data is Map<String, dynamic>) {
          final listData = data['data'] ??
              data['Message'] ??
              data['message'] ??
              data['Recurring Retrieved Successfully!!'];

          if (listData is List) {
            recurringList =
                listData.map((item) => RecurringItem.fromJson(item)).toList();
          } else {
            recurringList = [];
          }
        } else {
          recurringList = [];
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        listError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingList = false;
        });
      }
    }
  }

  Future<void> createRecurring(Map<String, dynamic> payload) async {
    if (!mounted) return;

    setState(() {
      loadingCreate = true;
      actionError = '';
      actionSuccess = '';
    });

    try {
      print('CREATE RECURRING PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/recurring/'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      print('CREATE RECURRING STATUS: ${response.statusCode}');
      print('CREATE RECURRING BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal menambahkan recurring',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Recurring berhasil ditambahkan';
      });

      await Future.wait([
        fetchRecurringSummary(),
        fetchRecurringList(),
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

  Future<void> updateRecurring(
      String id,
      Map<String, dynamic> payload,
      ) async {
    if (id.isEmpty) {
      setState(() {
        actionError = 'ID recurring tidak ditemukan';
      });
      return;
    }

    setState(() {
      loadingUpdate = true;
      actionError = '';
      actionSuccess = '';
    });

    try {
      print('UPDATE RECURRING PAYLOAD: $payload');

      final response = await http.patch(
        Uri.parse('$apiBaseUrl/recurring/$id'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      print('UPDATE RECURRING STATUS: ${response.statusCode}');
      print('UPDATE RECURRING BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal update recurring',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Recurring berhasil diupdate';
      });

      await Future.wait([
        fetchRecurringSummary(),
        fetchRecurringList(),
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
          loadingUpdate = false;
        });
      }
    }
  }

  Future<void> toggleRecurringStatus(RecurringItem item) async {
    if (item.id.isEmpty) {
      setState(() {
        actionError = 'ID recurring tidak ditemukan';
      });
      return;
    }

    final action = item.isActive ? 'pause' : 'resume';

    setState(() {
      loadingActionId = item.id;
      actionError = '';
      actionSuccess = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/recurring/${item.id}/$action'),
        headers: await _headers(),
      );

      final text = response.body;
      final data = text.isNotEmpty ? jsonDecode(text) : {};

      print('TOGGLE RECURRING STATUS: ${response.statusCode}');
      print('TOGGLE RECURRING BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal $action recurring',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = item.isActive
            ? 'Recurring berhasil dipause'
            : 'Recurring berhasil diresume';
      });

      await Future.wait([
        fetchRecurringSummary(),
        fetchRecurringList(),
      ]);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingActionId = null;
        });
      }
    }
  }

  Future<void> deleteRecurring(RecurringItem item) async {
    if (item.id.isEmpty) {
      setState(() {
        actionError = 'ID recurring tidak ditemukan';
      });
      return;
    }

    setState(() {
      loadingActionId = item.id;
      actionError = '';
      actionSuccess = '';
    });

    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/recurring/${item.id}'),
        headers: await _headers(),
      );

      final text = response.body;
      final data = text.isNotEmpty ? jsonDecode(text) : {};

      print('DELETE RECURRING STATUS: ${response.statusCode}');
      print('DELETE RECURRING BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal menghapus recurring',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Recurring berhasil dihapus';
      });

      await Future.wait([
        fetchRecurringSummary(),
        fetchRecurringList(),
      ]);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingActionId = null;
        });
      }
    }
  }

  void openCreateRecurringSheet() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return RecurringFormSheet(
          mode: RecurringFormMode.create,
          onSubmit: (payload) async {
            await createRecurring(payload);
          },
        );
      },
    );
  }

  void openEditRecurringSheet(RecurringItem item) {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return RecurringFormSheet(
          mode: RecurringFormMode.edit,
          item: item,
          isActionLoading: loadingActionId == item.id,
          onSubmit: (payload) async {
            await updateRecurring(item.id, payload);
          },
          onToggleStatus: () {
            Navigator.pop(context);
            toggleRecurringStatus(item);
          },
          onDelete: () {
            Navigator.pop(context);
            openDeleteConfirm(item);
          },
        );
      },
    );
  }

  void openDeleteConfirm(RecurringItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Hapus Recurring?'),
          content: Text(
            'Transaksi berulang "${item.name}" akan dihapus permanen dan tidak bisa dikembalikan.',
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
                deleteRecurring(item);
              },
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }

  DateTime getValidStartDate(RecurringItem item) {
    if (item.startDate != null) return item.startDate!;
    if (item.createdAt != null) return item.createdAt!;

    return DateTime.now();
  }

  DateTime addIntervalByFrequency(
      DateTime dateValue,
      String frequency,
      int interval,
      ) {
    final finalInterval = interval <= 0 ? 1 : interval;

    if (frequency == 'daily') {
      return dateValue.add(Duration(days: finalInterval));
    }

    if (frequency == 'weekly') {
      return dateValue.add(Duration(days: finalInterval * 7));
    }

    if (frequency == 'yearly') {
      return DateTime(
        dateValue.year + finalInterval,
        dateValue.month,
        dateValue.day,
      );
    }

    return DateTime(
      dateValue.year,
      dateValue.month + finalInterval,
      dateValue.day,
    );
  }

  DateTime getComputedNextRunDate(RecurringItem item) {
    final startDate = getValidStartDate(item);

    return addIntervalByFrequency(
      startDate,
      item.frequency,
      item.interval,
    );
  }

  String getTypeLabel(String value) {
    if (value == 'income') return 'PEMASUKAN';
    if (value == 'outcome') return 'PENGELUARAN';

    return value.isEmpty ? '-' : value;
  }

  String getFrequencyLabel(String value) {
    if (value == 'daily') return 'Harian';
    if (value == 'weekly') return 'Mingguan';
    if (value == 'monthly') return 'Bulanan';
    if (value == 'yearly') return 'Tahunan';

    return value.isEmpty ? '-' : value;
  }

  String getIntervalLabel(RecurringItem item) {
    final value = item.interval <= 0 ? 1 : item.interval;

    if (item.frequency == 'daily') return '$value hari sekali';
    if (item.frequency == 'weekly') return '$value minggu sekali';
    if (item.frequency == 'monthly') return '$value bulan sekali';
    if (item.frequency == 'yearly') return '$value tahun sekali';

    return '$value interval';
  }

  String formatCurrency(double value) {
    return CurrencyFormat.convertToIdr(value);
  }

  String formatDate(DateTime? value) {
    if (value == null) return '-';

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
        currentIndex: 6,
      ),

      appBar: AppBar(
        title: const Text('Transaksi Berulang'),
        actions: [
          IconButton(
            onPressed: openCreateRecurringSheet,
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
                      _buildHeaderInfo(),
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Daftar Recurring',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (loadingList)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (listError.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildMessageBox(
                      listError,
                      AppTheme.danger,
                      Icons.error_outline,
                    ),
                  ),
                )
              else if (recurringList.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Belum ada transaksi berulang',
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
                      itemCount: recurringList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildRecurringCard(recurringList[index]);
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.repeat,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: loadingSummary
                ? const Text(
              'Mengambil summary recurring...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Recurring',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${recurringSummary.activeCount} aktif • '
                      '${recurringSummary.pausedCount} pause • '
                      '${recurringSummary.totalRecurring} total',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final cards = [
      _SummaryData(
        title: 'Monthly Expenses',
        amount: recurringSummary.monthlyExpenses,
        icon: Icons.arrow_downward,
        color: AppTheme.danger,
        loading: loadingSummary,
      ),
      _SummaryData(
        title: 'Monthly Income',
        amount: recurringSummary.monthlyIncome,
        icon: Icons.arrow_upward,
        color: AppTheme.success,
        loading: loadingSummary,
      ),
      _SummaryData(
        title: 'Net Cashflow',
        amount: recurringSummary.netMonthlyCashflow,
        icon: Icons.account_balance_wallet_outlined,
        color: recurringSummary.netMonthlyCashflow >= 0
            ? AppTheme.success
            : AppTheme.danger,
        loading: loadingSummary,
      ),
      _SummaryData(
        title: 'Total Recurring',
        amount: recurringSummary.totalRecurring.toDouble(),
        icon: Icons.repeat,
        color: AppTheme.primaryColor,
        loading: loadingSummary,
        isCount: true,
      ),
    ];

    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildSummaryCard(cards[index]);
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
              data.isCount
                  ? data.amount.toInt().toString()
                  : formatCurrency(data.amount),
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

  Widget _buildRecurringCard(RecurringItem item) {
    final isIncome = item.type == 'income';
    final amountColor = isIncome ? AppTheme.success : AppTheme.danger;
    final amountPrefix = isIncome ? '+' : '-';
    final nextRunDate = getComputedNextRunDate(item);

    return Opacity(
      opacity: item.isActive ? 1 : 0.58,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openEditRecurringSheet(item),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.repeat,
                  color: amountColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _buildBadge(
                          getTypeLabel(item.type),
                          amountColor,
                        ),
                        _buildBadge(
                          getFrequencyLabel(item.frequency),
                          AppTheme.primaryColor,
                        ),
                        _buildBadge(
                          item.isActive ? 'AKTIF' : 'PAUSE',
                          item.isActive
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.category.isEmpty ? '-' : item.category,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.note,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Berikutnya: ${formatDate(nextRunDate)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix${formatCurrency(item.amount.abs())}',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    getIntervalLabel(item),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

enum RecurringFormMode { create, edit }

class RecurringFormSheet extends StatefulWidget {
  final RecurringFormMode mode;
  final RecurringItem? item;
  final bool isActionLoading;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  const RecurringFormSheet({
    super.key,
    required this.mode,
    this.item,
    this.isActionLoading = false,
    required this.onSubmit,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  State<RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends State<RecurringFormSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController accountIdController = TextEditingController();
  final TextEditingController intervalController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String type = 'outcome';
  String frequency = 'monthly';

  bool loading = false;
  String errorMessage = '';

  bool get isEdit => widget.mode == RecurringFormMode.edit;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    if (item != null) {
      nameController.text = item.name;
      amountController.text = item.amount.toStringAsFixed(0);
      categoryController.text = item.category;
      accountIdController.text = item.accountId;
      intervalController.text = item.interval.toString();
      noteController.text = item.note;
      type = item.type.isEmpty ? 'outcome' : item.type;
      frequency = item.frequency.isEmpty ? 'monthly' : item.frequency;
    } else {
      intervalController.text = '1';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    categoryController.dispose();
    accountIdController.dispose();
    intervalController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double cleanRupiah(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
  }

  Future<void> submit() async {
    setState(() {
      errorMessage = '';
    });

    final name = nameController.text.trim();
    final amount = cleanRupiah(amountController.text);
    final category = categoryController.text.trim();
    final accountId = accountIdController.text.trim();
    final interval = int.tryParse(intervalController.text.trim()) ?? 0;
    final note = noteController.text.trim();

    if (name.isEmpty) {
      setState(() => errorMessage = 'Nama recurring wajib diisi');
      return;
    }

    if (amount <= 0) {
      setState(() => errorMessage = 'Jumlah wajib diisi');
      return;
    }

    if (category.isEmpty) {
      setState(() => errorMessage = 'Kategori wajib diisi');
      return;
    }

    if (interval <= 0) {
      setState(() => errorMessage = 'Interval harus lebih dari 0');
      return;
    }

    final payload = {
      'name': name,
      'amount': amount,
      'type': type,
      'category': category,
      'account_id': accountId,
      'frequency': frequency,
      'interval': interval,
      'note': note,
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
                    Expanded(
                      child: Text(
                        isEdit
                            ? 'Edit Transaksi Berulang'
                            : 'Tambah Transaksi Berulang',
                        style: const TextStyle(
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
                    if (isEdit && widget.item != null) ...[
                      _buildSelectedInfo(widget.item!),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField(
                      label: 'Nama',
                      controller: nameController,
                      hint: 'Contoh: Langganan Netflix',
                      icon: Icons.repeat,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Jumlah',
                      controller: amountController,
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
                          child: _buildTypeButton(
                            label: 'Pengeluaran',
                            value: 'outcome',
                            color: AppTheme.danger,
                            icon: Icons.arrow_downward,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeButton(
                            label: 'Pemasukan',
                            value: 'income',
                            color: AppTheme.success,
                            icon: Icons.arrow_upward,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Kategori',
                      controller: categoryController,
                      hint: 'Contoh: Entertainment',
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Account ID',
                      controller: accountIdController,
                      hint: 'Opsional',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildFrequencyPicker(),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Interval',
                      controller: intervalController,
                      hint: 'Contoh: 1',
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Note',
                      controller: noteController,
                      hint: 'Contoh: Paket Premium 4K',
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
                        child: Text(
                          loading
                              ? isEdit
                              ? 'Mengupdate...'
                              : 'Menyimpan...'
                              : isEdit
                              ? 'Update Transaksi'
                              : 'Simpan Transaksi',
                        ),
                      ),
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: widget.isActionLoading
                              ? null
                              : widget.onToggleStatus,
                          icon: Icon(
                            widget.item?.isActive == true
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            widget.item?.isActive == true
                                ? 'Pause Recurring'
                                : 'Resume Recurring',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: const BorderSide(color: AppTheme.danger),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed:
                          widget.isActionLoading ? null : widget.onDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus Recurring'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedInfo(RecurringItem item) {
    final isIncome = item.type == 'income';
    final color = isIncome ? AppTheme.success : AppTheme.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${item.name}\n${isIncome ? 'PEMASUKAN' : 'PENGELUARAN'} • ${item.frequency} • ${item.interval}x',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: item.isActive
                  ? AppTheme.success.withOpacity(0.12)
                  : AppTheme.textSecondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.isActive ? 'AKTIF' : 'PAUSE',
              style: TextStyle(
                color:
                item.isActive ? AppTheme.success : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = type == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();

        setState(() {
          type = value;
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
              size: 16,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyPicker() {
    final items = [
      _FrequencyData('daily', 'Daily'),
      _FrequencyData('weekly', 'Weekly'),
      _FrequencyData('monthly', 'Monthly'),
      _FrequencyData('yearly', 'Yearly'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = frequency == item.value;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();

                setState(() {
                  frequency = item.value;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                  isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          ),
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
  final bool isCount;

  _SummaryData({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.loading,
    this.isCount = false,
  });
}

class _FrequencyData {
  final String value;
  final String label;

  _FrequencyData(this.value, this.label);
}

class RecurringSummary {
  final int activeCount;
  final double monthlyExpenses;
  final double monthlyIncome;
  final double netMonthlyCashflow;
  final int pausedCount;
  final int totalRecurring;

  RecurringSummary({
    required this.activeCount,
    required this.monthlyExpenses,
    required this.monthlyIncome,
    required this.netMonthlyCashflow,
    required this.pausedCount,
    required this.totalRecurring,
  });

  factory RecurringSummary.empty() {
    return RecurringSummary(
      activeCount: 0,
      monthlyExpenses: 0,
      monthlyIncome: 0,
      netMonthlyCashflow: 0,
      pausedCount: 0,
      totalRecurring: 0,
    );
  }

  factory RecurringSummary.fromJson(Map<String, dynamic> json) {
    return RecurringSummary(
      activeCount: _toInt(json['active_count']),
      monthlyExpenses: _toDouble(json['monthly_expenses']),
      monthlyIncome: _toDouble(json['monthly_income']),
      netMonthlyCashflow: _toDouble(json['net_monthly_cashflow']),
      pausedCount: _toInt(json['paused_count']),
      totalRecurring: _toInt(json['total_recurring']),
    );
  }
}

class RecurringItem {
  final String id;
  final String name;
  final double amount;
  final String type;
  final String category;
  final String accountId;
  final String frequency;
  final int interval;
  final String note;
  final String description;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? createdAt;

  RecurringItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.category,
    required this.accountId,
    required this.frequency,
    required this.interval,
    required this.note,
    required this.description,
    required this.isActive,
    required this.startDate,
    required this.createdAt,
  });

  factory RecurringItem.fromJson(Map<String, dynamic> json) {
    final rawNote = _readString(json, ['note', 'Note']);
    final rawDescription = _readString(json, ['description', 'Description']);

    return RecurringItem(
      id: _readString(json, ['id', '_id', 'ID']),
      name: _readString(json, ['name', 'Name']),
      amount: _toDouble(json['amount'] ?? json['Amount']),
      type: _readString(json, ['type', 'Type']).isEmpty
          ? 'outcome'
          : _readString(json, ['type', 'Type']),
      category: _readString(json, ['category', 'Category']),
      accountId: _readString(json, ['account_id', 'accountId', 'AccountID']),
      frequency: _readString(json, ['frequency', 'Frequency']).isEmpty
          ? 'monthly'
          : _readString(json, ['frequency', 'Frequency']),
      interval: _toInt(json['interval'] ?? json['Interval']) <= 0
          ? 1
          : _toInt(json['interval'] ?? json['Interval']),
      note: rawNote.isNotEmpty ? rawNote : rawDescription,
      description: rawDescription,
      isActive:
      _toBool(json['is_active'] ?? json['isActive'] ?? json['IsActive']),
      startDate: _parseDate(json['start_date'] ?? json['startDate']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
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