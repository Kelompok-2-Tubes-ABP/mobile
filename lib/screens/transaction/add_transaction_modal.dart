import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart' as t;
import '../../providers/finance_provider.dart';

class AddTransactionModal extends StatefulWidget {
  final String selectedMonth;

  const AddTransactionModal({super.key, required this.selectedMonth});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  t.TransactionType selectedType = t.TransactionType.pengeluaran;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String selectedCategory = 'Makanan';
  late DateTime selectedDate;
  String selectedPaymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monthMap = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'Mei': 5, 'Juni': 6,
      'Juli': 7, 'Agustus': 8, 'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12
    };
    final targetMonth = monthMap[widget.selectedMonth] ?? now.month;
    if (targetMonth == now.month) {
      selectedDate = now;
    } else {
      selectedDate = DateTime(now.year, targetMonth, 1, 12, 0, 0);
    }

    print('ADD MODAL RECEIVED MONTH: ${widget.selectedMonth}');
    print('MONTH MAP RESULT: $targetMonth');
    print('DATE GENERATED LOCAL: ${selectedDate.toIso8601String()}');
    print('DATE GENERATED UTC: ${selectedDate.toUtc().toIso8601String()}');
    print('YEAR: ${selectedDate.year}, MONTH: ${selectedDate.month}, DAY: ${selectedDate.day}');
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, picked.day, 12, 0, 0);
      });
    }
  }

  final List<Map<String, dynamic>> incomeCategories = [
    {
      'name': 'Gaji',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
    },
    {'name': 'Bonus', 'icon': Icons.star_border, 'color': Colors.orange},
    {'name': 'Investasi', 'icon': Icons.trending_up, 'color': Colors.blue},
    {'name': 'Lainnya', 'icon': Icons.category, 'color': Colors.blueGrey},
  ];

  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Makanan', 'icon': Icons.restaurant, 'color': Colors.orange},
    {
      'name': 'Transportasi',
      'icon': Icons.directions_car,
      'color': Colors.indigo,
    },
    {'name': 'Belanja', 'icon': Icons.shopping_bag, 'color': Colors.red},
    {'name': 'Tagihan', 'icon': Icons.home, 'color': Colors.deepOrange},
    {'name': 'Kesehatan', 'icon': Icons.favorite_border, 'color': Colors.teal},
    {
      'name': 'Hiburan',
      'icon': Icons.sports_esports,
      'color': Colors.deepPurple,
    },
    {'name': 'Investasi', 'icon': Icons.trending_up, 'color': Colors.green},
    {'name': 'Lainnya', 'icon': Icons.phone_android, 'color': Colors.blueGrey},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> categories =
        selectedType == t.TransactionType.pemasukan
        ? incomeCategories
        : expenseCategories;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tambah Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Input
            const Text(
              'Jumlah',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Rp ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Type Toggle
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'Pengeluaran',
                    t.TransactionType.pengeluaran,
                    AppTheme.danger,
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'Pemasukan',
                    t.TransactionType.pemasukan,
                    AppTheme.success,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category Selection
            const Text(
              'Kategori',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.map((cat) {
                bool isSelected = selectedCategory == cat['name'];
                Color catColor = cat['color'];
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat['name']),
                  child: Container(
                    width:
                        (MediaQuery.of(context).size.width - 48 - 36) /
                        4, // 4 items per row, 48 padding, 36 spacing
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? catColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(cat['icon'], color: catColor, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? catColor : Colors.grey.shade600,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Deskripsi',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Makan siang di restoran',
              ),
            ),
            const SizedBox(height: 20),

            // Date Selection
            const Text('Tanggal Transaksi', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormatUtil.formatDayDate(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Method Selection
            const Text('Metode Pembayaran', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedPaymentMethod,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'BCA', child: Text('BCA')),
                DropdownMenuItem(value: 'GoPay', child: Text('GoPay')),
                DropdownMenuItem(value: 'OVO', child: Text('OVO')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedPaymentMethod = val;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Simpan Transaksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    t.TransactionType type,
    Color color,
    IconData icon,
  ) {
    bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
          selectedCategory = type == t.TransactionType.pemasukan
              ? 'Gaji'
              : 'Makanan';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final newTx = t.Transaction(
      id: DateTime.now().toString(),
      title: _descriptionController.text.isEmpty
          ? selectedCategory
          : _descriptionController.text,
      amount: amount,
      type: selectedType,
      category: selectedCategory,
      date: selectedDate,
      time: timeString,
      paymentMethod: selectedPaymentMethod,
    );

    final financeProvider = context.read<FinanceProvider>();
    print('SEBELUM CREATE:');
    print('SELECTED DATE: $selectedDate');
    print('SELECTED YEAR: ${selectedDate.year}');
    print('SELECTED MONTH: ${selectedDate.month}');
    print('SELECTED DAY: ${selectedDate.day}');

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    financeProvider.createTransaction(newTx).then((success) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      if (success) {
        Navigator.pop(context); // Tutup modal sheet
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan transaksi ke backend')),
        );
      }
    });
  }
}
