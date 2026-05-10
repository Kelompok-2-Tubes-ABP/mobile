import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart' as t;
import '../../providers/finance_provider.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  t.TransactionType selectedType = t.TransactionType.pengeluaran;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String selectedCategory = 'Lainnya';

  final List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Gaji', 'icon': Icons.trending_up},
    {'name': 'Bonus', 'icon': Icons.star_border},
    {'name': 'Investasi', 'icon': Icons.account_balance},
    {'name': 'Lainnya', 'icon': Icons.category},
  ];

  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Makanan', 'icon': Icons.restaurant},
    {'name': 'Transportasi', 'icon': Icons.directions_car},
    {'name': 'Belanja', 'icon': Icons.shopping_bag},
    {'name': 'Tagihan', 'icon': Icons.receipt},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> categories = 
        selectedType == t.TransactionType.pemasukan ? incomeCategories : expenseCategories;

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
                )
              ],
            ),
            const SizedBox(height: 24),
            
            // Amount Input
            const Text('Jumlah', style: TextStyle(color: AppTheme.textSecondary)),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
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
                    Icons.arrow_downward
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'Pemasukan', 
                    t.TransactionType.pemasukan,
                    AppTheme.success,
                    Icons.arrow_upward
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category Selection
            const Text('Kategori', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  bool isSelected = selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat['name']),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'], color: isSelected ? AppTheme.primaryColor : Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? AppTheme.primaryColor : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text('Deskripsi', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Makan siang di restoran',
              ),
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

  Widget _buildTypeButton(String label, t.TransactionType type, Color color, IconData icon) {
    bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
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

    final newTx = t.Transaction(
      id: DateTime.now().toString(),
      title: _descriptionController.text.isEmpty ? selectedCategory : _descriptionController.text,
      amount: amount,
      type: selectedType,
      category: selectedCategory,
      date: DateTime.now(),
      time: '19:30',
      paymentMethod: 'Cash',
    );

    context.read<FinanceProvider>().addTransaction(newTx);
    Navigator.pop(context);
  }
}
