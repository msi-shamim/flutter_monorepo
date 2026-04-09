import '../project_config.dart';

String networkPubspec(ProjectConfig c) {
  final dep = switch (c.httpClient) {
    HttpClient.dio => 'dio: ^5.8.0+1',
    HttpClient.http => 'http: ^1.3.0',
    HttpClient.chopper => 'chopper: ^8.0.0+1',
  };
  return '''
name: ${c.network}
description: Network layer for ${c.pascal} — HTTP clients, interceptors, API services.
publish_to: 'none'
version: 0.1.0
resolution: workspace

environment:
  sdk: ^3.10.4

dependencies:
  flutter:
    sdk: flutter
  $dep
  ${c.core}:
    path: ../core

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
''';
}

String networkBarrel() => '''
export 'client/api_client.dart';
export 'interceptors/auth_interceptor.dart';
export 'interceptors/logging_interceptor.dart';
''';

// ═════════════════════════════════════════════════════════
// ── API CLIENT ──────────────────────────────────────────
// ═════════════════════════════════════════════════════════

String apiClient(ProjectConfig c) => switch (c.httpClient) {
      HttpClient.dio => _dioApiClient(c),
      HttpClient.http => _httpApiClient(c),
      HttpClient.chopper => _chopperApiClient(c),
    };

String _dioApiClient(ProjectConfig c) => '''
import 'package:dio/dio.dart';
import 'package:${c.core}/${c.core}.dart';

import '../interceptors/logging_interceptor.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    List<Interceptor> interceptors = const [],
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          ),
        )..interceptors.addAll([...interceptors, LoggingInterceptor()]);

  final Dio _dio;
  Dio get dio => _dio;

  Future<Result<T>> get<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: queryParameters);
      return Result.success(fromJson(response.data!));
    } on DioException catch (e) { return Result.failure(_mapError(e)); }
  }

  Future<Result<List<T>>> getList<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<List<dynamic>>(path, queryParameters: queryParameters);
      return Result.success(response.data!.cast<Map<String, dynamic>>().map(fromJson).toList());
    } on DioException catch (e) { return Result.failure(_mapError(e)); }
  }

  Future<Result<T>> post<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Object? data}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return Result.success(fromJson(response.data!));
    } on DioException catch (e) { return Result.failure(_mapError(e)); }
  }

  Future<Result<T>> put<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Object? data}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(path, data: data);
      return Result.success(fromJson(response.data!));
    } on DioException catch (e) { return Result.failure(_mapError(e)); }
  }

  Future<Result<void>> delete(String path) async {
    try {
      await _dio.delete<void>(path);
      return const Result.success(null);
    } on DioException catch (e) { return Result.failure(_mapError(e)); }
  }

  AppException _mapError(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout || DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout => const TimeoutException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.badResponse => ApiException(e.response?.statusMessage ?? 'Request failed', statusCode: e.response?.statusCode),
    _ => ApiException(e.message ?? 'Unknown error'),
  };
}
''';

String _httpApiClient(ProjectConfig c) => '''
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:${c.core}/${c.core}.dart';

import '../interceptors/logging_interceptor.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = LoggingClient(inner: client ?? http.Client());

  final String baseUrl;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Result<T>> get<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Map<String, dynamic>? queryParameters}) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _client.get(uri, headers: _headers);
      return _handleResponse(response, fromJson);
    } on SocketException {
      return const Result.failure(NetworkException());
    } on http.ClientException catch (e) {
      return Result.failure(ApiException(e.message));
    }
  }

  Future<Result<List<T>>> getList<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Map<String, dynamic>? queryParameters}) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
        return Result.success(list.map(fromJson).toList());
      }
      return Result.failure(ApiException(response.reasonPhrase ?? 'Request failed', statusCode: response.statusCode));
    } on SocketException {
      return const Result.failure(NetworkException());
    } on http.ClientException catch (e) {
      return Result.failure(ApiException(e.message));
    }
  }

  Future<Result<T>> post<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Object? data}) async {
    try {
      final response = await _client.post(_buildUri(path), headers: _headers, body: data != null ? jsonEncode(data) : null);
      return _handleResponse(response, fromJson);
    } on SocketException {
      return const Result.failure(NetworkException());
    } on http.ClientException catch (e) {
      return Result.failure(ApiException(e.message));
    }
  }

  Future<Result<T>> put<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Object? data}) async {
    try {
      final response = await _client.put(_buildUri(path), headers: _headers, body: data != null ? jsonEncode(data) : null);
      return _handleResponse(response, fromJson);
    } on SocketException {
      return const Result.failure(NetworkException());
    } on http.ClientException catch (e) {
      return Result.failure(ApiException(e.message));
    }
  }

  Future<Result<void>> delete(String path) async {
    try {
      final response = await _client.delete(_buildUri(path), headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Result.success(null);
      }
      return Result.failure(ApiException(response.reasonPhrase ?? 'Request failed', statusCode: response.statusCode));
    } on SocketException {
      return const Result.failure(NetworkException());
    } on http.ClientException catch (e) {
      return Result.failure(ApiException(e.message));
    }
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse('\$baseUrl\$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  Result<T> _handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Result.success(fromJson(jsonDecode(response.body) as Map<String, dynamic>));
    }
    return Result.failure(ApiException(response.reasonPhrase ?? 'Request failed', statusCode: response.statusCode));
  }
}
''';

