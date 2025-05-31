import 'package:intl/intl.dart';

/// Utility class for formatting currency in Indonesian Rupiah (IDR)
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _formatterWithoutSymbol = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  /// Format a number to Indonesian Rupiah currency
  /// 
  /// [amount] - The amount to format
  /// [withSymbol] - Whether to include the Rp symbol (default: true)
  /// 
  /// Returns formatted currency string
  /// 
  /// Example:
  /// ```dart
  /// CurrencyFormatter.format(150000); // "Rp 150.000"
  /// CurrencyFormatter.format(150000, withSymbol: false); // "150.000"
  /// CurrencyFormatter.format(null); // "Rp 0"
  /// ```
  static String format(num? amount, {bool withSymbol = true}) {
    if (amount == null) {
      return withSymbol ? 'Rp 0' : '0';
    }

    if (withSymbol) {
      return _formatter.format(amount);
    } else {
      // Format without symbol and trim any whitespace
      return _formatterWithoutSymbol.format(amount).trim();
    }
  }

  /// Format a number to Indonesian Rupiah currency with compact notation
  /// for large numbers (e.g., 1.2M, 3.5K)
  /// 
  /// [amount] - The amount to format
  /// [withSymbol] - Whether to include the Rp symbol (default: true)
  /// 
  /// Returns formatted currency string with compact notation
  /// 
  /// Example:
  /// ```dart
  /// CurrencyFormatter.formatCompact(1500000); // "Rp 1,5 Jt"
  /// CurrencyFormatter.formatCompact(2500); // "Rp 2,5 Rb"
  /// ```
  static String formatCompact(num? amount, {bool withSymbol = true}) {
    if (amount == null) {
      return withSymbol ? 'Rp 0' : '0';
    }

    final NumberFormat compactFormatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: withSymbol ? 'Rp ' : '',
      decimalDigits: 1,
    );

    return compactFormatter.format(amount);
  }

  /// Parse a formatted currency string back to a number
  /// 
  /// [currencyString] - The formatted currency string to parse
  /// 
  /// Returns the parsed number or null if parsing fails
  /// 
  /// Example:
  /// ```dart
  /// CurrencyFormatter.parse("Rp 150.000"); // 150000
  /// CurrencyFormatter.parse("150.000"); // 150000
  /// ```
  static num? parse(String? currencyString) {
    if (currencyString == null || currencyString.isEmpty) {
      return null;
    }

    try {
      // Remove currency symbol and clean the string
      String cleanString = currencyString
          .replaceAll('Rp', '')
          .replaceAll(' ', '')
          .replaceAll('.', '');

      return num.tryParse(cleanString);
    } catch (e) {
      return null;
    }
  }

  /// Check if a string is a valid formatted currency
  /// 
  /// [currencyString] - The string to validate
  /// 
  /// Returns true if the string is a valid currency format
  static bool isValidCurrency(String? currencyString) {
    return parse(currencyString) != null;
  }
}