import '../project_config.dart';

/// The authenticated user, in core so nothing outside depends on a provider's
/// own user type.
String authUser(ProjectConfig c) => '''
/// A signed-in user, independent of which provider authenticated them.
class AuthUser {
  /// Creates a user record.
  const AuthUser({required this.id, this.email, this.displayName});

  /// Provider-assigned unique id.
  final String id;

  /// Email address, when the provider exposes one.
  final String? email;

  /// Display name, when the provider exposes one.
  final String? displayName;

  @override
  String toString() => 'AuthUser(\$id, \$email)';
}
''';

/// The authentication contract, in core alongside the other interfaces.
String authRepository(ProjectConfig c) =>
    '''
import 'package:${c.core}/models/auth_user.dart';
import 'package:${c.core}/utils/result.dart';

/// Authentication boundary.
///
/// Screens and route guards depend on this, never on a provider SDK, so
/// swapping provider does not reach beyond its implementation.
abstract interface class AuthRepository {
  /// The user currently signed in, or null.
  AuthUser? get currentUser;

  /// Emits on every sign-in and sign-out.
  Stream<AuthUser?> authStateChanges();

  /// Signs in with email and password.
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  });

  /// Registers a new account.
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
  });

  /// Signs the current user out.
  Future<Result<void>> signOut();
}
''';

/// What the generated auth scaffolding does, and what you must finish.
String authDoc(ProjectConfig c) {
  final providerSection = switch (c.auth) {
    AuthProvider.custom =>
      '''
## Custom (token against your own API)

Session handling is complete: the token is persisted through the project's
`KeyValueStore`, restored on launch, and sign-in state is broadcast.

Two things are left to you, both marked `TODO` in
`lib/app/auth/token_auth_repository.dart`:

1. `signIn` — call your API and use the token and user it returns.
2. `signUp` — call your registration endpoint.

Until then sign-in accepts any non-empty email and password and stores a
placeholder token, so the flow is navigable while you build the backend.
''',
    AuthProvider.firebase =>
      '''
## Firebase

`lib/app/auth/firebase_options.dart` holds placeholders. Replace them with
your project's real values:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

That command rewrites `firebase_options.dart` and adds the platform config
files Firebase needs — `google-services.json` on Android and
`GoogleService-Info.plist` on iOS.

**Android builds require those files.** Run `flutterfire configure` before
`flutter build apk`, or the Gradle build will fail. The Dart code compiles
and the widget tests pass without it, which is why generation succeeds.
''',
    AuthProvider.supabase =>
      '''
## Supabase

Set your project's credentials in `lib/app/auth/supabase_config.dart`:

```dart
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseAnonKey = 'your-anon-key';
```

Both are in your Supabase dashboard under Project Settings → API. The anon
key is designed to be shipped in a client; it is not a secret.

No platform config files are needed, so the app builds and runs before you
set these — sign-in simply fails until you do.
''',
    AuthProvider.none => '',
  };

  return '''
# Authentication

Auth is wired the same way as storage: a contract in `packages/core`, one
implementation in the app, and a single file that names the provider.

| Piece | Where |
|-------|-------|
| `AuthRepository`, `AuthUser`, `AuthException` | `packages/core` |
| Implementation | `${c.app}/lib/app/auth/${authImplFileName(c)}` |
| Wiring | `${c.app}/lib/app/auth/auth.dart` |
| Login screen | `${c.app}/lib/screens/login/login_screen.dart` |

Screens and guards depend on `AuthRepository`, never on a provider SDK, so
changing provider does not reach beyond its implementation.

## Using it

```dart
final result = await authRepository.signIn(email: email, password: password);
result.when(
  success: (user) => context.go(AppRoutes.home),
  failure: (e) => showError(e.message),
);
```

`authRepository.authStateChanges()` emits on every sign-in and sign-out, which
is what a route guard should listen to.

$providerSection
## Route guard

`AppRoutes.login` is declared and the login screen exists, but the guard is
not enabled by default — turning it on before the sign-in path is finished
would lock you out of your own app. Enable it when you are ready:

${c.usesGoRouter ? '- Uncomment the `redirect` in `${c.app}/lib/app/router/app_router.dart` and register a `GoRoute` for `AppRoutes.login`.' : '- Add `middlewares: [AuthMiddleware()]` to the pages that require sign-in, and register a `GetPage` for `AppRoutes.login`.'}
''';
}

/// The pubspec dependency lines this provider needs.
String authDependency(ProjectConfig c) => switch (c.auth) {
  // custom uses the app's own store and HTTP client, so it adds nothing.
  AuthProvider.none || AuthProvider.custom => '',
  AuthProvider.firebase =>
    '  firebase_core: ${c.versions['firebase_core']}\n'
        '  firebase_auth: ${c.versions['firebase_auth']}\n',
  AuthProvider.supabase =>
    '  supabase_flutter: ${c.versions['supabase_flutter']}\n',
};

