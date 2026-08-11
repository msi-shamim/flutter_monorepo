import '../project_config.dart';

/// The app-side implementation of core's `KeyValueStore`.
///
/// Every backend loads into memory during `init()` so `read` can be
/// synchronous, which is what lets theme and locale state restore during
/// construction rather than after a frame.
String keyValueStoreImpl(ProjectConfig c) => switch (c.storage) {
  StorageBackend.getStorage => _getStorageImpl(c),
  StorageBackend.sharedPrefs => _sharedPrefsImpl(c),
  StorageBackend.hive => _hiveImpl(c),
};

/// The file name for the generated implementation.
String keyValueStoreFileName(ProjectConfig c) => switch (c.storage) {
  StorageBackend.getStorage => 'get_storage_store.dart',
  StorageBackend.sharedPrefs => 'shared_prefs_store.dart',
  StorageBackend.hive => 'hive_store.dart',
};

/// The class name of the generated implementation.
String keyValueStoreClass(ProjectConfig c) => switch (c.storage) {
  StorageBackend.getStorage => 'GetStorageStore',
  StorageBackend.sharedPrefs => 'SharedPrefsStore',
  StorageBackend.hive => 'HiveStore',
};

String _getStorageImpl(ProjectConfig c) =>
    '''
import 'package:get_storage/get_storage.dart';
import 'package:${c.core}/${c.core}.dart';

/// [KeyValueStore] backed by GetStorage.
class GetStorageStore implements KeyValueStore {
  late final GetStorage _box;

  @override
  Future<void> init() async {
    await GetStorage.init();
    _box = GetStorage();
  }

  @override
  T? read<T>(String key) => _box.read<T>(key);

  @override
  Future<void> write(String key, Object? value) => _box.write(key, value);

  @override
  Future<void> delete(String key) => _box.remove(key);

  @override
  Future<void> clear() => _box.erase();

  @override
  Future<void> close() async {
    // GetStorage keeps no handle to release.
  }
}
''';

String _sharedPrefsImpl(ProjectConfig c) =>
    '''
import 'package:shared_preferences/shared_preferences.dart';
import 'package:${c.core}/${c.core}.dart';

/// [KeyValueStore] backed by shared_preferences.
///
/// Uses the caching API so reads are synchronous; the plain async API cannot
/// satisfy [KeyValueStore.read].
class SharedPrefsStore implements KeyValueStore {
  late final SharedPreferencesWithCache _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }

  @override
  T? read<T>(String key) {
    final value = _prefs.get(key);
    return value is T ? value : null;
  }

  @override
  Future<void> write(String key, Object? value) async {
    switch (value) {
      case null:
        await _prefs.remove(key);
      case final int v:
        await _prefs.setInt(key, v);
      case final double v:
        await _prefs.setDouble(key, v);
      case final bool v:
        await _prefs.setBool(key, v);
      case final String v:
        await _prefs.setString(key, v);
      case final List<String> v:
        await _prefs.setStringList(key, v);
      default:
        throw ArgumentError.value(
          value,
          'value',
          'shared_preferences stores int, double, bool, String or List<String>',
        );
    }
  }

  @override
  Future<void> delete(String key) => _prefs.remove(key);

  @override
  Future<void> clear() => _prefs.clear();

  @override
  Future<void> close() async {
    // Nothing to release.
  }
}
''';

String _hiveImpl(ProjectConfig c) =>
    '''
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:${c.core}/${c.core}.dart';

/// [KeyValueStore] backed by hive_ce.
///
/// hive_ce is the maintained fork: `hive` itself declares `sdk <3.0.0` and
/// cannot resolve on Dart 3.
class HiveStore implements KeyValueStore {
  static const _boxName = '${c.name}_store';

  late final Box<dynamic> _box;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  @override
  T? read<T>(String key) {
    final value = _box.get(key);
    return value is T ? value : null;
  }

  @override
  Future<void> write(String key, Object? value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  @override
  Future<void> close() => _box.close();
}
''';

