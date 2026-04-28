import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'user_provider.dart';

/// على Render تحت `/app/`: نفس النطاق. تطوير ويب محلي: `FLORABIT_API_BASE=http://127.0.0.1:5000`.
String get baseUrl {
  const env = String.fromEnvironment('FLORABIT_API_BASE');
  if (env.isNotEmpty) return env;
  if (kIsWeb) {
    final p = Uri.base.path;
    if (p.startsWith('/app/') || p == '/app') {
      return Uri.base.origin;
    }
    return 'http://127.0.0.1:5000';
  }
  return 'http://10.0.2.2:5000';
}

class ApiService {
  /// يُرسل مع الطلبات التي تتطلب هوية المستخدم عندما لا تُستخدم جلسة المتصفح (تطبيق Flutter).
  static Map<String, String> _jsonHeadersWithUser() {
    final h = <String, String>{'Content-Type': 'application/json'};
    final uid = UserProvider.userId;
    if (uid != null) {
      h['X-User-Id'] = '$uid';
    }
    return h;
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password,
      {String? city, String? homeType}) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    if (city != null) body['city'] = city;
    if (homeType != null) body['home_type'] = homeType;
    final res = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> identifyPlant(
      List<int> imageBytes) async {
    final b64 = base64Encode(imageBytes);
    final res = await http.post(
      Uri.parse('$baseUrl/api/identify-plant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_base64': b64}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final preds = data['predictions'] as List<dynamic>? ?? [];
    return preds.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getArabicPlants() async {
    final res = await http.get(Uri.parse('$baseUrl/api/plants/arabic-list'));
    final list = jsonDecode(res.body) as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  static Future<List<dynamic>> getPlants(int? userId) async {
    final url = userId != null
        ? '$baseUrl/api/plants?user_id=$userId'
        : '$baseUrl/api/plants';
    final res = await http.get(Uri.parse(url));
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getPlant(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/plants/$id'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createPlant(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/plants'),
      headers: _jsonHeadersWithUser(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> waterPlant(int plantId) async {
    await http.post(
      Uri.parse('$baseUrl/api/plants/$plantId/water'),
      headers: _jsonHeadersWithUser(),
      body: '{}',
    );
  }

  static Future<void> fertilizePlant(int plantId) async {
    await http.post(
      Uri.parse('$baseUrl/api/plants/$plantId/fertilize'),
      headers: _jsonHeadersWithUser(),
      body: '{}',
    );
  }

  static Future<List<dynamic>> getCareLogs(int plantId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/care-logs?plant_id=$plantId'));
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getPlantCatalog() async {
    final res = await http.get(Uri.parse('$baseUrl/api/plant-catalog'));
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getRecommendations({String? city, String? homeType}) async {
    final params = <String, String>{};
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (homeType != null && homeType.isNotEmpty) params['home_type'] = homeType;
    final qs = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final res = await http.get(Uri.parse('$baseUrl/api/plants/recommendations$qs'));
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<String>> getCities() async {
    final res = await http.get(Uri.parse('$baseUrl/api/cities'));
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  static Future<List<String>> getHomeTypes() async {
    final res = await http.get(Uri.parse('$baseUrl/api/home-types'));
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  static Future<void> updateUser(int userId, Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('$baseUrl/api/users/$userId'),
      headers: _jsonHeadersWithUser(),
      body: jsonEncode(data),
    );
  }

  static Future<void> updatePlant(int plantId, Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('$baseUrl/api/plants/$plantId'),
      headers: _jsonHeadersWithUser(),
      body: jsonEncode(data),
    );
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(Uri.parse('$baseUrl/api/admin/stats'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getUpcomingCare(int? userId) async {
    final q = userId != null ? '?user_id=$userId' : '';
    final res = await http.get(Uri.parse('$baseUrl/api/plants/upcoming-care$q'));
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> logLightPlant(int plantId) async {
    await http.post(
      Uri.parse('$baseUrl/api/plants/$plantId/light'),
      headers: _jsonHeadersWithUser(),
      body: '{}',
    );
  }

  static Future<Map<String, dynamic>> getSmartSummary(int userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/user/smart-summary?user_id=$userId'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// تقرير عناية كل النباتات (للطباعة من التطبيق). يعتمد على [X-User-Id] عند عدم وجود جلسة ويب.
  static Future<Map<String, dynamic>> getPlantsCareReport({int? forUserId}) async {
    final q = forUserId != null ? '?user_id=$forUserId' : '';
    final res = await http.get(
      Uri.parse('$baseUrl/api/plants/care-report$q'),
      headers: _jsonHeadersWithUser(),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      final err = body is Map<String, dynamic> ? body['error'] : null;
      throw Exception(err?.toString() ?? 'تعذر تحميل التقرير');
    }
    return body as Map<String, dynamic>;
  }
}
