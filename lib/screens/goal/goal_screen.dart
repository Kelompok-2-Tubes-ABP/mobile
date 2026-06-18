import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/app_drawer.dart';

class GoalScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const GoalScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  static const String apiBaseUrl = 'http://172.24.217.180:8000';

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool loadingGoals = false;
  bool savingTarget = false;
  bool savingDana = false;
  bool deletingGoal = false;

  String listError = '';
  String actionError = '';
  String actionSuccess = '';

  String? loadingContributeId;
  String? loadingDeleteId;

  List<SavingGoalItem> savingGoals = [];

  double get totalTerkumpul {
    return savingGoals.fold(
      0.0,
          (total, item) => total + item.goal.currentAmount,
    );
  }

  @override
  void initState() {
    super.initState();
    fetchSavingGoals();
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await storage.read(key: 'token');

    return {
      if (json) 'Content-Type': 'application/json',
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

  Future<void> fetchSavingGoals() async {
    if (!mounted) return;

    setState(() {
      loadingGoals = true;
      listError = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/savings_goal/get'),
        headers: await _headers(),
      );

      final data = _decodeResponseBody(response.body);

      print('SAVINGS GOAL LIST STATUS: ${response.statusCode}');
      print('SAVINGS GOAL LIST BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['detail'] ??
              data['error'] ??
              data['message'] ??
              data['Error'] ??
              'Gagal mengambil data target tabungan',
        );
      }

      if (!mounted) return;

      setState(() {
        if (data is List) {
          savingGoals = data.map((item) {
            return SavingGoalItem.fromJson(item);
          }).toList();
        } else if (data is Map<String, dynamic>) {
          final listData = data['data'] ??
              data['Message'] ??
              data['message'] ??
              data['goals'] ??
              data['saving_goals'];

          if (listData is List) {
            savingGoals = listData.map((item) {
              return SavingGoalItem.fromJson(item);
            }).toList();
          } else {
            savingGoals = [];
          }
        } else {
          savingGoals = [];
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        listError = e.toString().replaceAll('Exception: ', '');
        savingGoals = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingGoals = false;
        });
      }
    }
  }

  Future<void> createSavingGoal(Map<String, dynamic> payload) async {
    setState(() {
      savingTarget = true;
      actionError = '';
      actionSuccess = '';
    });

    try {
      print('CREATE SAVINGS GOAL PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/savings_goal/'),
        headers: await _headers(json: true),
        body: jsonEncode(payload),
      );

      final data = _decodeResponseBody(response.body);

      print('CREATE SAVINGS GOAL STATUS: ${response.statusCode}');
      print('CREATE SAVINGS GOAL BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['detail'] ??
              data['error'] ??
              data['message'] ??
              data['Error'] ??
              'Gagal menambahkan target tabungan',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Target tabungan berhasil ditambahkan';
      });

      await fetchSavingGoals();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          savingTarget = false;
        });
      }
    }
  }

  Future<void> contributeSavingGoal(
      SavingGoalItem item,
      double amount,
      ) async {
    final goalId = item.goal.id;

    if (goalId.isEmpty) {
      setState(() {
        actionError = 'Target tabungan tidak ditemukan';
      });
      return;
    }

    if (isGoalCompleted(item)) {
      setState(() {
        actionError = 'Target sudah tercapai, tidak perlu menambahkan dana';
      });
      return;
    }

    final sisaTarget = getSisaTarget(item);

    if (amount <= 0) {
      setState(() {
        actionError = 'Jumlah dana harus lebih dari 0';
      });
      return;
    }

    if (amount > sisaTarget) {
      setState(() {
        actionError =
        'Dana tambahan tidak boleh lebih dari sisa target ${formatCurrency(sisaTarget)}';
      });
      return;
    }

    setState(() {
      savingDana = true;
      loadingContributeId = goalId;
      actionError = '';
      actionSuccess = '';
    });

    try {
      final payload = {
        'amount': amount,
      };

      print('CONTRIBUTE GOAL ID: $goalId');
      print('CONTRIBUTE GOAL PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/savings_goal/$goalId/contribute'),
        headers: await _headers(json: true),
        body: jsonEncode(payload),
      );

      final data = _decodeResponseBody(response.body);

      print('CONTRIBUTE GOAL STATUS: ${response.statusCode}');
      print('CONTRIBUTE GOAL BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['detail'] ??
              data['error'] ??
              data['message'] ??
              data['Error'] ??
              'Gagal menambahkan dana',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Dana berhasil ditambahkan';
      });

      await fetchSavingGoals();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          savingDana = false;
          loadingContributeId = null;
        });
      }
    }
  }

  Future<void> deleteSavingGoal(SavingGoalItem item) async {
    final goalId = item.goal.id;

    if (goalId.isEmpty) {
      setState(() {
        actionError = 'Target tabungan tidak ditemukan';
      });
      return;
    }

    setState(() {
      deletingGoal = true;
      loadingDeleteId = goalId;
      actionError = '';
      actionSuccess = '';
    });

    try {
      print('DELETE SAVINGS GOAL ID: $goalId');

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/savings_goal/$goalId'),
        headers: await _headers(),
      );

      final data = _decodeResponseBody(response.body);

      print('DELETE SAVINGS GOAL STATUS: ${response.statusCode}');
      print('DELETE SAVINGS GOAL BODY: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['detail'] ??
              data['error'] ??
              data['message'] ??
              data['Error'] ??
              'Gagal menghapus target tabungan',
        );
      }

      if (!mounted) return;

      setState(() {
        actionSuccess = 'Target tabungan berhasil dihapus';
        savingGoals = savingGoals.where((goal) {
          return goal.goal.id != goalId;
        }).toList();
      });

      await fetchSavingGoals();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        actionError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          deletingGoal = false;
          loadingDeleteId = null;
        });
      }
    }
  }

  void openAddGoalSheet() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddGoalSheet(
          onSubmit: (payload) async {
            await createSavingGoal(payload);
          },
        );
      },
    );
  }

  void openAddDanaSheet(SavingGoalItem item) {
    if (isGoalCompleted(item)) return;

    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddDanaSheet(
          item: item,
          getProgress: getProgress,
          getRealProgress: getRealProgress,
          getSisaTarget: getSisaTarget,
          isGoalCompleted: isGoalCompleted,
          onSubmit: (amount) async {
            await contributeSavingGoal(item, amount);
          },
        );
      },
    );
  }

  void openDeleteConfirm(SavingGoalItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Hapus Target?'),
          content: Text(
            'Target tabungan "${item.goal.name}" akan dihapus permanen dan tidak bisa dikembalikan.\n\n'
                'Target: ${formatCurrency(item.goal.targetAmount)}',
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
              onPressed: loadingDeleteId == item.goal.id
                  ? null
                  : () {
                Navigator.pop(dialogContext);
                deleteSavingGoal(item);
              },
              child: Text(
                loadingDeleteId == item.goal.id ? 'Menghapus...' : 'Hapus',
              ),
            ),
          ],
        );
      },
    );
  }

  int getProgress(SavingGoalItem item) {
    final progress = item.progress;
    return progress.round().clamp(0, 100);
  }

  int getRealProgress(SavingGoalItem item) {
    return item.progress.round();
  }

  double getSisaTarget(SavingGoalItem item) {
    final target = item.goal.targetAmount;
    final current = item.goal.currentAmount;

    return (target - current).clamp(0.0, target);
  }

  bool isGoalCompleted(SavingGoalItem item) {
    final target = item.goal.targetAmount;
    final current = item.goal.currentAmount;

    return target > 0 && current >= target;
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

    final day = value.day.toString();
    final month = months[value.month - 1];
    final year = value.year;

    return '$day $month $year';
  }

  Color getGoalColor(SavingGoalItem item) {
    if (isGoalCompleted(item)) return AppTheme.success;
    if (item.onTrack) return AppTheme.primaryColor;

    return AppTheme.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

      // Drawer sudah lewat MainScreen.
      // Index Goal sesuai AppDrawer = 3.
      drawer: AppDrawer(
        onNavigate: widget.onNavigate,
        currentIndex: 3,
      ),

      appBar: AppBar(
        title: const Text('Target Tabungan'),
        actions: [
          IconButton(
            onPressed: openAddGoalSheet,
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      // Floating button "+ Tambah" bawah sudah dihapus.

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchSavingGoals,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSummary(),
                      const SizedBox(height: 14),
                      _buildMotivationBox(),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Daftar Target',
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
              if (loadingGoals)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (savingGoals.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada target tabungan.',
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
                    itemCount: savingGoals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _buildGoalCard(savingGoals[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Terkumpul',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(totalTerkumpul),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${savingGoals.length} target tabungan',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationBox() {
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
              color: AppTheme.warning.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konsisten adalah kunci',
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Tambah dana sedikit demi sedikit agar targetmu tercapai.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(SavingGoalItem item) {
    final completed = isGoalCompleted(item);
    final progress = getProgress(item);
    final realProgress = getRealProgress(item);
    final color = getGoalColor(item);
    final sisaTarget = getSisaTarget(item);

    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed ? Icons.check_circle : Icons.track_changes,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.goal.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildBadge(
                      completed ? 'TERCAPAI' : 'ON PROGRESS',
                      completed ? AppTheme.success : AppTheme.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: progress / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      '$realProgress%',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  'Target',
                  formatCurrency(item.goal.targetAmount),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'Terkumpul',
                  formatCurrency(item.goal.currentAmount),
                  valueColor: AppTheme.success,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'Sisa',
                  formatCurrency(sisaTarget),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'Deadline',
                  formatDate(item.goal.targetDate),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'Dibutuhkan / Bulan',
                  formatCurrency(item.monthlyNeeded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!completed)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: loadingContributeId == item.goal.id
                    ? null
                    : () => openAddDanaSheet(item),
                icon: loadingContributeId == item.goal.id
                    ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.add, size: 18),
                label: Text(
                  loadingContributeId == item.goal.id
                      ? 'Menyimpan...'
                      : 'Tambah Dana',
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Target sudah tercapai 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 10),
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
              onPressed: loadingDeleteId == item.goal.id
                  ? null
                  : () => openDeleteConfirm(item),
              icon: loadingDeleteId == item.goal.id
                  ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.delete_outline, size: 18),
              label: Text(
                loadingDeleteId == item.goal.id ? 'Menghapus...' : 'Hapus',
              ),
            ),
          ),
        ],
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

  Widget _buildInfoRow(
      String label,
      String value, {
        Color? valueColor,
      }) {
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
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
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

class AddGoalSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const AddGoalSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final TextEditingController namaTargetController = TextEditingController();
  final TextEditingController targetJumlahController = TextEditingController();
  final TextEditingController sudahTerkumpulController =
  TextEditingController();

  DateTime? selectedDeadline;

  bool loading = false;
  String errorMessage = '';

  @override
  void dispose() {
    namaTargetController.dispose();
    targetJumlahController.dispose();
    sudahTerkumpulController.dispose();
    super.dispose();
  }

  double cleanRupiah(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
  }

  String formatDate(DateTime? value) {
    if (value == null) return 'Pilih deadline';

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

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  Future<void> pickDeadline() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 20),
    );

    if (picked == null) return;

    setState(() {
      selectedDeadline = picked;
    });
  }

  Future<void> submit() async {
    setState(() {
      errorMessage = '';
    });

    final name = namaTargetController.text.trim();
    final targetAmount = cleanRupiah(targetJumlahController.text);
    final initialAmount = cleanRupiah(sudahTerkumpulController.text);

    if (name.isEmpty) {
      setState(() => errorMessage = 'Nama target wajib diisi');
      return;
    }

    if (targetAmount <= 0) {
      setState(() => errorMessage = 'Target jumlah harus lebih dari 0');
      return;
    }

    if (initialAmount < 0) {
      setState(() => errorMessage = 'Dana terkumpul tidak valid');
      return;
    }

    if (initialAmount > targetAmount) {
      setState(() {
        errorMessage = 'Dana terkumpul tidak boleh lebih besar dari target';
      });
      return;
    }

    if (selectedDeadline == null) {
      setState(() => errorMessage = 'Deadline wajib diisi');
      return;
    }

    final now = DateTime.now();
    final selectedDate = DateTime(
      selectedDeadline!.year,
      selectedDeadline!.month,
      selectedDeadline!.day,
      23,
      59,
      59,
    );

    if (selectedDate.isBefore(now) || selectedDate.isAtSameMomentAs(now)) {
      setState(() => errorMessage = 'Deadline harus di masa depan');
      return;
    }

    final targetDateIso = DateTime(
      selectedDeadline!.year,
      selectedDeadline!.month,
      selectedDeadline!.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    final payload = {
      'name': name,
      'target_amount': targetAmount,
      'target_date': targetDateIso,
      'initial_amount': initialAmount,
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
      initialChildSize: 0.82,
      minChildSize: 0.45,
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
                        'Tambah Target Tabungan',
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
                    _buildTextField(
                      label: 'Nama Target',
                      controller: namaTargetController,
                      hint: 'Contoh: Emergency Fund',
                      icon: Icons.track_changes,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Target Jumlah',
                      controller: targetJumlahController,
                      hint: '0',
                      icon: Icons.savings,
                      prefixText: 'Rp ',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Sudah Terkumpul',
                      controller: sudahTerkumpulController,
                      hint: '0',
                      icon: Icons.account_balance_wallet_outlined,
                      prefixText: 'Rp ',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Deadline',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: pickDeadline,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                formatDate(selectedDeadline),
                                style: TextStyle(
                                  color: selectedDeadline == null
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          loading ? 'Menyimpan...' : 'Simpan Target',
                        ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
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

class AddDanaSheet extends StatefulWidget {
  final SavingGoalItem item;
  final int Function(SavingGoalItem item) getProgress;
  final int Function(SavingGoalItem item) getRealProgress;
  final double Function(SavingGoalItem item) getSisaTarget;
  final bool Function(SavingGoalItem item) isGoalCompleted;
  final Future<void> Function(double amount) onSubmit;

  const AddDanaSheet({
    super.key,
    required this.item,
    required this.getProgress,
    required this.getRealProgress,
    required this.getSisaTarget,
    required this.isGoalCompleted,
    required this.onSubmit,
  });

  @override
  State<AddDanaSheet> createState() => _AddDanaSheetState();
}

class _AddDanaSheetState extends State<AddDanaSheet> {
  final TextEditingController tambahanDanaController = TextEditingController();

  bool loading = false;
  String errorMessage = '';

  @override
  void dispose() {
    tambahanDanaController.dispose();
    super.dispose();
  }

  double cleanRupiah(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
  }

  void pilihNominal(double nominal) {
    final sisaTarget = widget.getSisaTarget(widget.item);
    final finalNominal = nominal > sisaTarget ? sisaTarget : nominal;

    tambahanDanaController.text = finalNominal.toStringAsFixed(0);
  }

  Future<void> submit() async {
    setState(() {
      errorMessage = '';
    });

    if (widget.isGoalCompleted(widget.item)) {
      setState(() {
        errorMessage = 'Target sudah tercapai, tidak perlu menambahkan dana';
      });
      return;
    }

    final amount = cleanRupiah(tambahanDanaController.text);
    final sisaTarget = widget.getSisaTarget(widget.item);

    if (amount <= 0) {
      setState(() => errorMessage = 'Jumlah dana harus lebih dari 0');
      return;
    }

    if (amount > sisaTarget) {
      setState(() {
        errorMessage =
        'Dana tambahan tidak boleh lebih dari sisa target ${CurrencyFormat.convertToIdr(sisaTarget)}';
      });
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await widget.onSubmit(amount);

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
    final progress = widget.getProgress(widget.item);
    final realProgress = widget.getRealProgress(widget.item);
    final sisaTarget = widget.getSisaTarget(widget.item);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
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
                        'Tambah Dana',
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.item.goal.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CircularProgressIndicator(
                                    value: progress / 100,
                                    strokeWidth: 9,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                      AppTheme.success,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$realProgress%',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${CurrencyFormat.convertToIdr(widget.item.goal.currentAmount)} dari ${CurrencyFormat.convertToIdr(widget.item.goal.targetAmount)}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sisa target: ${CurrencyFormat.convertToIdr(sisaTarget)}',
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Jumlah Tambahan Dana',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tambahanDanaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(Icons.add_card),
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickButton(50000),
                        _buildQuickButton(100000),
                        _buildQuickButton(500000),
                        _buildQuickButton(1000000),
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
                          loading ? 'Menyimpan...' : 'Simpan Dana',
                        ),
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

  Widget _buildQuickButton(double amount) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        pilihNominal(amount);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          CurrencyFormat.convertToIdr(amount).replaceAll('Rp ', ''),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class SavingGoalItem {
  final SavingGoal goal;
  final double monthlyNeeded;
  final bool onTrack;
  final double progress;

  SavingGoalItem({
    required this.goal,
    required this.monthlyNeeded,
    required this.onTrack,
    required this.progress,
  });

  factory SavingGoalItem.fromJson(Map<String, dynamic> json) {
    final goalRaw = json['goal'];

    return SavingGoalItem(
      goal: goalRaw is Map<String, dynamic>
          ? SavingGoal.fromJson(goalRaw)
          : SavingGoal.fromJson(json),
      monthlyNeeded: _toDouble(json['monthly_needed'] ?? json['monthlyNeeded']),
      onTrack: _toBool(json['on_track'] ?? json['onTrack']),
      progress: _toDouble(json['progress']),
    );
  }
}

class SavingGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final DateTime? deadline;

  SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.deadline,
  });

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    return SavingGoal(
      id: _readString(json, ['id', '_id', 'ID']),
      name: _readString(json, ['name', 'Name']),
      targetAmount: _toDouble(json['target_amount'] ?? json['targetAmount']),
      currentAmount: _toDouble(json['current_amount'] ?? json['currentAmount']),
      targetDate: _parseDate(json['target_date'] ?? json['targetDate']),
      deadline: _parseDate(json['deadline'] ?? json['Deadline']),
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