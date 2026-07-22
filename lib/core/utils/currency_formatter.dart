import 'package:intl/intl.dart';

class AppCurrency {
  final String code;
  final String symbol;
  final String name;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

class CurrencyFormatter {
  /// Used when the device region does not map to one of our supported
  /// currencies. A user's saved preference always takes priority.
  static const defaultCode = 'USD';

  static const _euroCountries = {
    'AD',
    'AT',
    'BE',
    'BG',
    'HR',
    'CY',
    'EE',
    'FI',
    'FR',
    'DE',
    'GR',
    'IE',
    'IT',
    'LV',
    'LT',
    'LU',
    'MT',
    'MC',
    'ME',
    'NL',
    'PT',
    'SK',
    'SI',
    'ES',
    'SM',
    'VA',
    'XK',
  };

  static const supported = [
    AppCurrency(code: 'KES', symbol: 'KES ', name: 'Kenyan Shilling'),
    AppCurrency(code: 'USD', symbol: r'$', name: 'US Dollar'),
    AppCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
    AppCurrency(code: 'GBP', symbol: '£', name: 'British Pound'),
    AppCurrency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
    AppCurrency(code: 'ZAR', symbol: 'R ', name: 'South African Rand'),
  ];

  static String defaultCodeForCountry(String? countryCode) {
    final country = countryCode?.toUpperCase();
    if (_euroCountries.contains(country)) return 'EUR';

    return switch (country) {
      'KE' => 'KES',
      'US' => 'USD',
      'GB' => 'GBP',
      'NG' => 'NGN',
      'ZA' => 'ZAR',
      _ => defaultCode,
    };
  }

  static AppCurrency optionFor(String code) {
    return supported.firstWhere(
      (option) => option.code == code,
      orElse: () => supported.first,
    );
  }

  static bool isCurrencyUnit(String unit) {
    return supported.any((option) => option.code == unit.toUpperCase());
  }

  static String format(num amount, String code, {int decimalDigits = 2}) {
    final option = optionFor(code);
    return NumberFormat.currency(
      symbol: option.symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  static String formatUnitAmount(num amount, String unit) {
    if (isCurrencyUnit(unit)) return format(amount, unit.toUpperCase());
    final digits = amount.truncateToDouble() == amount ? 0 : 1;
    return '${amount.toStringAsFixed(digits)} $unit';
  }
}
