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
    print("TRANSACTION MONTH FIELD: ${json['month']}");

    final rawCategory = _readString(json, [
      'category',
      'Category',
    ]);

    final rawType = _readString(json, [
      'type',
      'Type',
    ]).toLowerCase();

    final rawDate = _readString(json, [
      'date',
      'Date',
      'created_at',
      'createdAt',
      'CreatedAt',
    ]);

    final rawMonth = _readString(json, [
      'month',
      'Month',
    ]);

    DateTime parsedDate = _parseDateSafe(rawDate);

    final monthNumber = _parseMonthToNumber(rawMonth);

    if (monthNumber != null) {
      final year = parsedDate.year <= 1900
          ? DateTime.now().year
          : parsedDate.year;

      parsedDate = DateTime(
        year,
        monthNumber,
        1,
        parsedDate.hour,
        parsedDate.minute,
        parsedDate.second,
      );

      print("DATE DIAMBIL DARI MONTH FIELD: $parsedDate");
    } else {
      print("MONTH FIELD KOSONG / TIDAK VALID, PAKAI DATE: $parsedDate");
    }

    print("TRANSACTION FINAL MONTH: ${parsedDate.month}");

    final categoryLower = rawCategory.toLowerCase();

    return Transaction(
      id: _readString(json, [
        'id',
        '_id',
        'ID',
      ]),
      title: _readString(json, [
        'description',
        'Description',
        'title',
        'Title',
      ]),
      amount: _toDouble(json['amount'] ?? json['Amount']),
      type: _parseTransactionType(rawType, categoryLower),
      category: _mapCategoryToUi(rawCategory),
      date: parsedDate,
      time:
      '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}',
      paymentMethod: '-',
    );
  }

  static TransactionType _parseTransactionType(
      String rawType,
      String categoryLower,
      ) {
    if (rawType == 'income' ||
        rawType == 'pemasukan' ||
        categoryLower == 'pendapatan' ||
        categoryLower == 'income') {
      return TransactionType.pemasukan;
    }

    return TransactionType.pengeluaran;
  }

  static String _mapCategoryToUi(String category) {
    final value = category.toLowerCase().trim();

    switch (value) {
      case 'food':
      case 'makanan':
        return 'Makanan';

      case 'transport':
      case 'transportasi':
        return 'Transportasi';

      case 'shopping':
      case 'belanja':
        return 'Belanja';

      case 'bills':
      case 'tagihan':
        return 'Tagihan';

      case 'health':
      case 'kesehatan':
        return 'Kesehatan';

      case 'entertainment':
      case 'hiburan':
        return 'Hiburan';

      case 'investment':
      case 'investasi':
        return 'Investasi';

      case 'income':
      case 'pendapatan':
      case 'gaji':
      case 'bonus':
        return 'Pendapatan';

      case 'other':
      case 'lainnya':
        return 'Lainnya';

      default:
        return category.isEmpty ? '-' : category;
    }
  }

  static int? _parseMonthToNumber(String month) {
    final value = month.toLowerCase().trim();

    if (value.isEmpty) return null;

    if (value.contains('-')) {
      try {
        final parts = value.split('-');

        if (parts.length >= 2) {
          final monthNumber = int.tryParse(parts[1]);

          if (monthNumber != null && monthNumber >= 1 && monthNumber <= 12) {
            return monthNumber;
          }
        }
      } catch (e) {
        print("ERROR PARSE MONTH yyyy-MM: $e");
      }
    }

    switch (value) {
      case 'january':
      case 'jan':
        return 1;

      case 'february':
      case 'feb':
        return 2;

      case 'march':
      case 'mar':
        return 3;

      case 'april':
      case 'apr':
        return 4;

      case 'may':
        return 5;

      case 'june':
      case 'jun':
        return 6;

      case 'july':
      case 'jul':
        return 7;

      case 'august':
      case 'aug':
        return 8;

      case 'september':
      case 'sep':
        return 9;

      case 'october':
      case 'oct':
        return 10;

      case 'november':
      case 'nov':
        return 11;

      case 'december':
      case 'dec':
        return 12;

      default:
        print("MONTH FORMAT TIDAK DIKENALI: $month");
        return null;
    }
  }

  static DateTime _parseDateSafe(String value) {
    try {
      if (value.isEmpty) {
        return DateTime.now();
      }

      final date = DateTime.parse(value).toLocal();

      if (date.year <= 1900) {
        print("DATE DEFAULT BACKEND TERDETEKSI: $date");
        return DateTime.now();
      }

      return date;
    } catch (e) {
      print("ERROR PARSE DATE: $e");
      return DateTime.now();
    }
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }
}