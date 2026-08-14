import '../project_config.dart';

/// Extra route constants a template contributes to `AppRoutes`.
String templateRouteConstants(ProjectConfig c) => switch (c.template) {
  ProjectTemplate.blank => '',
  ProjectTemplate.ecommerce =>
    "\n  /// Product catalogue.\n"
        "  static const String catalog = '/catalog';\n"
        "\n  /// A single product.\n"
        "  static const String product = '/product';\n",
  ProjectTemplate.social =>
    "\n  /// Activity feed.\n"
        "  static const String feed = '/feed';\n"
        "\n  /// A user profile.\n"
        "  static const String profile = '/profile';\n",
  ProjectTemplate.dashboard =>
    "\n  /// Metrics overview.\n"
        "  static const String overview = '/overview';\n"
        "\n  /// Detail for one metric.\n"
        "  static const String metric = '/metric';\n",
};

/// The screens a template adds, as a path-to-content map.
Map<String, String> templateScreens(ProjectConfig c) => switch (c.template) {
  ProjectTemplate.blank => const {},
  ProjectTemplate.ecommerce => {
    'catalog/catalog_screen.dart': _catalogScreen(c),
    'catalog/product_screen.dart': _productScreen(c),
  },
  ProjectTemplate.social => {
    'feed/feed_screen.dart': _feedScreen(c),
    'feed/profile_screen.dart': _profileScreen(c),
  },
  ProjectTemplate.dashboard => {
    'overview/overview_screen.dart': _overviewScreen(c),
    'overview/metric_screen.dart': _metricScreen(c),
  },
};

/// The core models a template adds, as a path-to-content map.
Map<String, String> templateModels(ProjectConfig c) => switch (c.template) {
  ProjectTemplate.blank => const {},
  ProjectTemplate.ecommerce => {'product.dart': _productModel(c)},
  ProjectTemplate.social => {'post.dart': _postModel(c)},
  ProjectTemplate.dashboard => {'metric.dart': _metricModel(c)},
};

/// Barrel export lines for the models a template adds.
String templateModelExports(ProjectConfig c) =>
    templateModels(c).keys.map((f) => "export 'models/$f';\n").join();

/// `GetPage` entries for the template's screens.
String templateGetPages(ProjectConfig c) => switch (c.template) {
  ProjectTemplate.blank => '',
  ProjectTemplate.ecommerce => _getPages(const [
    ('catalog', 'CatalogScreen', 'catalog/catalog_screen.dart'),
    ('product', 'ProductScreen', 'catalog/product_screen.dart'),
  ]),
  ProjectTemplate.social => _getPages(const [
    ('feed', 'FeedScreen', 'feed/feed_screen.dart'),
    ('profile', 'ProfileScreen', 'feed/profile_screen.dart'),
  ]),
  ProjectTemplate.dashboard => _getPages(const [
    ('overview', 'OverviewScreen', 'overview/overview_screen.dart'),
    ('metric', 'MetricScreen', 'overview/metric_screen.dart'),
  ]),
};

/// `GoRoute` entries for the template's screens.
String templateGoRoutes(ProjectConfig c, {String indent = '    '}) =>
    switch (c.template) {
      ProjectTemplate.blank => '',
      ProjectTemplate.ecommerce => _goRoutes(indent: indent, const [
        ('catalog', 'CatalogScreen'),
        ('product', 'ProductScreen'),
      ]),
      ProjectTemplate.social => _goRoutes(indent: indent, const [
        ('feed', 'FeedScreen'),
        ('profile', 'ProfileScreen'),
      ]),
      ProjectTemplate.dashboard => _goRoutes(indent: indent, const [
        ('overview', 'OverviewScreen'),
        ('metric', 'MetricScreen'),
      ]),
    };

/// Screen imports the router file needs.
String templateScreenImports(ProjectConfig c, {required String prefix}) =>
    templateScreens(c).keys.map((f) => "import '$prefix$f';\n").join();

String _getPages(List<(String, String, String)> routes) => routes
    .map(
      (r) =>
          '    GetPage(\n'
          '      name: AppRoutes.${r.$1},\n'
          '      page: () => const ${r.$2}(),\n'
          '    ),\n',
    )
    .join();

String _goRoutes(List<(String, String)> routes, {String indent = '    '}) =>
    routes
        .map(
          (r) =>
              '    GoRoute(\n'
              '      path: AppRoutes.${r.$1},\n'
              '      builder: (context, state) => const ${r.$2}(),\n'
              '    ),\n',
        )
        .join();

// ── Models ────────────────────────────────────────────────