String _chopperApiClient(ProjectConfig c) => '''
import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:${c.core}/${c.core}.dart';

import '../interceptors/logging_interceptor.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    List<Interceptor> interceptors = const [],
  }) : _client = ChopperClient(
          baseUrl: Uri.parse(baseUrl),
          interceptors: [
            ...interceptors,
            LoggingInterceptor(),
          ],
          converter: const JsonConverter(),
        );

  final ChopperClient _client;
  ChopperClient get client => _client;

  Future<Result<T>> get<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Map<String, dynamic>? queryParameters}) async {
    try {
      final request = Request('GET', Uri.parse(path), _client.baseUrl, parameters: queryParameters ?? {});
      final response = await _client.send<dynamic, dynamic>(request);
      return _handleResponse(response, fromJson);
    } on Exception catch (e) {
      return Result.failure(ApiException(e.toString()));
    }
  }

  Future<Result<List<T>>> getList<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Map<String, dynamic>? queryParameters}) async {
    try {
      final request = Request('GET', Uri.parse(path), _client.baseUrl, parameters: queryParameters ?? {});
      final response = await _client.send<dynamic, dynamic>(request);
      if (response.isSuccessful) {
        final list = (response.body as List).cast<Map<String, dynamic>>();
        return Result.success(list.map(fromJson).toList());
      }
      return Result.failure(ApiException(response.error?.toString() ?? 'Request failed', statusCode: response.statusCode));
    } on Exception catch (e) {
      return Result.failure(ApiException(e.toString()));
    }
  }

  Future<Result<T>> post<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Object? data}) async {
    try {
      final request = Request('POST', Uri.parse(path), _client.baseUrl, body: data != null ? jsonEncode(data) : null);
      final response = await _client.send<dynamic, dynamic>(request);
      return _handleResponse(response, fromJson);
    } on Exception catch (e) {
      return Result.failure(ApiException(e.toString()));
    }
  }

  Future<Result<T>> put<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Object? data}) async {
    try {
      final request = Request('PUT', Uri.parse(path), _client.baseUrl, body: data != null ? jsonEncode(data) : null);
      final response = await _client.send<dynamic, dynamic>(request);
      return _handleResponse(response, fromJson);
    } on Exception catch (e) {
      return Result.failure(ApiException(e.toString()));
    }
  }

  Future<Result<void>> delete(String path) async {
    try {
      final request = Request('DELETE', Uri.parse(path), _client.baseUrl);
      final response = await _client.send<dynamic, dynamic>(request);
      if (response.isSuccessful) return const Result.success(null);
      return Result.failure(ApiException(response.error?.toString() ?? 'Request failed', statusCode: response.statusCode));
    } on Exception catch (e) {
      return Result.failure(ApiException(e.toString()));
    }
  }

  Result<T> _handleResponse<T>(Response<dynamic> response, T Function(Map<String, dynamic>) fromJson) {
    if (response.isSuccessful) {
      return Result.success(fromJson(response.body as Map<String, dynamic>));
    }
    return Result.failure(ApiException(response.error?.toString() ?? 'Request failed', statusCode: response.statusCode));
  }
}
''';

