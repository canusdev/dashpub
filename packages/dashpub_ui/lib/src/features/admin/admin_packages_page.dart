import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_ui/main.dart';

class AdminPackagesPage extends StatefulWidget {
  const AdminPackagesPage({super.key});

  @override
  State<AdminPackagesPage> createState() => _AdminPackagesPageState();
}

class _AdminPackagesPageState extends State<AdminPackagesPage> {
  late Future<ListApi> _packagesFuture;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  void _fetchPackages() {
    setState(() {
      _packagesFuture = apiClient.getPackages(size: 100); // Get more for admin
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Packages Management',
                    style: theme.typography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Manage registry packages, visibility and versions',
                  ).muted(),
                ],
              ),
              Button.outline(
                onPressed: _fetchPackages,
                child: const Row(
                  children: [
                    Icon(BootstrapIcons.arrowClockwise, size: 16),
                    Gap(8),
                    Text('Refresh'),
                  ],
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

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: packages.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) {
                    final pkg = packages[index];
                    return SurfaceCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              BootstrapIcons.boxSeam,
                              color: theme.colorScheme.primary,
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pkg.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Latest: v${pkg.latest} • Updated: ${pkg.updatedAt.toString().substring(0, 10)}',
                                  ).muted(),
                                ],
                              ),
                            ),
                            const Gap(16),
                            const PrimaryBadge(child: Text('Versioned')),
                            const Gap(16),
                            IconButton.ghost(
                              size: ButtonSize.small,
                              onPressed: () {},
                              icon: const Icon(BootstrapIcons.eye, size: 14),
                            ),
                          ],
                        ),
                      ),
                    );
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