String _productModel(ProjectConfig c) =>
    '''
import 'package:${c.core}/models/base_model.dart';

/// A catalogue item.
class Product extends BaseModel {
  /// Creates a product.
  const Product({
    required this.id,
    required this.name,
    required this.priceCents,
    this.description = '',
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Price in minor units, avoiding floating point for money.
  final int priceCents;

  /// Long-form description.
  final String description;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price_cents': priceCents,
    'description': description,
  };

  @override
  List<Object?> get props => [id, name, priceCents, description];
}
''';

String _postModel(ProjectConfig c) =>
    '''
import 'package:${c.core}/models/base_model.dart';

/// An item in the activity feed.
class Post extends BaseModel {
  /// Creates a post.
  const Post({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    this.likes = 0,
  });

  /// Unique identifier.
  final String id;

  /// Display name of the author.
  final String author;

  /// Post text.
  final String body;

  /// When the post was created.
  final DateTime createdAt;

  /// Number of likes.
  final int likes;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'body': body,
    'created_at': createdAt.toIso8601String(),
    'likes': likes,
  };

  @override
  List<Object?> get props => [id, author, body, createdAt, likes];
}
''';

String _metricModel(ProjectConfig c) =>
    '''
import 'package:${c.core}/models/base_model.dart';

/// A single dashboard figure.
class Metric extends BaseModel {
  /// Creates a metric.
  const Metric({
    required this.id,
    required this.label,
    required this.value,
    this.changePercent = 0,
  });

  /// Unique identifier.
  final String id;

  /// Human-readable label.
  final String label;

  /// Formatted value, e.g. '1,204' or '\$8.2k'.
  final String value;

  /// Change against the previous period; negative means a decrease.
  final double changePercent;

  /// Whether the change is an improvement.
  bool get isPositive => changePercent >= 0;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'change_percent': changePercent,
  };

  @override
  List<Object?> get props => [id, label, value, changePercent];
}
''';

// ── Screens ───────────────────────────────────────────────
//
// Plain widgets that take their data as parameters, so they work with any
// state manager. Sample data is a local constant, clearly marked, rather than
// a fake repository that would have to be unpicked later.

String _navigateTo(ProjectConfig c, String route) => c.usesGoRouter
    ? 'context.push(AppRoutes.$route)'
    : 'Get.toNamed(AppRoutes.$route)';

String _navImport(ProjectConfig c) => c.usesGoRouter
    ? "import 'package:go_router/go_router.dart';"
    : "import 'package:get/get.dart';";

String _catalogScreen(ProjectConfig c) =>
    '''
import 'package:flutter/material.dart';
${_navImport(c)}
import 'package:${c.core}/${c.core}.dart';
import 'package:${c.ui}/${c.ui}.dart';

import '../../app/routes/app_routes.dart';

/// Product catalogue.
///
/// Replace [_sampleProducts] with data from a repository; the layout and
/// navigation are what this screen is here to give you.
class CatalogScreen extends StatelessWidget {
  /// Creates the catalogue.
  const CatalogScreen({super.key, this.products = _sampleProducts});

  /// Products to display.
  final List<Product> products;

  static const _sampleProducts = [
    Product(id: '1', name: 'Sample item', priceCents: 1999),
    Product(id: '2', name: 'Another item', priceCents: 4550),
    Product(id: '3', name: 'Third item', priceCents: 899),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      body: ResponsiveBuilder(
        mobile: (context) => _grid(context, columns: 2),
        tablet: (context) => _grid(context, columns: 3),
        desktop: (context) => _grid(context, columns: 4),
      ),
    );
  }

  Widget _grid(BuildContext context, {required int columns}) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ${_navigateTo(c, 'product')},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.image_outlined)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '\\\$\${(product.priceCents / 100).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
''';

String _productScreen(ProjectConfig c) =>
    '''
import 'package:flutter/material.dart';
import 'package:${c.core}/${c.core}.dart';
import 'package:${c.ui}/${c.ui}.dart';

/// Detail for a single product.
class ProductScreen extends StatelessWidget {
  /// Creates the product detail screen.
  const ProductScreen({super.key, this.product = _sample});

  /// Product to display.
  final Product product;

  static const _sample = Product(
    id: '1',
    name: 'Sample item',
    priceCents: 1999,
    description: 'Replace this with a product loaded from your repository.',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.image_outlined, size: 48)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(product.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\\\$\${(product.priceCents / 100).toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(product.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () {
              // TODO: Add to cart.
            },
            child: const Text('Add to cart'),
          ),
        ],
      ),
    );
  }
}
''';

