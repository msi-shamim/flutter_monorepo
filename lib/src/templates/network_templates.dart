import '../project_config.dart';

String networkPubspec(ProjectConfig c) => '''
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
  dio: ^5.8.0+1
  ${c.core}:
    path: ../core

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
''';

String networkBarrel() => '''
export 'client/api_client.dart';
export 'interceptors/auth_interceptor.dart';
export 'interceptors/logging_interceptor.dart';
''';

String apiClient(ProjectConfig c) => '''
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
    } on DioException catch (e) { return Result.failure(_mapDioError(e)); }
  }

  Future<Result<List<T>>> getList<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<List<dynamic>>(path, queryParameters: queryParameters);
      return Result.success(response.data!.cast<Map<String, dynamic>>().map(fromJson).toList());
    } on DioException catch (e) { return Result.failure(_mapDioError(e)); }
  }

  Future<Result<T>> post<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Object? data}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return Result.success(fromJson(response.data!));
    } on DioException catch (e) { return Result.failure(_mapDioError(e)); }
  }

  Future<Result<T>> put<T>(String path, {required T Function(Map<String, dynamic>) fromJson, Object? data}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(path, data: data);
      return Result.success(fromJson(response.data!));
    } on DioException catch (e) { return Result.failure(_mapDioError(e)); }
  }

  Future<Result<void>> delete(String path) async {
    try {
      await _dio.delete<void>(path);
      return const Result.success(null);
    } on DioException catch (e) { return Result.failure(_mapDioError(e)); }
  }

  AppException _mapDioError(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout || DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout => const TimeoutException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.badResponse => ApiException(e.response?.statusMessage ?? 'Request failed', statusCode: e.response?.statusCode),
    _ => ApiException(e.message ?? 'Unknown error'),
  };
}
''';

String authInterceptor() => r'''
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

String loggingInterceptor() => r'''
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

String networkPackageMd(ProjectConfig c) => '''
# ${c.network}

Dio-based HTTP layer. Depends on `${c.core}` for exceptions and Result type.

## What belongs here

- `ApiClient` (Dio wrapper returning `Result<T>`)
- Interceptors (auth, logging)
- Repository implementations in `repositories/`

## What is PROHIBITED

- GetX, Flutter widgets, business logic, localization
''';