/// The app's single auth repository and its initialiser.
///
/// Same shape as the generated store: one place names the provider, and
/// nothing else does.
String authSession(ProjectConfig c) {
  final cls = authImplClass(c);
  final providerImport = switch (c.auth) {
    AuthProvider.firebase =>
      "import 'package:firebase_core/firebase_core.dart';\n\n"
          "import 'firebase_options.dart';\n",
    AuthProvider.supabase =>
      "import 'package:supabase_flutter/supabase_flutter.dart';\n\n"
          "import 'supabase_config.dart';\n",
    _ => '',
  };
  final providerInit = switch (c.auth) {
    AuthProvider.firebase =>
      '  await Firebase.initializeApp(\n'
          '    options: DefaultFirebaseOptions.currentPlatform,\n'
          '  );\n',
    AuthProvider.supabase =>
      '  await Supabase.initialize(\n'
          '    url: supabaseUrl,\n'
          '    anonKey: supabaseAnonKey,\n'
          '  );\n',
    _ => '',
  };

  return '''
import 'package:${c.core}/${c.core}.dart';
$providerImport
import '${authImplFileName(c)}';

/// The app's authentication repository. Valid after [initAuth] completes.
late final AuthRepository authRepository;

/// Creates and initialises [authRepository].
///
/// Changing provider is a change to this file alone: nothing else names
/// $cls.
Future<void> initAuth() async {
$providerInit  authRepository = $cls();
}
''';
}

/// Placeholder Firebase options.
///
/// Deliberately not real values: `flutterfire configure` overwrites this file
/// with the project's own. Generating placeholders is what keeps the app
/// building, so the rest of the scaffold can be verified before Firebase is
/// set up.
String firebaseOptions(ProjectConfig c) => '''
import 'package:firebase_core/firebase_core.dart';

/// Placeholder Firebase configuration.
///
/// Replace by running:
///
///     flutterfire configure
///
/// Sign-in fails until you do; the app itself still builds and starts.
abstract final class DefaultFirebaseOptions {
  /// Options for the platform the app is running on.
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_API_KEY',
    appId: 'REPLACE_WITH_YOUR_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
  );
}
''';

/// Placeholder Supabase credentials.
String supabaseConfig(ProjectConfig c) => '''
/// Supabase project URL.
///
/// Replace with the value from your project's API settings. Sign-in fails
/// until you do; the app itself still builds and starts.
const supabaseUrl = 'https://REPLACE_WITH_YOUR_PROJECT.supabase.co';

/// Supabase anon (public) key, safe to ship in a client.
const supabaseAnonKey = 'REPLACE_WITH_YOUR_ANON_KEY';
''';

/// The login screen, identical across state managers apart from navigation.
///
/// It talks to [AuthRepository] directly rather than through the framework's
/// state layer, so one screen serves all four and the flow stays readable.
String loginScreen(ProjectConfig c) {
  final navImport = c.usesGoRouter
      ? "import 'package:go_router/go_router.dart';"
      : "import 'package:get/get.dart';";
  final navigate = c.usesGoRouter
      ? 'context.go(AppRoutes.home)'
      : 'Get.offAllNamed(AppRoutes.home)';

  return '''
import 'package:flutter/material.dart';
$navImport
import 'package:${c.l10n}/${c.l10n}.dart';

import '../../app/auth/auth.dart';
import '../../app/routes/app_routes.dart';

/// Email and password sign-in.
class LoginScreen extends StatefulWidget {
  /// Creates the login screen.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await authRepository.signIn(
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    result.when(
      success: (_) => $navigate,
      failure: (e) => setState(() {
        _busy = false;
        _error = e.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Enter your email'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Enter your password'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''';
}

/// File name of the generated implementation.
String authImplFileName(ProjectConfig c) => switch (c.auth) {
  AuthProvider.none => '',
  AuthProvider.custom => 'token_auth_repository.dart',
  AuthProvider.firebase => 'firebase_auth_repository.dart',
  AuthProvider.supabase => 'supabase_auth_repository.dart',
};

/// Class name of the generated implementation.
String authImplClass(ProjectConfig c) => switch (c.auth) {
  AuthProvider.none => '',
  AuthProvider.custom => 'TokenAuthRepository',
  AuthProvider.firebase => 'FirebaseAuthRepository',
  AuthProvider.supabase => 'SupabaseAuthRepository',
};

/// The provider-specific implementation of [authRepository].
String authImpl(ProjectConfig c) => switch (c.auth) {
  AuthProvider.none => '',
  AuthProvider.custom => _customImpl(c),
  AuthProvider.firebase => _firebaseImpl(c),
  AuthProvider.supabase => _supabaseImpl(c),
};

