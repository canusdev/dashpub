import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:go_router/go_router.dart';
import 'package:dashpub_ui/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<ListApi> _packagesFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _packagesFuture = apiClient.getPackages();
  }

  void _search() {
    setState(() {
      _packagesFuture = apiClient.getPackages(q: _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Packages',
                      style: theme.typography.h2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Search through public and authorized private packages',
                    ).muted(),
                  ],
                ),
              ),
              const Gap(16),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  placeholder: const Text('Search packages...'),
                  onSubmitted: (_) => _search(),
                ),
              ),
            ],
          ),
          const Gap(32),
          Expanded(
            child: FutureBuilder<ListApi>(
              future: _packagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          BootstrapIcons.exclamationTriangle,
                          size: 48,
                          color: theme.colorScheme.destructive,
                        ),
                        const Gap(16),
                        Text('Error: ${snapshot.error}').muted(),
                      ],
                    ),
                  );
                }
                final packages = snapshot.data!.packages;
                if (packages.isEmpty) {
                  return Center(child: const Text('No packages found').muted());
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final pkg = packages[index];
                    return _PackageCard(pkg: pkg);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final ListApiPackage pkg;
  const _PackageCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: GestureDetector(
        onTap: () => context.go('/package/${pkg.name}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pkg.name,
                      style: theme.typography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap(8),
                  PrimaryBadge(child: Text('v${pkg.latest}')),
                ],
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  pkg.description ?? 'No description provided.',
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(16),
              if (pkg.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pkg.tags.map((tag) => _TagBadge(tag: tag)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String tag;
  const _TagBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
