import '../project_config.dart';
import '../version.dart';

String corePubspec(ProjectConfig c) => '''
name: ${c.core}
description: Core shared logic for ${c.pascal}.
publish_to: 'none'
version: 0.1.0
resolution: workspace

environment:
  sdk: $generatedSdkConstraint

dev_dependencies:
  test: ${c.versions['test']}
  flutter_lints: ${c.versions['flutter_lints']}
''';

/// Starter test proving core is testable with `dart test` and no Flutter.
String coreStarterTest(ProjectConfig c) => '''
import 'package:${c.core}/${c.core}.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('success carries its data', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d, failure: (_) => -1), 42);
    });

    test('failure carries its exception', () {
      const result = Result<int>.failure(NetworkException());
      expect(result.isFailure, isTrue);
      expect(
        result.when(success: (_) => '', failure: (e) => e.message),
        'No internet connection',
      );
    });

    test('map transforms success and passes failure through', () {
      expect(const Result<int>.success(2).map((d) => d * 2).isSuccess, isTrue);
      expect(
        const Result<int>.failure(NetworkException()).map((d) => d * 2).isFailure,
        isTrue,
      );
    });
  });

  group('String extensions', () {
    test('capitalized upper-cases the first character', () {
      expect('hello'.capitalized, 'Hello');
    });

    test('isValidEmail accepts and rejects', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('not-an-email'.isValidEmail, isFalse);
    });
  });
}
''';

String coreBarrel(ProjectConfig c) => '''
// ── Exceptions ───────────────────────────────────────────
export 'exceptions/app_exception.dart';

// ── Models ───────────────────────────────────────────────
export 'models/base_model.dart';

// ── Repositories ─────────────────────────────────────────
export 'repositories/base_repository.dart';

// ── Use Cases ────────────────────────────────────────────
export 'usecases/use_case.dart';

// ── Utils ────────────────────────────────────────────────
export 'utils/result.dart';

// ── Extensions ───────────────────────────────────────────
export 'extensions/string_extensions.dart';
export 'extensions/date_extensions.dart';
export 'extensions/list_extensions.dart';
''';

String appException() => '''
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AppException(\$code): \$message';
}

class ApiException extends AppException {
  const ApiException(super.message, {super.code, this.statusCode});
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiException(\$statusCode, \$code): \$message';
}

class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, this.field});
  final String? field;

  @override
  String toString() => 'ValidationException(\$field): \$message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out']);
}
''';

String baseModel() => r'''
abstract class BaseModel {
  const BaseModel();

  Map<String, dynamic> toJson();
  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseModel &&
          runtimeType == other.runtimeType &&
          _listEquals(props, other.props);

  @override
  int get hashCode => Object.hashAll(props);

  static bool _listEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
''';

String baseRepository() => '''
abstract class BaseRepository {
  const BaseRepository();
}
''';

String useCase(ProjectConfig c) => '''
import 'package:${c.core}/utils/result.dart';

abstract class UseCase<T, P> {
  const UseCase();
  Future<Result<T>> call(P params);
}

abstract class NoParamUseCase<T> {
  const NoParamUseCase();
  Future<Result<T>> call();
}
''';

String result(ProjectConfig c) => '''
import 'package:${c.core}/exceptions/app_exception.dart';

sealed class Result<T> {
  const Result._();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppException exception) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success(:final data) => Result.success(transform(data)),
        Failure(:final exception) => Result.failure(exception),
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) =>
      switch (this) {
        Success(:final data) => success(data),
        Failure(:final exception) => failure(exception),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.data) : super._();
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.exception) : super._();
  final AppException exception;
}
''';

String stringExtensions() => r'''
extension StringExtensions on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase =>
      split(' ').map((word) => word.capitalized).join(' ');

  String? get nullIfEmpty => isEmpty ? null : this;

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  String truncate(int maxLength, {String suffix = '...'}) =>
      length <= maxLength ? this : '${substring(0, maxLength)}$suffix';
}
''';

String dateExtensions() => '''
extension DateExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  DateTime get dateOnly => DateTime(year, month, day);

  int daysFrom(DateTime other) =>
      dateOnly.difference(other.dateOnly).inDays;
}
''';

String listExtensions() => '''
extension ListExtensions<T> on List<T> {
  T? elementAtOrNull(int index) =>
      (index >= 0 && index < length) ? this[index] : null;

  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension NullableListExtensions<T> on List<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;
  List<T> get orEmpty => this ?? [];
}
''';

String corePackageMd(ProjectConfig c) => '''
# ${c.core}

Shared business logic, models, and utilities — **framework-free**, **UI-free**.

## What belongs here

- Exception hierarchy (`AppException` sealed class)
- `Result<T>` type for type-safe error handling
- `BaseModel` for entities
- Repository interfaces (abstract)
- Use cases (`UseCase<T,P>`, `NoParamUseCase<T>`)
- Business rules in `rules/`
- Companion states for UI components in `states/` (validation, selection, upload progress)
- Extensions (String, DateTime, List)

## What is PROHIBITED

- GetX, Flutter widgets, HTTP clients, localization, UI code
''';