String _feedScreen(ProjectConfig c) =>
    '''
import 'package:flutter/material.dart';
${_navImport(c)}
import 'package:${c.core}/${c.core}.dart';
import 'package:${c.ui}/${c.ui}.dart';

import '../../app/routes/app_routes.dart';

/// Activity feed.
///
/// Replace [_samplePosts] with data from a repository.
class FeedScreen extends StatelessWidget {
  /// Creates the feed.
  const FeedScreen({super.key, this.posts});

  /// Posts to display; sample content is used when null.
  final List<Post>? posts;

  @override
  Widget build(BuildContext context) {
    final items = posts ?? _samplePosts();

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final post = items[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text(post.author.characters.first)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: () => ${_navigateTo(c, 'profile')},
                          child: Text(
                            post.author,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                      Text(
                        _relative(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(post.body),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text('\${post.likes}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Compact relative time, e.g. "12m" or "3h".
  static String _relative(DateTime time) {
    final delta = DateTime.now().difference(time);
    if (delta.inMinutes < 1) return 'now';
    if (delta.inHours < 1) return '\${delta.inMinutes}m';
    if (delta.inDays < 1) return '\${delta.inHours}h';
    return '\${delta.inDays}d';
  }

  static List<Post> _samplePosts() {
    final now = DateTime.now();
    return [
      Post(
        id: '1',
        author: 'Ada',
        body: 'Replace this feed with posts from your repository.',
        createdAt: now.subtract(const Duration(minutes: 12)),
        likes: 4,
      ),
      Post(
        id: '2',
        author: 'Grace',
        body: 'The layout, navigation and formatting are wired already.',
        createdAt: now.subtract(const Duration(hours: 3)),
        likes: 11,
      ),
    ];
  }
}
''';

String _profileScreen(ProjectConfig c) =>
    '''
import 'package:flutter/material.dart';
import 'package:${c.ui}/${c.ui}.dart';

/// A user profile.
class ProfileScreen extends StatelessWidget {
  /// Creates the profile screen.
  const ProfileScreen({super.key, this.name = 'Ada', this.bio = ''});

  /// Display name.
  final String name;

  /// Short biography.
  final String bio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                name.characters.first,
                style: theme.textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(child: Text(name, style: theme.textTheme.headlineSmall)),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              bio.isEmpty ? 'Replace with a profile from your repository.' : bio,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
''';

String _overviewScreen(ProjectConfig c) =>
    '''
import 'package:flutter/material.dart';
${_navImport(c)}
import 'package:${c.core}/${c.core}.dart';
import 'package:${c.ui}/${c.ui}.dart';

import '../../app/routes/app_routes.dart';

/// Metrics overview.
///
/// Replace [_sampleMetrics] with data from a repository.
class OverviewScreen extends StatelessWidget {
  /// Creates the overview.
  const OverviewScreen({super.key, this.metrics = _sampleMetrics});

  /// Metrics to display.
  final List<Metric> metrics;

  static const _sampleMetrics = [
    Metric(id: 'users', label: 'Active users', value: '1,204', changePercent: 8.2),
    Metric(id: 'revenue', label: 'Revenue', value: '\\\$8.2k', changePercent: 3.1),
    Metric(id: 'churn', label: 'Churn', value: '2.4%', changePercent: -0.6),
    Metric(id: 'sessions', label: 'Sessions', value: '9,871', changePercent: 12.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: ResponsiveBuilder(
        mobile: (context) => _grid(context, columns: 2),
        tablet: (context) => _grid(context, columns: 3),
        desktop: (context) => _grid(context, columns: 4),
      ),
    );
  }

  Widget _grid(BuildContext context, {required int columns}) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.6,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        final theme = Theme.of(context);
        final changeColor = metric.isPositive
            ? theme.colorScheme.primary
            : theme.colorScheme.error;

        return Card(
          child: InkWell(
            onTap: () => ${_navigateTo(c, 'metric')},
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(metric.label, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(metric.value, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        metric.isPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 16,
                        color: changeColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '\${metric.changePercent.abs().toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
''';

String _metricScreen(ProjectConfig c) =>
    '''
import 'package:flutter/material.dart';
import 'package:${c.core}/${c.core}.dart';
import 'package:${c.ui}/${c.ui}.dart';

/// Detail for a single metric.
class MetricScreen extends StatelessWidget {
  /// Creates the metric detail screen.
  const MetricScreen({super.key, this.metric = _sample});

  /// Metric to display.
  final Metric metric;

  static const _sample = Metric(
    id: 'users',
    label: 'Active users',
    value: '1,204',
    changePercent: 8.2,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(metric.label)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(metric.value, style: theme.textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '\${metric.isPositive ? 'Up' : 'Down'} '
            '\${metric.changePercent.abs().toStringAsFixed(1)}% '
            'on the previous period',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(
                // TODO: Replace with a chart from your charting package.
                child: Text('Chart goes here'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
''';
