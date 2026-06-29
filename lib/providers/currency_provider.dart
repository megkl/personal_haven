import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/utils/currency_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCurrencyCodeKey = 'app_currency_code';

class CurrencyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrencyCodeKey) ?? CurrencyFormatter.defaultCode;
  }

  Future<void> setCurrency(String code) async {
    state = AsyncData(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyCodeKey, code);
  }
}

final currencyProvider = AsyncNotifierProvider<CurrencyNotifier, String>(
  CurrencyNotifier.new,
);