// ═════════════════════════════════════════════════════════
// ── AUTH INTERCEPTOR ────────────────────────────────────
// ═════════════════════════════════════════════════════════

String authInterceptor(ProjectConfig c) => switch (c.httpClient) {
      HttpClient.dio => _dioAuthInterceptor(),
      HttpClient.http => _httpAuthInterceptor(),
      HttpClient.chopper => _chopperAuthInterceptor(),
    };

String _dioAuthInterceptor() => r'''
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenProvider});
  final Future<String?> Function() tokenProvider;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
''';

String _httpAuthInterceptor() => r'''
import 'package:http/http.dart' as http;

/// Wraps an [http.Client] to inject the Authorization header.
class AuthInterceptor extends http.BaseClient {
  AuthInterceptor({required this.inner, required this.tokenProvider});

  final http.Client inner;
  final Future<String?> Function() tokenProvider;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return inner.send(request);
  }
}
''';

String _chopperAuthInterceptor() => r'''
import 'dart:async';

import 'package:chopper/chopper.dart';

class AuthInterceptor implements Interceptor {
  AuthInterceptor({required this.tokenProvider});
  final Future<String?> Function() tokenProvider;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final token = await tokenProvider();
    Request request = chain.request;
    if (token != null && token.isNotEmpty) {
      request = applyHeader(request, 'Authorization', 'Bearer $token');
    }
    return chain.proceed(request);
  }
}
''';

// ═════════════════════════════════════════════════════════
// ── LOGGING INTERCEPTOR ─────────────────────────────────
// ═════════════════════════════════════════════════════════

String loggingInterceptor(ProjectConfig c) => switch (c.httpClient) {
      HttpClient.dio => _dioLoggingInterceptor(),
      HttpClient.http => _httpLoggingInterceptor(),
      HttpClient.chopper => _chopperLoggingInterceptor(),
    };

String _dioLoggingInterceptor() => r'''
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log('→ ${options.method} ${options.uri}', name: 'HTTP');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    developer.log('← ${response.statusCode} ${response.requestOptions.uri}', name: 'HTTP');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log('✗ ${err.response?.statusCode ?? "NO_STATUS"} ${err.requestOptions.uri} — ${err.message}', name: 'HTTP', level: 1000);
    handler.next(err);
  }
}
''';

String _httpLoggingInterceptor() => r'''
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// Wraps an [http.Client] to log requests and responses.
class LoggingClient extends http.BaseClient {
  LoggingClient({required this.inner});
  final http.Client inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    developer.log('→ ${request.method} ${request.url}', name: 'HTTP');
    try {
      final response = await inner.send(request);
      developer.log('← ${response.statusCode} ${request.url}', name: 'HTTP');
      return response;
    } catch (e) {
      developer.log('✗ ${request.url} — $e', name: 'HTTP', level: 1000);
      rethrow;
    }
  }
}
''';

String _chopperLoggingInterceptor() => r'''
import 'dart:async';
import 'dart:developer' as developer;

import 'package:chopper/chopper.dart';

class LoggingInterceptor implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final request = chain.request;
    developer.log('→ ${request.method} ${request.url}', name: 'HTTP');
    try {
      final response = await chain.proceed(request);
      developer.log('← ${response.statusCode} ${request.url}', name: 'HTTP');
      return response;
    } catch (e) {
      developer.log('✗ ${request.url} — $e', name: 'HTTP', level: 1000);
      rethrow;
    }
  }
}
''';

// ═════════════════════════════════════════════════════════
// ── DOCS ────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════

String networkPackageMd(ProjectConfig c) {
  final clientName = switch (c.httpClient) {
    HttpClient.dio => 'Dio',
    HttpClient.http => 'http',
    HttpClient.chopper => 'Chopper',
  };
  return '''
# ${c.network}

$clientName-based HTTP layer. Depends on `${c.core}` for exceptions and Result type.

## What belongs here

- `ApiClient` ($clientName wrapper returning `Result<T>`)
- Interceptors (auth, logging)
- Repository implementations in `repositories/`

## What is PROHIBITED

- GetX, Flutter widgets, business logic, localization
''';
}
