import '../models/transaction_item.dart';

/// Hasil parsing dari teks bahasa santai.
class ParsedTransaction {
  final String title;
  final double amount;
  final String category;
  final bool isExpense;
  final String? note;

  const ParsedTransaction({
    required this.title,
    required this.amount,
    required this.category,
    required this.isExpense,
    this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedTransaction &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          amount == other.amount &&
          category == other.category &&
          isExpense == other.isExpense &&
          note == other.note;

  @override
  int get hashCode => Object.hash(title, amount, category, isExpense, note);

  @override
  String toString() =>
      'ParsedTransaction(title: "$title", amount: $amount, category: "$category", isExpense: $isExpense, note: "$note")';
}

class _AmountMatch {
  final double amount;
  final int start;
  final int end;

  const _AmountMatch({
    required this.amount,
    required this.start,
    required this.end,
  });
}

/// Parser teks bahasa santai untuk mengekstrak nominal, tipe (pengeluaran/pemasukan),
/// kategori, dan judul transaksi secara instan dan 100% offline.
class SmartTextParser {
  const SmartTextParser();

  /// Kata kunci untuk deteksi transaksi pemasukan.
  static const List<String> _incomeKeywords = [
    'gaji',
    'uang saku',
    'kiriman',
    'transferan',
    'dapat uang',
    'cashback',
    'bonus',
    'pemasukan',
    'sangu',
  ];

  /// Pemetaan kata kunci untuk kategori transaksi anak kos.
  static const Map<String, List<String>> _categoryKeywords = {
    TransactionCategory.makan: [
      'makan',
      'geprek',
      'nasi',
      'bakso',
      'ayam',
      'mie',
      'mi',
      'kopi',
      'minum',
      'sarapan',
      'lunch',
      'snack',
      'gorengan',
      'martabak',
      'sate',
      'indomie',
      'roti',
      'dinner',
      'jajan',
      'es teh',
    ],
    TransactionCategory.kosan: [
      'kos',
      'kost',
      'kosan',
      'laundry',
      'listrik',
      'air',
      'galon',
      'wifi',
      'sabun',
      'odol',
      'deterjen',
      'kontrakan',
      'kamar',
      'sampah',
      'iuran',
    ],
    TransactionCategory.nongkrong: [
      'nongkrong',
      'nongki',
      'cafe',
      'kafe',
      'warkop',
      'boba',
      'bioskop',
      'game',
      'steam',
      'spotify',
      'netflix',
      'cinema',
      'karaoke',
      'hangout',
    ],
    TransactionCategory.transport: [
      'bensin',
      'pertalite',
      'pertamax',
      'gojek',
      'grab',
      'ojol',
      'parkir',
      'angkot',
      'kereta',
      'tambal ban',
      'tol',
      'busway',
      'krl',
      'mrt',
      'servis',
      'oli',
    ],
    TransactionCategory.belajar: [
      'buku',
      'print',
      'fotokopi',
      'jilid',
      'pulpen',
      'praktikum',
      'kuliah',
      'ujian',
      'kertas',
      'modul',
      'atk',
      'alat tulis',
      'kursus',
      'seminar',
    ],
  };

  /// Method statis instan untuk melakukan parsing teks input.
  static ParsedTransaction? parse(String input) {
    return const SmartTextParser().parseText(input);
  }

  /// Mengeksekusi parsing kalimat santai menjadi data terstruktur.
  ParsedTransaction? parseText(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final normalized = replaceIndonesianNumberWords(trimmed);
    final lower = normalized.toLowerCase();

    // 1. Ekstraksi Nominal
    final amountMatch = _extractAmount(normalized);
    if (amountMatch == null || amountMatch.amount <= 0) {
      return null;
    }

    // 2. Deteksi Tipe (Pemasukan vs Pengeluaran)
    final isExpense = _detectIsExpense(lower);

    // 3. Deteksi Kategori
    final category = _detectCategory(lower);

    // 4. Ekstraksi Judul Bersih
    final title = _extractTitle(normalized, amountMatch, category);

    return ParsedTransaction(
      title: title,
      amount: amountMatch.amount,
      category: category,
      isExpense: isExpense,
      note: trimmed,
    );
  }

  /// Ekstraksi nominal dengan urutan prioritas pengali (jt/juta -> k/rb/ribu -> titik ribuan -> angka polos).
  _AmountMatch? _extractAmount(String input) {
    // Pola 1: Juta / jt (contoh: 1.5jt, 1,5 jt, 2jt, 3 juta, 1.5juta)
    final jtRegex = RegExp(
      r'(?:rp\.?\s*)?(\d+(?:[.,]\d+)?)\s*(jt|juta)\b',
      caseSensitive: false,
    );
    final jtMatch = jtRegex.firstMatch(input);
    if (jtMatch != null) {
      final numStr = jtMatch.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(numStr);
      if (val != null && val > 0) {
        return _AmountMatch(
          amount: val * 1000000,
          start: jtMatch.start,
          end: jtMatch.end,
        );
      }
    }

    // Pola 2: Ribu / rb / k (contoh: 18k, 18K, 18rb, 18 rb, 18ribu, 18 ribu, 2.5k)
    final rbRegex = RegExp(
      r'(?:rp\.?\s*)?(\d+(?:[.,]\d+)?)\s*(k|rb|ribu)\b',
      caseSensitive: false,
    );
    final rbMatch = rbRegex.firstMatch(input);
    if (rbMatch != null) {
      final numStr = rbMatch.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(numStr);
      if (val != null && val > 0) {
        return _AmountMatch(
          amount: val * 1000,
          start: rbMatch.start,
          end: rbMatch.end,
        );
      }
    }

    // Pola 3: Format titik ribuan Indonesia (contoh: 18.000, 150.000, 1.500.000, rp 18.000)
    final thousandDotRegex = RegExp(
      r'(?:rp\.?\s*)?(\d{1,3}(?:\.\d{3})+)\b',
      caseSensitive: false,
    );
    final dotMatch = thousandDotRegex.firstMatch(input);
    if (dotMatch != null) {
      final numStr = dotMatch.group(1)!.replaceAll('.', '');
      final val = double.tryParse(numStr);
      if (val != null && val > 0) {
        return _AmountMatch(
          amount: val,
          start: dotMatch.start,
          end: dotMatch.end,
        );
      }
    }

    // Pola 4: Awalan Rp diikuti angka polos (contoh: Rp 18000, rp.25000, rp5000)
    final rpPlainRegex = RegExp(
      r'(?:rp\.?\s*)(\d+)\b',
      caseSensitive: false,
    );
    final rpMatch = rpPlainRegex.firstMatch(input);
    if (rpMatch != null) {
      final val = double.tryParse(rpMatch.group(1)!);
      if (val != null && val > 0) {
        return _AmountMatch(
          amount: val,
          start: rpMatch.start,
          end: rpMatch.end,
        );
      }
    }

    // Pola 5: Angka polos 3 digit atau lebih (contoh: 18000, 25000, 500)
    final largeNumRegex = RegExp(r'\b(\d{3,})\b');
    final largeMatch = largeNumRegex.firstMatch(input);
    if (largeMatch != null) {
      final val = double.tryParse(largeMatch.group(1)!);
      if (val != null && val > 0) {
        return _AmountMatch(
          amount: val,
          start: largeMatch.start,
          end: largeMatch.end,
        );
      }
    }

    // Pola 6: Angka polos apapun sebagai fallback
    final anyNumRegex = RegExp(r'\b(\d+)\b');
    final anyMatch = anyNumRegex.firstMatch(input);
    if (anyMatch != null) {
      final val = double.tryParse(anyMatch.group(1)!);
      if (val != null && val > 0) {
        return _AmountMatch(
          amount: val,
          start: anyMatch.start,
          end: anyMatch.end,
        );
      }
    }

    return null;
  }

  /// Menentukan apakah transaksi berupa pemasukan atau pengeluaran.
  bool _detectIsExpense(String lowerInput) {
    for (final kw in _incomeKeywords) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(kw) + r'\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(lowerInput)) {
        return false; // Pemasukan
      }
    }
    return true; // Default: Pengeluaran
  }

