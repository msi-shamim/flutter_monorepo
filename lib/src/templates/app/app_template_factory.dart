import '../../project_config.dart';
import 'app_template_strategy.dart';
import 'bloc_templates.dart';
import 'cubit_templates.dart';
import 'getx_templates.dart';
import 'riverpod_templates.dart';

AppTemplateStrategy createAppTemplates(StateManagement sm) => switch (sm) {
      StateManagement.getx => GetxTemplateStrategy(),
      StateManagement.riverpod => RiverpodTemplateStrategy(),
      StateManagement.bloc => BlocTemplateStrategy(),
      StateManagement.cubit => CubitTemplateStrategy(),
    };
