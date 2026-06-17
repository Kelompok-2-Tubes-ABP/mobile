import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/budget.dart';

class AddMonthlyBudgetModal extends StatefulWidget {
  final MonthlyBudget? monthlyBudgetToEdit;

  const AddMonthlyBudgetModal({super.key, this.monthlyBudgetToEdit});

  @override
  State<AddMonthlyBudgetModal> createState() => _AddMonthlyBudgetModalState();
}

class _AddMonthlyBudgetModalState extends State<AddMonthlyBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  bool _isLoading = false;
  String _selectedMonth = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  bool get isEditMode => widget.monthlyBudgetToEdit != null;

  List<String> _generateMonths() {
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = -3; i <= 8; i++) {
      DateTime d = DateTime(now.year, now.month + i, 1);
      months.add("${d.year}-${d.month.toString().padLeft(2, '0')}");
    }
    return months;
  }

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _selectedMonth = widget.monthlyBudgetToEdit!.month;
      // Pre-fill the limit field with the current value
      final currentLimit = widget.monthlyBudgetToEdit!.limit.toInt();
      _limitController.text = CurrencyFormat.convertToIdr(currentLimit).replaceAll('Rp ', '');
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final limitRaw = _limitController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final limit = double.tryParse(limitRaw) ?? 0;

      bool success;
      if (isEditMode) {
        success = await context.read<FinanceProvider>().updateMonthlyBudget(
          widget.monthlyBudgetToEdit!.id,
          limit,
          _selectedMonth,
        );
      } else {
        success = await context.read<FinanceProvider>().createMonthlyBudget(
          limit,
          month: _selectedMonth,
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditMode ? 'Budget bulanan berhasil diperbarui' : 'Budget bulanan berhasil dibuat'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditMode ? 'Gagal memperbarui budget bulanan' : 'Gagal membuat budget bulanan'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditMode ? 'Edit Budget Bulanan' : 'Buat Budget Bulanan',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (isEditMode)
              // Show the month as read-only text when editing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppTheme.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Bulan: $_selectedMonth',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                decoration: InputDecoration(
                  labelText: 'Bulan Target',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _generateMonths().map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMonth = newValue;
                    });
                  }
                },
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Total Limit Bulanan',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final number = int.tryParse(
                    value.replaceAll(RegExp(r'[^0-9]'), ''),
                  );
                  if (number != null) {
                    _limitController.value = TextEditingValue(
                      text: CurrencyFormat.convertToIdr(
                        number,
                      ).replaceAll('Rp ', ''),
                      selection: TextSelection.collapsed(
                        offset: CurrencyFormat.convertToIdr(
                          number,
                        ).replaceAll('Rp ', '').length,
                      ),
                    );
                  }
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Limit tidak boleh kosong';
                }
                final number = int.tryParse(
                  value.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                if (number == null || number <= 0) {
                  return 'Limit harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  : Text(
                      isEditMode ? 'Perbarui' : 'Simpan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
