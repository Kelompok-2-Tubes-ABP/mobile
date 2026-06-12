import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/finance_provider.dart';

class AddInvestmentModal extends StatefulWidget {
  const AddInvestmentModal({super.key});

  @override
  State<AddInvestmentModal> createState() => _AddInvestmentModalState();
}

class _AddInvestmentModalState extends State<AddInvestmentModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _avgCostController = TextEditingController();
  final TextEditingController _currentPriceController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();
  String selectedType = 'saham'; // Default type
  bool _isLoading = false;

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
                  'Tambah Investasi',
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
            const Text('Jumlah Investasi', style: TextStyle(color: AppTheme.textSecondary)),
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

            // Name Input
            const Text('Nama Aset', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Bitcoin atau Bank Central Asia',
              ),
            ),
            const SizedBox(height: 20),

            // Symbol Input
            const Text('Simbol / Ticker', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(
                hintText: 'Contoh: BTC atau BBCA',
              ),
            ),
            const SizedBox(height: 20),

            // Avg Cost Input
            const Text('Harga Beli Rata-rata', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _avgCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Rp 0',
              ),
            ),
            const SizedBox(height: 20),

            // Current Price Input
            const Text('Harga Saat Ini', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _currentPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Rp 0',
              ),
            ),
            const SizedBox(height: 20),

            // Platform / Mata Uang Input
            const Text('Mata Uang / Platform', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _platformController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Binance atau Ajaib',
              ),
            ),
            const SizedBox(height: 20),

            // Profit Percentage Input
            const Text('Persentase Keuntungan (%)', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _profitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Contoh: 15.5 atau -5.2',
              ),
            ),
            const SizedBox(height: 20),

            // Type Selection
            const Text('Tipe Aset', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeOption('Saham', 'saham', Icons.trending_up),
                const SizedBox(width: 16),
                _buildTypeOption('Crypto', 'crypto', Icons.currency_bitcoin),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveInvestment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan Portofolio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, String value, IconData icon) {
    bool isSelected = selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveInvestment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final avgCost = double.tryParse(_avgCostController.text) ?? 0;
    final currentPrice = double.tryParse(_currentPriceController.text) ?? 0;
    
    if (amount <= 0 || _nameController.text.isEmpty || _symbolController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi Jumlah Investasi, Nama Aset, dan Simbol')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final symbol = _symbolController.text;
    final type = selectedType;
    final quantity = amount / (currentPrice > 0 ? currentPrice : (avgCost > 0 ? avgCost : 1.0));
    final exchange = _platformController.text.isEmpty ? 'Binance' : _platformController.text;

    try {
      final financeProvider = context.read<FinanceProvider>();
      final success = await financeProvider.createInvestment(
        name,
        symbol,
        type,
        quantity,
        avgCost,
        currentPrice,
        exchange,
      );

      if (success) {
        await financeProvider.fetchPortfolio();
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan investasi ke server')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
