import '../project_config.dart';

String rootPubspec(ProjectConfig c) => '''
name: ${c.name}_workspace
publish_to: 'none'

environment:
  sdk: ^3.10.4

workspace:
  - ${c.app}
  - packages/core
  - packages/ui
  - packages/network
  - packages/l10n
''';

String rootGitignore() => '''
# Dart/Flutter
.dart_tool/
.packages
build/
pubspec.lock

# IDE
.idea/
*.iml
.vscode/

# OS
.DS_Store
Thumbs.db

# Env
.env
.env.*
''';

String analysisOptions() => '''
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    missing_return: error
    dead_code: warning
  language:
    strict-casts: true
    strict-raw-types: true
    strict-inference: true

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_locals
    - prefer_final_in_for_each
    - prefer_single_quotes
    - sort_child_properties_last
    - use_colored_box
    - use_decorated_box
    - sized_box_for_whitespace
    - sized_box_shrink_expand
    - use_super_parameters
    - always_declare_return_types
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - avoid_type_to_string
    - avoid_types_as_parameter_names
    - cancel_subscriptions
    - close_sinks
    - no_duplicate_case_values
    - throw_in_finally
    - unnecessary_statements
    - valid_regexps
    - use_build_context_synchronously
    - use_key_in_widget_constructors
    - no_logic_in_create_state
    - avoid_unnecessary_containers
    - prefer_is_empty
    - prefer_is_not_empty
    - unnecessary_null_checks
    - unnecessary_late
    - unnecessary_this
    - prefer_null_aware_operators
    - prefer_conditional_assignment
    - prefer_spread_collections
    - prefer_if_elements_to_conditional_expressions
''';