/// Adapter exposing a [KeyValueStore] as hydrated_bloc's `Storage`.
///
/// Generated for Bloc and Cubit only. It replaces `HydratedStorage` so the
/// whole project persists through one backend rather than two.
String hydratedStorageAdapter(ProjectConfig c) =>
    '''
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:${c.core}/${c.core}.dart';

/// Bridges hydrated_bloc's Storage onto the project's [KeyValueStore], so
/// bloc hydration and everything else share one backend.
class KeyValueHydratedStorage implements Storage {
  /// Wraps [store], which must already be initialised.
  const KeyValueHydratedStorage(this._store);

  final KeyValueStore _store;

  @override
  dynamic read(String key) => _store.read<dynamic>(key);

  @override
  Future<void> write(String key, dynamic value) =>
      _store.write(key, value);

  @override
  Future<void> delete(String key) => _store.delete(key);

  @override
  Future<void> clear() => _store.clear();

  @override
  Future<void> close() => _store.close();
}
''';

/// The pubspec dependency lines this backend needs.
String storageDependency(ProjectConfig c) => switch (c.storage) {
  StorageBackend.getStorage => '  get_storage: ${c.versions['get_storage']}\n',
  StorageBackend.sharedPrefs =>
    '  shared_preferences: ${c.versions['shared_preferences']}\n',
  StorageBackend.hive =>
    '  hive_ce: ${c.versions['hive_ce']}\n'
        '  hive_ce_flutter: ${c.versions['hive_ce_flutter']}\n',
};

/// The app's single store instance and its initialiser.
///
/// One place names the backend; everything else uses [KeyValueStore].
String appStore(ProjectConfig c) {
  final cls = keyValueStoreClass(c);
  return '''
import 'package:${c.core}/${c.core}.dart';

import '${keyValueStoreFileName(c)}';

/// The app's key-value store. Valid only after [initAppStore] completes.
late final KeyValueStore appStore;

/// Creates and initialises [appStore].
///
/// Swapping backend is a change to this file alone: nothing else names
/// $cls.
Future<void> initAppStore() async {
  final store = $cls();
  await store.init();
  appStore = store;
}
''';
}

/// Dev dependencies the generated test setup needs for this backend.
String storageTestDependencies(ProjectConfig c) => switch (c.storage) {
  StorageBackend.getStorage || StorageBackend.hive =>
    '  path_provider_platform_interface: any\n'
        '  plugin_platform_interface: any\n',
  StorageBackend.sharedPrefs =>
    '  shared_preferences_platform_interface: any\n',
};

/// `test/flutter_test_config.dart` for the app package.
///
/// Runs automatically before every test in the directory. Theme and locale
/// state read the store as they build, and storage plugins are not registered
/// under `flutter test`, so without this any widget test that pumps the app
/// fails before rendering a frame. The substitute depends on the backend, not
/// on the state management choice.
String storageTestSetup(ProjectConfig c) {
  // Bloc and Cubit hydrate through HydratedBloc, which main() wires after the
  // store is created. Tests never call main(), so the config must do the same
  // or every bloc throws StorageNotFound before a frame renders.
  final hydrated =
      c.stateManagement == StateManagement.bloc ||
      c.stateManagement == StateManagement.cubit;
  final hydratedImport = hydrated
      ? "import 'package:hydrated_bloc/hydrated_bloc.dart';\n"
            "import 'package:${c.app}/app/storage/hydrated_store.dart';\n"
      : '';
  final hydratedInit = hydrated
      ? '  HydratedBloc.storage = KeyValueHydratedStorage(appStore);\n'
      : '';

  final body = switch (c.storage) {
    StorageBackend.getStorage || StorageBackend.hive =>
      '''
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

${hydratedImport}import 'package:${c.app}/app/storage/app_store.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('app_test_storage');
  PathProviderPlatform.instance = _TestPathProvider(dir.path);
  await initAppStore();
$hydratedInit  await testMain();

  // Best effort: the store keeps its file open, and on Windows deleting an
  // open file fails and would surface as a test failure.
  try {
    dir.deleteSync(recursive: true);
  } on FileSystemException {
    // A leftover temp directory is not worth failing a test run over.
  }
}

class _TestPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _TestPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}
''',
    StorageBackend.sharedPrefs =>
      '''
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

${hydratedImport}import 'package:${c.app}/app/storage/app_store.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  await initAppStore();
$hydratedInit  await testMain();
}
''',
  };

  return "import 'dart:async';\n$body";
}
