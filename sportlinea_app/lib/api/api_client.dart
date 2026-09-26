import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class HomeData {
  HomeData({required this.lineEmpty, required this.totalActive, required this.top, required this.newest});
  final bool lineEmpty;
  final int totalActive;
  final List<SportEventDto> top;
  final List<SportEventDto> newest;
}

class LineData {
  LineData({
    required this.events,
    required this.sports,
    required this.categories,
    required this.totalActive,
    this.selectedSport,
    this.selectedCategory,
  });
  final List<SportEventDto> events;
  final List<String> sports;
  final List<String> categories;
  final int totalActive;
  final String? selectedSport;
  final String? selectedCategory;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static const _tokenKey = 'jwt';
  String? token;

  static const _apiFromEnv = String.fromEnvironment('API_URL');

  String get baseUrl {
    if (_apiFromEnv.isNotEmpty) return _apiFromEnv;
    if (kIsWeb) return 'http://localhost:5207';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5207';
      default:
        return 'http://localhost:5207';
    }
  }

  Future<void> loadToken() async {
    token = (await SharedPreferences.getInstance()).getString(_tokenKey);
  }

  Future<void> _saveToken(String? value) async {
    token = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
  }

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (isLoggedIn) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<Map<String, dynamic>> _json(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    late http.Response res;
    try {
      res = method == 'GET'
          ? await http.get(uri, headers: _headers)
          : method == 'PUT'
              ? await http.put(uri, headers: _headers, body: jsonEncode(body))
              : await http.post(uri, headers: _headers, body: body == null ? null : jsonEncode(body));
    } catch (_) {
      throw ApiException('Нет связи с сервером ($baseUrl). Запустите АРМ «СпортЛиния» на порту 5207.');
    }
    Map<String, dynamic>? json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    if (res.statusCode == 401) {
      await _saveToken(null);
      throw ApiException(json?['message']?.toString() ?? 'Нужно войти снова', statusCode: 401);
    }
    if (res.statusCode >= 400) {
      throw ApiException(json?['message']?.toString() ?? 'Ошибка ${res.statusCode}', statusCode: res.statusCode);
    }
    if (json?['success'] == false) {
      throw ApiException(json?['message']?.toString() ?? 'Ошибка', statusCode: res.statusCode);
    }
    return json ?? {};
  }

  Future<Player> login(String email, String password) async {
    final json = await _json('POST', '/api/auth/login', body: {'email': email.trim(), 'password': password});
    final data = json['data'] as Map<String, dynamic>;
    await _saveToken(data['token']?.toString());
    return Player.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<Player> register(Map<String, dynamic> body) async {
    final json = await _json('POST', '/api/auth/register', body: body);
    final data = json['data'] as Map<String, dynamic>;
    await _saveToken(data['token']?.toString());
    return Player.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() => _saveToken(null);

  Future<Player> me() async {
    final json = await _json('GET', '/api/auth/me');
    return Player.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<HomeData> home() async {
    final json = await _json('GET', '/api/home');
    final data = json['data'] as Map<String, dynamic>;
    List<SportEventDto> list(String k) =>
        (data[k] as List<dynamic>? ?? []).map((e) => SportEventDto.fromJson(e as Map<String, dynamic>)).toList();
    return HomeData(
      lineEmpty: data['lineEmpty'] == true,
      totalActive: (data['totalActive'] as num?)?.toInt() ?? 0,
      top: list('topEvents'),
      newest: list('newEvents'),
    );
  }

  Future<LineData> line({String? sport, String? category}) async {
    final q = <String>[];
    if (sport != null) q.add('sport=${Uri.encodeQueryComponent(sport)}');
    if (category != null) q.add('category=${Uri.encodeQueryComponent(category)}');
    final json = await _json('GET', '/api/line${q.isEmpty ? '' : '?${q.join('&')}'}');
    final data = json['data'] as Map<String, dynamic>;
    return LineData(
      events: (data['events'] as List<dynamic>? ?? []).map((e) => SportEventDto.fromJson(e as Map<String, dynamic>)).toList(),
      sports: (data['sports'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      categories: (data['categories'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      totalActive: (data['totalActive'] as num?)?.toInt() ?? 0,
      selectedSport: data['selectedSport']?.toString(),
      selectedCategory: data['selectedCategory']?.toString(),
    );
  }

  Future<String> refreshLine() async {
    final json = await _json('POST', '/api/line/refresh');
    return json['message']?.toString() ?? 'Линия обновлена';
  }

  Future<({SportEventDto event, double? freeBet})> event(int id) async {
    final json = await _json('GET', '/api/events/$id');
    final data = json['data'] as Map<String, dynamic>;
    final evt = SportEventDto.fromJson((data['evt'] ?? data) as Map<String, dynamic>);
    final fb = data['freeBet'] as Map<String, dynamic>?;
    return (event: evt, freeBet: (fb?['amount'] as num?)?.toDouble());
  }

  Future<({String message, bool isWin, String? bonusMessage})> placeBet({
    required int coefficientId,
    required double amount,
    bool useFreeBet = false,
  }) async {
    final json = await _json('POST', '/api/bets', body: {
      'coefficientId': coefficientId,
      'amount': amount,
      'useFreeBet': useFreeBet,
    });
    final data = json['data'] as Map<String, dynamic>?;
    final message = json['message']?.toString() ?? 'Ставка принята';
    final rawWin = data?['isWin'];
    final isWin = rawWin == true
        ? true
        : rawWin == false
            ? false
            : !message.toLowerCase().contains('проиграла');
    final bonus = data?['bonusMessage']?.toString();
    return (
      message: message,
      isWin: isWin,
      bonusMessage: (bonus == null || bonus.isEmpty) ? null : bonus,
    );
  }

  Future<List<BetDto>> bets({String? status}) async {
    final json = await _json('GET', '/api/bets${status == null ? '' : '?status=$status'}');
    return (json['data'] as List<dynamic>).map((e) => BetDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SportEventDto>> results() async {
    final json = await _json('GET', '/api/results');
    return (json['data'] as List<dynamic>).map((e) => SportEventDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> rating() async {
    final json = await _json('GET', '/api/rating');
    return (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> profile() async {
    final json = await _json('GET', '/api/profile');
    return json['data'] as Map<String, dynamic>;
  }

  Future<String> editProfile(Map<String, dynamic> body) async {
    final json = await _json('PUT', '/api/profile', body: body);
    return json['message']?.toString() ?? 'Профиль обновлён';
  }

  Future<String> deposit(double amount) async {
    final json = await _json('POST', '/api/profile/deposit', body: {'amount': amount});
    return json['message']?.toString() ?? 'Счёт пополнен';
  }

  Future<String> withdraw(double amount) async {
    final json = await _json('POST', '/api/profile/withdraw', body: {'amount': amount});
    return json['message']?.toString() ?? 'Заявка отправлена';
  }

  Future<Map<String, dynamic>> bonuses() async {
    final json = await _json('GET', '/api/bonuses');
    return json['data'] as Map<String, dynamic>;
  }

  Future<String> activateBonus(int id) async {
    final json = await _json('POST', '/api/bonuses/$id/activate');
    return json['message']?.toString() ?? 'Бонус активирован';
  }

  Future<List<Map<String, dynamic>>> notifications() async {
    final json = await _json('GET', '/api/notifications');
    return (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
