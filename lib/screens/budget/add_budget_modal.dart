import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/finance_provider.dart';


class AddBudgetModal extends StatefulWidget {
  const AddBudgetModal({super.key});

  @override
  State<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends State<AddBudgetModal> {
  final TextEditingController _amountController = TextEditingController();
  String selectedCategory = 'Makanan';

  final List<Map<String, dynamic>> categories = [
    {'name': 'Makanan', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Transportasi', 'icon': Icons.directions_car, 'color': Colors.indigo},
    {'name': 'Belanja', 'icon': Icons.shopping_bag, 'color': Colors.red},
    {'name': 'Tagihan', 'icon': Icons.home, 'color': Colors.deepOrange},
    {'name': 'Kesehatan', 'icon': Icons.favorite_border, 'color': Colors.teal},
    {'name': 'Hiburan', 'icon': Icons.sports_esports, 'color': Colors.deepPurple},
    {'name': 'Lainnya', 'icon': Icons.category, 'color': Colors.blueGrey},
  ];

  @override
  Widget build(BuildContext context) {
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
                  'Tambah Budget',
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
            const Text('Batas Budget', style: TextStyle(color: AppTheme.textSecondary)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text('Rp ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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

            // Category Selection
            const Text('Kategori', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
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
                    width: (MediaQuery.of(context).size.width - 48 - 36) / 4,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? catColor.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? catColor : Colors.transparent, width: 1.5),
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
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
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Simpan Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveBudget() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    context.read<FinanceProvider>().createCategoryBudget(selectedCategory, amount).then((success) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog loading
      if (success) {
        Navigator.pop(context); // Tutup modal add budget
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget berhasil disimpan')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan budget')),
        );
      }
    });
  }
}
