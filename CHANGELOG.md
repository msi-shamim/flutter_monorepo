## 1.0.0

- **`--state`**: Choose state management — GetX, Riverpod, Bloc, or Cubit
- **`--locales`**: Dynamic locale support with 12 built-in languages (en, ar, es, fr, de, pt, zh, ja, ko, hi, tr, ru)
- **`--platforms`**: Target any Flutter platform (android, ios, web, linux, macos, windows)
- **`--git`**: Auto git init with first commit (on by default)
- Strategy pattern architecture for clean framework-specific templates
- GoRouter for Riverpod/Bloc/Cubit, GetX router for GetX
- SharedPreferences for Riverpod, HydratedBloc for Bloc/Cubit, GetStorage for GetX

## 0.1.0

- Initial release
- GetX-only monorepo scaffolding with 4 shared packages (core, ui, network, l10n)
- Material 3 theme system (light + dark, all component themes)
- Responsive design utilities (Breakpoints, ResponsiveHelper, ResponsiveBuilder)
- Centralized asset management with type-safe constants
- Dio HTTP client with sealed Result<T> error handling
- EN/AR localization with date/number formatters and RTL helpers
- GetStorage persistence for theme and locale
- Route middleware/guards pattern
- Strict production linting
- Complete documentation
