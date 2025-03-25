import 'dart:convert';

class ApiResult {
  String body;
  final int statusCode;

  ApiResult({required this.body, required this.statusCode});

  T asJson<T>({required T fallback}) {
    try {
      return jsonDecode(body);
    } catch (e) {
      print(e);
      return fallback;
    }
  }
}
