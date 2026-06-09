enum TransactionType { pemasukan, pengeluaran }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String time;
  final String paymentMethod;

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

  factory Transaction.fromApiJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? '').toString().toLowerCase();

    return Transaction(
      id: json['id'] ?? '',
      title: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),

      type: category == 'pendapatan'
          ? TransactionType.pemasukan
          : TransactionType.pengeluaran,

      category: json['category'] ?? '-',

      date: DateTime.parse(json['date']),

      time: DateTime.parse(json['date']).toLocal().toString().substring(11, 16),

      paymentMethod: '-',
    );
  }
}
