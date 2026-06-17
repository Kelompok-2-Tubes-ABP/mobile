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
    print("TRANSACTION RAW JSON: $json");
    print("TRANSACTION ID: ${json['id']}");
    print("TRANSACTION TYPE: ${json['type']}");
    print("TRANSACTION DATE: ${json['date']}");
    
    final category = (json['category'] ?? '').toString().toLowerCase();
    final parsedDate = DateTime.parse(json['date']).toLocal();
    print("TRANSACTION MONTH: ${parsedDate.month}");

    return Transaction(
      id: json['id'] ?? '',
      title: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),

      type: category == 'pendapatan'
          ? TransactionType.pemasukan
          : TransactionType.pengeluaran,

      category: json['category'] ?? '-',

      date: parsedDate,

      time: parsedDate.toString().substring(11, 16),

      paymentMethod: '-',
    );
  }
}