  /// Menentukan kategori berdasarkan kata kunci yang paling cocok.
  /// Jika tidak ada kata kunci yang cocok, default fallback ke [TransactionCategory.makan].
  String _detectCategory(String lowerInput) {
    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        final pattern = RegExp(
          r'\b' + RegExp.escape(kw) + r'\b',
          caseSensitive: false,
        );
        if (pattern.hasMatch(lowerInput)) {
          return entry.key;
        }
      }
    }
    return TransactionCategory.makan;
  }

  /// Menghilangkan bagian nominal dari kalimat dan merapikan judul dengan Title Case.
  String _extractTitle(
    String originalInput,
    _AmountMatch match,
    String defaultCategory,
  ) {
    // Potong teks sebelum dan sesudah token nominal
    final before = originalInput.substring(0, match.start);
    final after = originalInput.substring(match.end);
    var rawTitle = '$before $after';

    // Bersihkan sisa kata "rp", "rp.", "rupiah" yang mungkin terpisah
    rawTitle = rawTitle.replaceAll(
      RegExp(r'\b(rp\.?|rupiah)\b', caseSensitive: false),
      ' ',
    );

    // Bersihkan kata penghubung harga (seperti "bayar", "sebesar", "seharga", "habis")
    // jika masih ada kata lain yang menjadi judul utama
    if (rawTitle.trim().contains(' ')) {
      rawTitle = rawTitle.replaceAll(
        RegExp(r'\b(bayar|sebesar|seharga|habis|kena)\s*$', caseSensitive: false),
        ' ',
      );
      rawTitle = rawTitle.replaceAll(
        RegExp(r'^\s*(sebesar|seharga|habis|kena)\b', caseSensitive: false),
        ' ',
      );
    }

    // Bersihkan karakter pembatas di awal/akhir kalimat (seperti tanda hubung, titik dua, koma)
    rawTitle = rawTitle.replaceAll(RegExp(r'^[\s\-:,]+|[\s\-:,]+$'), '');

    // Rapikan spasi ganda
    rawTitle = rawTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (rawTitle.isEmpty) {
      return defaultCategory;
    }

    return _toTitleCase(rawTitle);
  }

  /// Mengubah teks menjadi format Title Case per kata.
  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static const Set<String> _scaleTokens = {
    'sejuta',
    'seribu',
    'seratus',
    'juta',
    'jt',
    'ribu',
    'rb',
    'ratus',
  };

  /// Mengonversi frasa kata angka bahasa Indonesia (contoh: "dua puluh lima ribu", "sepuluh rb", "sejuta")
  /// menjadi representasi nominal numerik ("25000", "10000", "1000000").
  static String replaceIndonesianNumberWords(String text) {
    final pattern = RegExp(
      r'\b(?:sejuta|seribu|seratus|sepuluh|sebelas|setengah|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|belas|puluh|ratus|ribu|rb|juta|jt)(?:\s+(?:sejuta|seribu|seratus|sepuluh|sebelas|setengah|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|belas|puluh|ratus|ribu|rb|juta|jt))*\b',
      caseSensitive: false,
    );

    return text.replaceAllMapped(pattern, (match) {
      final matchedText = match.group(0)!;
      final tokens = matchedText
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      final parsedValue = _parseNumberPhrase(tokens);
      if (parsedValue != null && parsedValue > 0) {
        return parsedValue.toString();
      }
      return matchedText;
    });
  }

  static int? _parseNumberPhrase(List<String> words) {
    if (words.isEmpty) return null;

    // Harus mengandung setidaknya satu kata skala moneter
    if (!words.any((w) => _scaleTokens.contains(w))) {
      return null;
    }

    if (words.length == 1) {
      if (words[0] == 'sejuta') return 1000000;
      if (words[0] == 'seribu') return 1000;
      if (words[0] == 'seratus') return 100;
      return null;
    }

    int total = 0;
    var remaining = words;

    // 1. Ekstraksi Jutaan (juta / jt)
    final jutaIdx = remaining.indexWhere((w) => w == 'juta' || w == 'jt');
    if (jutaIdx != -1) {
      final millionsWords = remaining.sublist(0, jutaIdx);
      int millionMultiplier;
      if (millionsWords.isEmpty) {
        millionMultiplier = 1;
      } else if (millionsWords.length == 1 && millionsWords[0] == 'setengah') {
        total += 500000;
        millionMultiplier = 0;
      } else {
        final parsed = _parseSubThousand(millionsWords);
        if (parsed == null) return null;
        millionMultiplier = parsed;
      }
      total += millionMultiplier * 1000000;
      remaining = remaining.sublist(jutaIdx + 1);
    }

    // 2. Ekstraksi Ribuan (ribu / rb)
    final ribuIdx = remaining.indexWhere((w) => w == 'ribu' || w == 'rb');
    if (ribuIdx != -1) {
      final thousandsWords = remaining.sublist(0, ribuIdx);
      int thousandMultiplier;
      if (thousandsWords.isEmpty) {
        thousandMultiplier = 1;
      } else if (thousandsWords.length == 1 &&
          thousandsWords[0] == 'setengah') {
        total += 500;
        thousandMultiplier = 0;
      } else {
        final parsed = _parseSubThousand(thousandsWords);
        if (parsed == null) return null;
        thousandMultiplier = parsed;
      }
      total += thousandMultiplier * 1000;
      remaining = remaining.sublist(ribuIdx + 1);
    }

    // 3. Sisa Ratusan / Satuan jika ada
    if (remaining.isNotEmpty) {
      final sub = _parseSubThousand(remaining);
      if (sub != null) {
        total += sub;
      }
    }

    return total > 0 ? total : null;
  }

  static int? _parseSubThousand(List<String> words) {
    if (words.isEmpty) return null;

    if (words.length == 1) {
      if (words[0] == 'seratus') return 100;
      if (words[0] == 'seribu') return 1000;
      if (words[0] == 'sejuta') return 1000000;
      if (words[0] == 'sepuluh') return 10;
      if (words[0] == 'sebelas') return 11;
    }

    int total = 0;
    var remaining = words;

    final ratusIdx = remaining.indexWhere((w) => w == 'ratus');
    if (ratusIdx != -1) {
      final hundredsWords = remaining.sublist(0, ratusIdx);
      int hundredMultiplier;
      if (hundredsWords.isEmpty ||
          (hundredsWords.length == 1 &&
              (hundredsWords[0] == 'se' || hundredsWords[0] == 'satu'))) {
        hundredMultiplier = 1;
      } else {
        final parsedDigit = _parseDigit(hundredsWords.last);
        if (parsedDigit == null) return null;
        hundredMultiplier = parsedDigit;
      }
      total += hundredMultiplier * 100;
      remaining = remaining.sublist(ratusIdx + 1);
    } else if (remaining.isNotEmpty && remaining.first == 'seratus') {
      total += 100;
      remaining = remaining.sublist(1);
    }

    if (remaining.isNotEmpty) {
      final tensAndUnits = _parseSubHundred(remaining);
      if (tensAndUnits == null) return null;
      total += tensAndUnits;
    }

    return total;
  }

  static int? _parseSubHundred(List<String> words) {
    if (words.isEmpty) return 0;

    if (words.length == 1) {
      final w = words[0];
      if (w == 'sepuluh') return 10;
      if (w == 'sebelas') return 11;
      final digit = _parseDigit(w);
      if (digit != null) return digit;
      return null;
    }

    if (words.length == 2 && words[1] == 'belas') {
      if (words[0] == 'se' || words[0] == 'satu') return 11;
      final digit = _parseDigit(words[0]);
      if (digit != null && digit >= 2 && digit <= 9) {
        return 10 + digit;
      }
      return null;
    }

    final puluhIdx = words.indexWhere((w) => w == 'puluh');
    if (puluhIdx != -1) {
      int tens;
      final beforePuluh = words.sublist(0, puluhIdx);
      if (beforePuluh.length == 1) {
        if (beforePuluh[0] == 'se' || beforePuluh[0] == 'satu') {
          tens = 10;
        } else {
          final digit = _parseDigit(beforePuluh[0]);
          if (digit == null) return null;
          tens = digit * 10;
        }
      } else if (beforePuluh.isEmpty) {
        tens = 10;
      } else {
        return null;
      }

      final afterPuluh = words.sublist(puluhIdx + 1);
      if (afterPuluh.isEmpty) {
        return tens;
      } else if (afterPuluh.length == 1) {
        final digit = _parseDigit(afterPuluh[0]);
        if (digit == null) return null;
        return tens + digit;
      } else {
        return null;
      }
    }

    return null;
  }

  static int? _parseDigit(String word) {
    switch (word) {
      case 'nol':
      case 'kosong':
        return 0;
      case 'satu':
      case 'se':
        return 1;
      case 'dua':
        return 2;
      case 'tiga':
        return 3;
      case 'empat':
        return 4;
      case 'lima':
        return 5;
      case 'enam':
        return 6;
      case 'tujuh':
        return 7;
      case 'delapan':
        return 8;
      case 'sembilan':
        return 9;
      default:
        return null;
    }
  }
}
