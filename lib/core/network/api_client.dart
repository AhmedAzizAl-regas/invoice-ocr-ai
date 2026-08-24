import 'dart:convert';
import 'package:http/http.dart' as http;

/// ApiClient handles execution of standard JSON REST calls to Cloud OCR and LLM endpoints.
class ApiClient {
  final http.Client _client;

  ApiClient(this._client);

  /// Executes an HTTP POST request.
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    required dynamic body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final finalHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };

      final response = await _client.post(
        uri,
        headers: finalHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {'data': decoded};
        }
      } else {
        throw HttpException(
          statusCode: response.statusCode,
          message: 'API request failed: ${response.reasonPhrase}. Body: ${response.body}',
        );
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      throw Exception('Network connectivity error: $e');
    }
  }
}

/// Custom Exception representing HTTP protocol errors.
class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException({required this.statusCode, required this.message});

  @override
  String toString() => 'HttpException(Status: $statusCode, Message: $message)';
}
