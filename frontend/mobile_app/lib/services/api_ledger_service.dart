import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/contract.dart';
import '../models/create_contract_request.dart';
import '../models/create_payment_request.dart';
import '../models/transaction_entry.dart';
import '../models/user_overview.dart';
import 'ledger_service.dart';

class ApiLedgerService implements LedgerService {
  const ApiLedgerService();

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$_defaultBaseUrl/$path').replace(
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await http.get(_uri(path, queryParameters));
    if (response.statusCode != 200) {
      throw Exception('Request failed (${response.statusCode}) for $path.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      final payload = jsonDecode(response.body);
      final detail = payload is Map<String, dynamic> ? payload['detail'] : null;
      throw Exception(detail ?? 'Request failed (${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<UserOverview> fetchOverview(String username) async {
    final json = await _getJson(
      'overview/',
      queryParameters: {'username': username},
    );
    return UserOverview.fromJson(json);
  }

  @override
  Future<TransactionEntry> claimTransaction({
    required String transactionId,
    required String username,
  }) async {
    final json = await _postJson(
      'transactions/$transactionId/claim/',
      body: {'username': username},
    );
    return TransactionEntry.fromJson(json);
  }

  @override
  Future<TransactionEntry> approveTransaction({
    required String transactionId,
    required String username,
  }) async {
    final json = await _postJson(
      'transactions/$transactionId/approve/',
      body: {'username': username},
    );
    return TransactionEntry.fromJson(json);
  }

  @override
  Future<Contract> approveContract({
    required String contractId,
    required String username,
  }) async {
    final json = await _postJson(
      'contracts/$contractId/approve/',
      body: {'username': username},
    );
    return Contract.fromJson(json);
  }

  @override
  Future<Contract> createContract({
    required String username,
    required CreateContractRequest request,
  }) async {
    final json = await _postJson(
      'contracts/',
      body: {
        'username': username,
        ...request.toJson(),
      },
    );
    return Contract.fromJson(json);
  }

  @override
  Future<TransactionEntry> createPayment({
    required String username,
    required CreatePaymentRequest request,
  }) async {
    final json = await _postJson(
      'contracts/${request.contractId}/pay/',
      body: {
        'username': username,
        ...request.toJson(),
      },
    );
    return TransactionEntry.fromJson(json);
  }
}