String _customImpl(ProjectConfig c) =>
    '''
import 'dart:async';

import 'package:${c.core}/${c.core}.dart';

import '../storage/app_store.dart';

/// [AuthRepository] backed by a token in the app's [KeyValueStore].
///
/// The session handling — persisting the token, restoring it on launch,
/// broadcasting sign-in state — is complete and works as written. What is
/// deliberately left to you are the two network calls marked TODO: point them
/// at your API and return the token and user it responds with.
class TokenAuthRepository implements AuthRepository {
  /// Restores any previously persisted session.
  TokenAuthRepository() {
    final id = appStore.read<String>(_userIdKey);
    if (id != null) {
      _current = AuthUser(id: id, email: appStore.read<String>(_emailKey));
    }
  }

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _emailKey = 'auth_email';

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  /// The bearer token for API calls, or null when signed out.
  String? get token => appStore.read<String>(_tokenKey);

  @override
  AuthUser? get currentUser => _current;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    // TODO: Call your API and use the token and user it returns.
    if (email.isEmpty || password.isEmpty) {
      return const Result.failure(
        AuthException('Email and password are required'),
      );
    }
    final user = AuthUser(id: email, email: email);
    await _persist(user, 'replace-with-a-real-token');
    return Result.success(user);
  }

  @override
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
  }) async {
    // TODO: Call your registration endpoint.
    return signIn(email: email, password: password);
  }

  @override
  Future<Result<void>> signOut() async {
    await appStore.delete(_tokenKey);
    await appStore.delete(_userIdKey);
    await appStore.delete(_emailKey);
    _current = null;
    _controller.add(null);
    return const Result.success(null);
  }

  Future<void> _persist(AuthUser user, String token) async {
    await appStore.write(_tokenKey, token);
    await appStore.write(_userIdKey, user.id);
    await appStore.write(_emailKey, user.email);
    _current = user;
    _controller.add(user);
  }
}
''';

String _firebaseImpl(ProjectConfig c) =>
    '''
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:${c.core}/${c.core}.dart';

/// [AuthRepository] backed by Firebase Authentication.
///
/// Requires real Firebase credentials: run `flutterfire configure` to replace
/// the placeholders in `firebase_options.dart`. Until then the app builds and
/// starts, but sign-in fails.
class FirebaseAuthRepository implements AuthRepository {
  final _auth = fb.FirebaseAuth.instance;

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) => _guard(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
  }) => _guard(
    () =>
        _auth.createUserWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Result.success(null);
    } on fb.FirebaseAuthException catch (e) {
      return Result.failure(AuthException(e.message ?? 'Sign out failed', code: e.code));
    }
  }

  Future<Result<AuthUser>> _guard(
    Future<fb.UserCredential> Function() call,
  ) async {
    try {
      final credential = await call();
      final user = _map(credential.user);
      if (user == null) {
        return const Result.failure(AuthException('No user returned'));
      }
      return Result.success(user);
    } on fb.FirebaseAuthException catch (e) {
      // Firebase codes are stable, so callers can branch on them.
      return Result.failure(
        AuthException(e.message ?? 'Authentication failed', code: e.code),
      );
    }
  }

  AuthUser? _map(fb.User? user) => user == null
      ? null
      : AuthUser(id: user.uid, email: user.email, displayName: user.displayName);
}
''';

String _supabaseImpl(ProjectConfig c) =>
    '''
import 'package:${c.core}/${c.core}.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// [AuthRepository] backed by Supabase Auth.
///
/// Requires real credentials: set the URL and anon key in
/// `lib/app/auth/supabase_config.dart`. Until then the app builds and starts,
/// but sign-in fails.
class SupabaseAuthRepository implements AuthRepository {
  final _auth = sb.Supabase.instance.client.auth;

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.onAuthStateChange.map((event) => _map(event.session?.user));

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) => _guard(
    () => _auth.signInWithPassword(email: email, password: password),
  );

  @override
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
  }) => _guard(() => _auth.signUp(email: email, password: password));

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Result.success(null);
    } on sb.AuthException catch (e) {
      return Result.failure(AuthException(e.message, code: e.statusCode));
    }
  }

  Future<Result<AuthUser>> _guard(Future<sb.AuthResponse> Function() call) async {
    try {
      final response = await call();
      final user = _map(response.user);
      if (user == null) {
        return const Result.failure(AuthException('No user returned'));
      }
      return Result.success(user);
    } on sb.AuthException catch (e) {
      return Result.failure(AuthException(e.message, code: e.statusCode));
    }
  }

  AuthUser? _map(sb.User? user) => user == null
      ? null
      : AuthUser(id: user.id, email: user.email);
}
''';
