enum TransactionType { pemasukan, pengeluaran }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String time;
  final String paymentMethod; // e.g. BCA, Cash, GoPay

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.time,
    required this.paymentMethod,
  });
}
