import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/app_drawer.dart';

class BillScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const BillScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  static const String apiBaseUrl = 'http://172.24.217.180:8000';

  static const String defaultBillIcon = 'bill';
  static const String defaultBillColor = '#4f46e5';

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool loadingBills = false;
  bool loadingBillDetail = false;
  bool savingBill = false;

  String? loadingPayId;
  String? loadingDeleteId;

  String listError = '';
  String actionError = '';
  String actionSuccess = '';

  String filterAktif = 'semua';

  List<BillItem> billList = [];

  final List<String> categories = const [
    'Utilities',
    'Internet',
    'Electricity',
    'Water',
    'Streaming',
    'Phone',
    'Rent',
    'Insurance',
    'Education',
    'Other',
  ];

  final List<BillCycleOption> billingCycles = const [
    BillCycleOption(label: 'Monthly', value: 'monthly'),
    BillCycleOption(label: 'Weekly', value: 'weekly'),
    BillCycleOption(label: 'Yearly', value: 'yearly'),
  ];

  @override
  void initState() {
    super.initState();
    fetchBills();
  }

  Future<Map<String, String>> _headers() async {
    final token = await storage.read(key: 'token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeResponseBody(String text) {
    if (text.trim().isEmpty) return {};

    try {
      return jsonDecode(text);
    } catch (_) {
      return {
        'message': text,
      };
    }
  }

  List<BillItem> get filteredBills {
    if (filterAktif == 'semua') return billList;

    if (filterAktif == 'belum') {
      return billList.where((item) {
        return !item.isPaid && !isOverdue(item);
      }).toList();
    }

    if (filterAktif == 'sudah') {
      return billList.where((item) => item.isPaid).toList();
    }

    return billList.where((item) {
      return !item.isPaid && isOverdue(item);
    }).toList();
  }

  int get dueThisWeek {
    return billList.where((item) {
      if (item.isPaid) return false;

      final days = getRemainingDays(item.nextDueDate);
      return days >= 0 && days <= 7;
    }).length;
  }

  Future<void> fetchBills() async {
    if (!mounted) return;

    setState(() {
      loadingBills = true;
      listError = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/bill/'),
        headers: await _headers(),
      );

      final data = _decodeResponseBody(response.body);

      print('BILL LIST STATUS: ${response.statusCode}');
      print('BILL LIST BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal mengambil list bill',
        );
      }

      if (!mounted) return;

      setState(() {
        if (data is List) {
          billList = data.map((item) => BillItem.fromJson(item)).toList();
        } else if (data is Map<String, dynamic>) {
          final listData = data['data'] ??
              data['Message'] ??
              data['message'] ??
              data['bills'] ??
              data['Bills'];

          if (listData is List) {
            billList = listData.map((item) => BillItem.fromJson(item)).toList();
          } else {
            billList = [];
          }
        } else {
          billList = [];
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        listError = e.toString().replaceAll('Exception: ', '');
        billList = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingBills = false;
        });
      }
    }
  }

  Future<BillItem?> fetchBillDetail(BillItem fallback) async {
    final billId = fallback.id;

    if (billId.isEmpty) {
      setState(() {
        listError = 'ID bill tidak ditemukan';
      });
      return null;
    }

    setState(() {
      loadingBillDetail = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/bill/$billId'),
        headers: await _headers(),
      );

      final data = _decodeResponseBody(response.body);

      print('BILL DETAIL STATUS: ${response.statusCode}');
      print('BILL DETAIL BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal mengambil detail bill',
        );
      }

      final detail = normalizeBillDetail(data, fallback);
      return detail;
    } catch (e) {
      if (!mounted) return fallback;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );

      return fallback;
    } finally {
      if (mounted) {
        setState(() {
          loadingBillDetail = false;
        });
      }
    }
  }

  BillItem normalizeBillDetail(dynamic data, BillItem fallback) {
    dynamic raw = data;

    if (data is Map<String, dynamic>) {
      raw = data['bill'] ??
          data['data'] ??
          data['Message'] ??
          data['message'] ??
          data;
    }

    if (raw is Map<String, dynamic>) {
      final detail = BillItem.fromJson(raw);

      return detail.copyWith(
        id: detail.id.isNotEmpty ? detail.id : fallback.id,
        name: detail.name.isNotEmpty ? detail.name : fallback.name,
        description: detail.description.isNotEmpty
            ? detail.description
            : fallback.description,
        amount: detail.amount > 0 ? detail.amount : fallback.amount,
        currency: detail.currency.isNotEmpty ? detail.currency : fallback.currency,
        category: detail.category.isNotEmpty ? detail.category : fallback.category,
        payTo: detail.payTo.isNotEmpty ? detail.payTo : fallback.payTo,
        billingCycle: detail.billingCycle.isNotEmpty
            ? detail.billingCycle
            : fallback.billingCycle,
        dayOfMonth: detail.dayOfMonth > 0
            ? detail.dayOfMonth
            : fallback.dayOfMonth,
        remindDaysBefore: detail.remindDaysBefore,
        isPaid: detail.isPaid,
        nextDueDate: detail.nextDueDate ?? fallback.nextDueDate,
        createdAt: detail.createdAt ?? fallback.createdAt,
        updatedAt: detail.updatedAt ?? fallback.updatedAt,
      );
    }

    return fallback;
  }

  Future<void> createBill(Map<String, dynamic> payload) async {
    setState(() {
      savingBill = true;
      actionError = '';
      actionSuccess = '';
    });

    try {
      print('CREATE BILL PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/bill/'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      final data = _decodeResponseBody(response.body);

      print('CREATE BILL STATUS: ${response.statusCode}');
      print('CREATE BILL BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal menambahkan bill',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Bill berhasil ditambahkan';
      });

      await fetchBills();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          savingBill = false;
        });
      }
    }
  }

  Future<void> updateBill(String id, Map<String, dynamic> payload) async {
    if (id.isEmpty) {
      setState(() {
        actionError = 'ID bill tidak ditemukan';
      });
      return;
    }

    setState(() {
      savingBill = true;
      actionError = '';
      actionSuccess = '';
    });

    try {
      print('UPDATE BILL ID: $id');
      print('UPDATE BILL PAYLOAD: $payload');

      final response = await http.patch(
        Uri.parse('$apiBaseUrl/bill/$id'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      final data = _decodeResponseBody(response.body);

      print('UPDATE BILL STATUS: ${response.statusCode}');
      print('UPDATE BILL BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal mengupdate bill',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Bill berhasil diupdate';
      });

      await fetchBills();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          savingBill = false;
        });
      }
    }
  }

  Future<void> payBill(BillItem item) async {
    if (item.id.isEmpty) {
      setState(() {
        actionError = 'ID bill tidak ditemukan';
      });
      return;
    }

    if (item.amount <= 0) {
      setState(() {
        actionError = 'Amount bill tidak valid';
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
        'amount': item.amount,
      };

      print('PAY BILL ID: ${item.id}');
      print('PAY BILL PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/bill/${item.id}/pay'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      final data = _decodeResponseBody(response.body);

      print('PAY BILL STATUS: ${response.statusCode}');
      print('PAY BILL BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal membayar tagihan',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Tagihan berhasil ditandai sudah dibayar';

        billList = billList.map((bill) {
          if (bill.id == item.id) {
            return bill.copyWith(isPaid: true);
          }

          return bill;
        }).toList();
      });

      await fetchBills();
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

  Future<void> deleteBill(BillItem item) async {
    if (item.id.isEmpty) {
      setState(() {
        actionError = 'ID bill tidak ditemukan';
      });
      return;
    }

    setState(() {
      loadingDeleteId = item.id;
      actionError = '';
      actionSuccess = '';
    });

    try {
      print('DELETE BILL ID: ${item.id}');

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/bill/${item.id}'),
        headers: await _headers(),
      );

      final data = _decodeResponseBody(response.body);

      print('DELETE BILL STATUS: ${response.statusCode}');
      print('DELETE BILL BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              data['error'] ??
              data['Error'] ??
              'Gagal menghapus bill',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = '${item.name} berhasil dihapus';
        billList = billList.where((bill) => bill.id != item.id).toList();
      });

      await fetchBills();
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

  void openAddBillSheet() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BillFormSheet(
          mode: BillFormMode.add,
          categories: categories,
          billingCycles: billingCycles,
          onSubmit: (payload) async {
            await createBill(payload);
          },
        );
      },
    );
  }

  Future<void> openEditBillSheet(BillItem item) async {
    HapticFeedback.selectionClick();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    final detail = await fetchBillDetail(item);

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (detail == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BillFormSheet(
          mode: BillFormMode.edit,
          bill: detail,
          categories: categories,
          billingCycles: billingCycles,
          onSubmit: (payload) async {
            await updateBill(detail.id, payload);
          },
          onDelete: () {
            Navigator.pop(context);
            openDeleteConfirm(detail);
          },
        );
      },
    );
  }

  void openPayConfirm(BillItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Bayar Tagihan?'),
          content: Text(
            'Tagihan "${item.name}" akan ditandai sebagai sudah dibayar.\n\n'
                'Nominal: ${item.currency} ${formatRupiah(item.amount)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: loadingPayId == item.id
                  ? null
                  : () {
                Navigator.pop(dialogContext);
                payBill(item);
              },
              child: const Text('Bayar'),
            ),
          ],
        );
      },
    );
  }

  void openDeleteConfirm(BillItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Hapus Tagihan?'),
          content: Text(
            'Tagihan "${item.name}" akan dihapus permanen dan tidak bisa dikembalikan.\n\n'
                'Nominal: ${item.currency} ${formatRupiah(item.amount)}',
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
              onPressed: loadingDeleteId == item.id
                  ? null
                  : () {
                Navigator.pop(dialogContext);
                deleteBill(item);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  int getRemainingDays(DateTime? dateValue) {
    if (dateValue == null) return 0;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final targetOnly = DateTime(
      dateValue.year,
      dateValue.month,
      dateValue.day,
    );

    return targetOnly.difference(todayOnly).inDays;
  }

  bool isOverdue(BillItem item) {
    if (item.isPaid) return false;

    return getRemainingDays(item.nextDueDate) < 0;
  }

  String getBillStatus(BillItem item) {
    if (item.isPaid) return 'sudah';
    if (isOverdue(item)) return 'terlambat';

    return 'belum';
  }

  String getBillStatusText(BillItem item) {
    final status = getBillStatus(item);

    if (status == 'sudah') return 'Sudah Bayar';
    if (status == 'terlambat') return 'Terlambat';

    return 'Belum Bayar';
  }

  String getBillInfo(BillItem item) {
    if (item.isPaid) return 'Sudah dibayar';

    final days = getRemainingDays(item.nextDueDate);

    if (days < 0) return 'Terlambat ${days.abs()} hari!';
    if (days == 0) return 'Jatuh tempo hari ini!';

    return '$days hari lagi';
  }

  bool isUrgent(BillItem item) {
    if (item.isPaid) return false;

    final days = getRemainingDays(item.nextDueDate);

    return days <= item.remindDaysBefore;
  }

  String getBillingCycleLabel(String value) {
    if (value == 'monthly') return 'Bulanan';
    if (value == 'weekly') return 'Mingguan';
    if (value == 'yearly') return 'Tahunan';

    return value.isEmpty ? '-' : value;
  }

  String formatRupiah(double value) {
    return CurrencyFormat.convertToIdr(value).replaceAll('Rp ', '');
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

  String formatDateTime(DateTime? value) {
    if (value == null) return '-';

    final date = formatDate(value);
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$date $hour:$minute';
  }

  Color getStatusColor(BillItem item) {
    final status = getBillStatus(item);

    if (status == 'sudah') return AppTheme.success;
    if (status == 'terlambat') return AppTheme.danger;

    return AppTheme.warning;
  }

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'internet':
        return Icons.wifi;
      case 'electricity':
        return Icons.flash_on;
      case 'water':
        return Icons.water_drop;
      case 'streaming':
        return Icons.play_circle;
      case 'phone':
        return Icons.phone_android;
      case 'rent':
        return Icons.home;
      case 'insurance':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'utilities':
        return Icons.receipt_long;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

      drawer: AppDrawer(
        onNavigate: widget.onNavigate,
        currentIndex: 7,
      ),

      appBar: AppBar(
        title: const Text('Tagihan'),
        actions: [
          IconButton(
            onPressed: openAddBillSheet,
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchBills,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDueAlert(),
                      const SizedBox(height: 14),
                      if (listError.isNotEmpty)
                        _buildMessageBox(
                          listError,
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
                      _buildFilterRow(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (loadingBills)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filteredBills.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada data bill',
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
                    itemCount: filteredBills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _buildBillCard(filteredBills[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loadingBills
                  ? 'Mengambil data tagihan...'
                  : '$dueThisWeek tagihan jatuh tempo minggu ini!',
              style: const TextStyle(
                color: AppTheme.warning,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
          _buildFilterButton('belum', 'Belum Bayar'),
          const SizedBox(width: 8),
          _buildFilterButton('sudah', 'Sudah Bayar'),
          const SizedBox(width: 8),
          _buildFilterButton('terlambat', 'Terlambat'),
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

  Widget _buildBillCard(BillItem item) {
    final statusColor = getStatusColor(item);
    final status = getBillStatus(item);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => openEditBillSheet(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isUrgent(item) && !item.isPaid
                ? AppTheme.danger.withOpacity(0.55)
                : Colors.grey.shade100,
            width: isUrgent(item) && !item.isPaid ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: item.isPaid ? 0.72 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      getCategoryIcon(item.category),
                      color: AppTheme.primaryColor,
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
                        const SizedBox(height: 4),
                        Text(
                          item.description.isEmpty ? '-' : item.description,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _buildBadge(
                              status == 'belum'
                                  ? 'BELUM BAYAR'
                                  : status == 'sudah'
                                  ? 'SUDAH BAYAR'
                                  : 'TERLAMBAT',
                              statusColor,
                            ),
                            _buildBadge(
                              getBillingCycleLabel(item.billingCycle),
                              AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.currency} ${formatRupiah(item.amount)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        getBillInfo(item),
                        style: TextStyle(
                          color: isUrgent(item) && !item.isPaid
                              ? AppTheme.danger
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Jatuh tempo',
                      formatDate(item.nextDueDate),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Kategori',
                      item.category.isEmpty ? '-' : item.category,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Bayar ke',
                      item.payTo.isEmpty ? '-' : item.payTo,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Reminder',
                      '${item.remindDaysBefore} hari sebelumnya',
                    ),
                  ],
                ),
              ),
              if (!item.isPaid) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: loadingPayId == item.id
                        ? null
                        : () => openPayConfirm(item),
                    icon: loadingPayId == item.id
                        ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      loadingPayId == item.id
                          ? 'Memproses...'
                          : 'Tandai Bayar',
                    ),
                  ),
                ),
              ],
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

enum BillFormMode { add, edit }

class BillFormSheet extends StatefulWidget {
  final BillFormMode mode;
  final BillItem? bill;
  final List<String> categories;
  final List<BillCycleOption> billingCycles;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final VoidCallback? onDelete;

  const BillFormSheet({
    super.key,
    required this.mode,
    this.bill,
    required this.categories,
    required this.billingCycles,
    required this.onSubmit,
    this.onDelete,
  });

  @override
  State<BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends State<BillFormSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController payToController = TextEditingController();
  final TextEditingController dayOfMonthController = TextEditingController();
  final TextEditingController remindDaysBeforeController =
  TextEditingController();

  String currency = 'IDR';
  String category = 'Utilities';
  String billingCycle = 'monthly';

  bool loading = false;
  String errorMessage = '';

  bool get isEdit => widget.mode == BillFormMode.edit;

  @override
  void initState() {
    super.initState();

    final bill = widget.bill;

    if (bill != null) {
      nameController.text = bill.name;
      descriptionController.text = bill.description;
      amountController.text = bill.amount.toStringAsFixed(0);
      currency = bill.currency.isEmpty ? 'IDR' : bill.currency;
      category = bill.category.isEmpty ? 'Utilities' : bill.category;
      payToController.text = bill.payTo;
      billingCycle = bill.billingCycle.isEmpty ? 'monthly' : bill.billingCycle;
      dayOfMonthController.text =
      bill.dayOfMonth <= 0 ? '' : bill.dayOfMonth.toString();
      remindDaysBeforeController.text = bill.remindDaysBefore.toString();
    } else {
      dayOfMonthController.text = '';
      remindDaysBeforeController.text = '0';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    payToController.dispose();
    dayOfMonthController.dispose();
    remindDaysBeforeController.dispose();
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
    final description = descriptionController.text.trim();
    final amount = cleanRupiah(amountController.text);
    final payTo = payToController.text.trim();
    final dayOfMonth = int.tryParse(dayOfMonthController.text.trim()) ?? 0;
    final remindDaysBefore =
        int.tryParse(remindDaysBeforeController.text.trim()) ?? 0;

    if (name.isEmpty) {
      setState(() => errorMessage = 'Nama tagihan wajib diisi');
      return;
    }

    if (description.isEmpty) {
      setState(() => errorMessage = 'Description wajib diisi');
      return;
    }

    if (amount <= 0) {
      setState(() => errorMessage = 'Amount harus lebih dari 0');
      return;
    }

    if (category.trim().isEmpty) {
      setState(() => errorMessage = 'Category wajib diisi');
      return;
    }

    if (payTo.isEmpty) {
      setState(() => errorMessage = 'Pay to wajib diisi');
      return;
    }

    if (dayOfMonth < 1 || dayOfMonth > 31) {
      setState(() => errorMessage = 'Day of month harus 1 sampai 31');
      return;
    }

    if (remindDaysBefore < 0) {
      setState(() => errorMessage = 'Reminder tidak valid');
      return;
    }

    final payload = {
      'name': name,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'pay_to': payTo,
      'billing_cycle': billingCycle,
      'day_of_month': dayOfMonth,
      'remind_days_before': remindDaysBefore,
      'icon': _BillScreenState.defaultBillIcon,
      'color': _BillScreenState.defaultBillColor,
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

    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }

  String formatDateTime(DateTime? value) {
    if (value == null) return '-';

    final date = formatDate(value);
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$date $hour:$minute';
  }

  String formatRupiah(double value) {
    return CurrencyFormat.convertToIdr(value).replaceAll('Rp ', '');
  }

  String getBillingCycleLabel(String value) {
    if (value == 'monthly') return 'Bulanan';
    if (value == 'weekly') return 'Mingguan';
    if (value == 'yearly') return 'Tahunan';

    return value.isEmpty ? '-' : value;
  }

  String getBillStatusText(BillItem item) {
    if (item.isPaid) return 'Sudah Bayar';

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (item.nextDueDate == null) return 'Belum Bayar';

    final targetOnly = DateTime(
      item.nextDueDate!.year,
      item.nextDueDate!.month,
      item.nextDueDate!.day,
    );

    if (targetOnly.difference(todayOnly).inDays < 0) {
      return 'Terlambat';
    }

    return 'Belum Bayar';
  }

  Color getBillStatusColor(BillItem item) {
    final status = getBillStatusText(item);

    if (status == 'Sudah Bayar') return AppTheme.success;
    if (status == 'Terlambat') return AppTheme.danger;

    return AppTheme.warning;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
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
                        isEdit ? 'Edit Tagihan' : 'Tambah Tagihan',
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
                    if (isEdit && widget.bill != null) ...[
                      _buildDetailBox(widget.bill!),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField(
                      label: 'Nama Tagihan',
                      controller: nameController,
                      hint: 'Contoh: IndiHome Internet',
                      icon: Icons.receipt_long,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Description',
                      controller: descriptionController,
                      hint: 'Contoh: Tagihan internet rumah',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Amount',
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
                    _buildCurrencyPicker(),
                    const SizedBox(height: 14),
                    _buildCategoryPicker(),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Bayar ke',
                      controller: payToController,
                      hint: 'Contoh: Telkom Indonesia',
                      icon: Icons.store,
                    ),
                    const SizedBox(height: 14),
                    _buildCyclePicker(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Tanggal Jatuh Tempo',
                            controller: dayOfMonthController,
                            hint: '1 - 31',
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
                            label: 'Reminder',
                            controller: remindDaysBeforeController,
                            hint: '0',
                            icon: Icons.notifications,
                            suffixText: 'hari',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
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
                              ? 'Update Tagihan'
                              : 'Simpan Tagihan',
                        ),
                      ),
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 12),
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
                          onPressed: loading ? null : widget.onDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus Tagihan'),
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

  Widget _buildDetailBox(BillItem bill) {
    final statusColor = getBillStatusColor(bill);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bill.name,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  getBillStatusText(bill),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Bill ID', bill.id),
          _buildDetailRow(
            'Amount',
            '${bill.currency} ${formatRupiah(bill.amount)}',
          ),
          _buildDetailRow('Category', bill.category),
          _buildDetailRow('Pay To', bill.payTo),
          _buildDetailRow(
            'Billing Cycle',
            getBillingCycleLabel(bill.billingCycle),
          ),
          _buildDetailRow('Day of Month', bill.dayOfMonth.toString()),
          _buildDetailRow('Next Due Date', formatDate(bill.nextDueDate)),
          _buildDetailRow(
            'Reminder',
            '${bill.remindDaysBefore} hari sebelumnya',
          ),
          _buildDetailRow('Created At', formatDateTime(bill.createdAt)),
          _buildDetailRow('Updated At', formatDateTime(bill.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
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
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
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

  Widget _buildCurrencyPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Currency',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currency,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.monetization_on_outlined),
          ),
          items: const [
            DropdownMenuItem(
              value: 'IDR',
              child: Text('IDR'),
            ),
            DropdownMenuItem(
              value: 'USD',
              child: Text('USD'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              currency = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
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
          children: widget.categories.map((item) {
            final isSelected = category == item;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();

                setState(() {
                  category = item;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item,
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

  Widget _buildCyclePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing Cycle',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: widget.billingCycles.map((item) {
            final isSelected = billingCycle == item.value;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();

                    setState(() {
                      billingCycle = item.value;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class BillCycleOption {
  final String label;
  final String value;

  const BillCycleOption({
    required this.label,
    required this.value,
  });
}

class BillItem {
  final String id;
  final String name;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final String payTo;
  final String billingCycle;
  final int dayOfMonth;
  final int remindDaysBefore;
  final String icon;
  final String color;
  final DateTime? nextDueDate;
  final bool isPaid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BillItem({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.payTo,
    required this.billingCycle,
    required this.dayOfMonth,
    required this.remindDaysBefore,
    required this.icon,
    required this.color,
    required this.nextDueDate,
    required this.isPaid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: _readString(json, ['id', '_id', 'ID', 'bill_id']),
      name: _readString(json, ['name', 'Name']),
      description: _readString(json, ['description', 'Description']),
      amount: _toDouble(json['amount'] ?? json['Amount']),
      currency: _readString(json, ['currency', 'Currency']).isEmpty
          ? 'IDR'
          : _readString(json, ['currency', 'Currency']),
      category: _readString(json, ['category', 'Category']),
      payTo: _readString(json, ['pay_to', 'payTo', 'PayTo']),
      billingCycle:
      _readString(json, ['billing_cycle', 'billingCycle', 'BillingCycle'])
          .isEmpty
          ? 'monthly'
          : _readString(
        json,
        ['billing_cycle', 'billingCycle', 'BillingCycle'],
      ),
      dayOfMonth: _toInt(json['day_of_month'] ?? json['dayOfMonth']),
      remindDaysBefore:
      _toInt(json['remind_days_before'] ?? json['remindDaysBefore']),
      icon: _readString(json, ['icon', 'Icon']),
      color: _readString(json, ['color', 'Color']),
      nextDueDate: _parseDate(
        json['next_due_date'] ?? json['nextDueDate'] ?? json['NextDueDate'],
      ),
      isPaid: _toBool(json['is_paid'] ?? json['isPaid'] ?? json['IsPaid']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  BillItem copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    String? currency,
    String? category,
    String? payTo,
    String? billingCycle,
    int? dayOfMonth,
    int? remindDaysBefore,
    String? icon,
    String? color,
    DateTime? nextDueDate,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      payTo: payTo ?? this.payTo,
      billingCycle: billingCycle ?? this.billingCycle,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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