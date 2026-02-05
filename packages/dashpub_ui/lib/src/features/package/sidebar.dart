import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PackageSidebar extends StatelessWidget {
  final WebapiDetailView detail;

  const PackageSidebar({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Metadata', style: theme.typography.h4),
        const Gap(16),
        if (detail.description.isNotEmpty) ...[
          Text(detail.description).muted(),
          const Gap(24),
        ],
        if (detail.homepage.isNotEmpty) ...[
          Text(
            'Homepage',
            style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          Button(
            style: ButtonStyle.link().withForegroundColor(
              color: theme.colorScheme.primary,
            ),
            enabled: detail.homepage.isNotEmpty,
            onPressed: () {
              launchUrlString(detail.homepage);
            },
            child: Text(detail.homepage),
          ),
          const Gap(16),
        ],
        if (detail.repository != null) ...[
          Text(
            'Repository',
            style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          Button(
            style: ButtonStyle.link().withForegroundColor(
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              launchUrlString(detail.repository!);
            },
            child: Text(detail.repository!),
          ),
          const Gap(16),
        ],
        if (detail.issueTracker != null) ...[
          Text(
            'Issue Tracker',
            style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          Button(
            style: ButtonStyle.link().withForegroundColor(
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              launchUrlString(detail.issueTracker!);
            },
            child: Text(detail.issueTracker!),
          ),
          const Gap(16),
        ],
        Text(
          'Publisher',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
        ),
        //...
        Text(
          'Documentation',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        Button(
          style: ButtonStyle.link().withForegroundColor(
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            launchUrlString('/doc/${detail.name}/${detail.version}/');
          },
          child: const Text('API Reference'),
        ),
        const Gap(16),

        Text(
          'License',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        if (detail.license != null)
          Row(
            children: [
              Icon(
                BootstrapIcons.fileText,
                size: 14,
                color: theme.colorScheme.mutedForeground,
              ),
              const Gap(4),
              Text(_getLicenseName(detail.license!)),
              const Gap(4),
              Button(
                style: ButtonStyle.link().withForegroundColor(
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  context.go('/pkg/${detail.name}/license?v=${detail.version}');
                },
                child: const Text('(view)'),
              ),
            ],
          )
        else
          const Text('Unknown').muted(),
        const Gap(16),
        //...
        Text(
          'Dependencies',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        if (detail.dependencies.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detail.dependencies
                .map(
                  (d) => Button(
                    style: ButtonStyle.link().withForegroundColor(
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      if (d.isLocal) {
                        context.push('/pkg/${d.name}');
                      } else if (d.gitUrl != null) {
                        launchUrlString(d.gitUrl!);
                      } else if (d.hostedUrl != null) {
                        launchUrlString(d.hostedUrl!);
                      } else {
                        launchUrlString('https://pub.dev/packages/${d.name}');
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(d.name),
                        if (!d.isLocal) ...[
                          const Gap(4),
                          Icon(
                            BootstrapIcons.boxArrowUpRight,
                            size: 10,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
          )
        else
          const Text('None').muted(),
        if (detail.repository != null) ...[
          Text(
            'Repository',
            style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          Button(
            style: ButtonStyle.link().withForegroundColor(
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              launchUrlString(detail.repository!);
            },
            child: Text(detail.repository!),
          ),
          const Gap(16),
        ],
        if (detail.issueTracker != null) ...[
          Text(
            'Issue Tracker',
            style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          Button(
            style: ButtonStyle.link().withForegroundColor(
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              launchUrlString(detail.issueTracker!);
            },
            child: Text(detail.issueTracker!),
          ),
          const Gap(16),
        ],
        Text(
          'Publisher',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
        ),
        // ...
        Text(
          'Documentation',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        Button(
          style: ButtonStyle.link().withForegroundColor(
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            launchUrlString('/doc/${detail.name}/${detail.version}/');
          },
          child: const Text('API Reference'),
        ),
        const Gap(16),

        Text(
          'License',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        if (detail.license != null)
          Row(
            children: [
              Icon(
                BootstrapIcons.fileText,
                size: 14,
                color: theme.colorScheme.mutedForeground,
              ),
              const Gap(4),
              Text(_getLicenseName(detail.license!)),
              const Gap(4),
              Button(
                style: ButtonStyle.link().withForegroundColor(
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  context.go('/pkg/${detail.name}/license?v=${detail.version}');
                },
                child: const Text('(view)'),
              ),
            ],
          )
        else
          const Text('Unknown').muted(),
        const Gap(16),
        //...
        Text(
          'Dependencies',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        if (detail.dependencies.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detail.dependencies
                .map(
                  (d) => Button(
                    style: ButtonStyle.link().withForegroundColor(
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      if (d.isLocal) {
                        context.push('/pkg/${d.name}');
                      } else if (d.gitUrl != null) {
                        launchUrlString(d.gitUrl!);
                      } else if (d.hostedUrl != null) {
                        launchUrlString(d.hostedUrl!);
                      } else {
                        launchUrlString('https://pub.dev/packages/${d.name}');
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(d.name),
                        if (!d.isLocal) ...[
                          const Gap(4),
                          Icon(
                            BootstrapIcons.boxArrowUpRight,
                            size: 10,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
          )
        else
          const Text('None').muted(),
        const Gap(16),
        Button(
          style: ButtonStyle.link().withForegroundColor(
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            context.go('/?q=dependency:${detail.name}');
          },
          child: Text('Packages that depend on ${detail.name}'),
        ),
      ],
    );
  }

  String _getLicenseName(String content) {
    if (content.contains('MIT License')) {
      return 'MIT';
    }
    if (content.contains('Apache License, Version 2.0') ||
        content.contains('Apache License 2.0')) {
      return 'Apache 2.0';
    }
    if (content.contains('BSD 3-Clause')) {
      return 'BSD 3-Clause';
    }
    if (content.contains('BSD 2-Clause')) {
      return 'BSD 2-Clause';
    }
    if (content.contains('GPL-3.0') ||
        content.contains('General Public License version 3')) {
      return 'GPL v3';
    }
    if (content.contains('AGPL') ||
        content.contains('Affero General Public License')) {
      return 'AGPL';
    }
    return 'Custom';
  }
}
