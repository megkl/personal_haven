import 'dart:convert';
import 'package:http/http.dart' as http;

/// Safaricom Daraja M-Pesa STK Push integration.
///
/// Setup:
///  1. Register at https://developer.safaricom.co.ke
///  2. Create an app and get Consumer Key + Consumer Secret
///  3. Set your shortcode, passkey, and callback URL below
///  4. For production change [_isSandbox] to false
class MpesaService {
  static final MpesaService instance = MpesaService._();
  MpesaService._();

  // ── Configuration — replace with your Daraja credentials ─────────────────
  static const _isSandbox = true;
  static const _consumerKey = 'YOUR_CONSUMER_KEY';
  static const _consumerSecret = 'YOUR_CONSUMER_SECRET';
  static const _shortcode = '174379'; // sandbox till number
  static const _passkey =
      'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  static const _callbackUrl =
      'https://YOUR_BACKEND_URL/mpesa/callback'; // your server endpoint

  String get _baseUrl => _isSandbox
      ? 'https://sandbox.safaricom.co.ke'
      : 'https://api.safaricom.co.ke';

  // ── Auth token ────────────────────────────────────────────────────────────

  Future<String?> _getAccessToken() async {
    final credentials =
        base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    final response = await http.get(
      Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
      headers: {'Authorization': 'Basic $credentials'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String?;
    }
    return null;
  }

  // ── STK Push ──────────────────────────────────────────────────────────────

  /// Initiates an M-Pesa STK push to [phone] for [amount] KES.
  /// [phone] should be in format 2547XXXXXXXX.
  /// Returns a [MpesaResult] with success status and checkout request ID.
  Future<MpesaResult> stkPush({
    required String phone,
    required double amount,
    required String accountRef,
    String description = 'Personal Haven Subscription',
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return MpesaResult(
            success: false, error: 'Failed to get M-Pesa access token');
      }

      final timestamp = _timestamp();
      final password = base64Encode(
          utf8.encode('$_shortcode$_passkey$timestamp'));

      final body = {
        'BusinessShortCode': _shortcode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toInt().toString(),
        'PartyA': phone,
        'PartyB': _shortcode,
        'PhoneNumber': phone,
        'CallBackURL': _callbackUrl,
        'AccountReference': accountRef,
        'TransactionDesc': description,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          data['ResponseCode'] == '0') {
        return MpesaResult(
          success: true,
          checkoutRequestId: data['CheckoutRequestID'] as String?,
          merchantRequestId: data['MerchantRequestID'] as String?,
        );
      }

      return MpesaResult(
        success: false,
        error: data['errorMessage'] as String? ??
            data['ResponseDescription'] as String? ??
            'STK push failed',
      );
    } catch (e) {
      return MpesaResult(success: false, error: e.toString());
    }
  }

  /// Query the status of an STK push transaction.
  Future<MpesaQueryResult> queryStatus(String checkoutRequestId) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return MpesaQueryResult(status: 'error', description: 'No token');
      }

      final timestamp = _timestamp();
      final password = base64Encode(
          utf8.encode('$_shortcode$_passkey$timestamp'));

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'BusinessShortCode': _shortcode,
          'Password': password,
          'Timestamp': timestamp,
          'CheckoutRequestID': checkoutRequestId,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final resultCode = data['ResultCode']?.toString();

      return MpesaQueryResult(
        status: resultCode == '0' ? 'success' : 'pending',
        description: data['ResultDesc'] as String? ?? '',
        resultCode: resultCode,
      );
    } catch (e) {
      return MpesaQueryResult(status: 'error', description: e.toString());
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }
}

class MpesaResult {
  final bool success;
  final String? checkoutRequestId;
  final String? merchantRequestId;
  final String? error;

  MpesaResult({
    required this.success,
    this.checkoutRequestId,
    this.merchantRequestId,
    this.error,
  });
}

class MpesaQueryResult {
  final String status; // 'success', 'pending', 'error'
  final String description;
  final String? resultCode;

  MpesaQueryResult(
      {required this.status, required this.description, this.resultCode});
}
