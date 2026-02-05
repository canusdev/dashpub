import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dashpub_ui/main.dart';
import 'package:dashpub_ui/src/utils/code_syntax_highlighter.dart';
import 'package:dashpub_ui/src/utils/code_block_builder.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:timeago/timeago.dart' as timeago;
import 'sidebar.dart';

class PackageDetailPage extends StatefulWidget {
  final String name;
  final String version;
  final String? tab;

  const PackageDetailPage({
    super.key,
    required this.name,
    required this.version,
    this.tab,
  });

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  int _selectedTab = 0;

  final _tabs = ['readme', 'changelog', 'versions', 'permissions', 'license'];

  @override
  void initState() {
    super.initState();
    _updateTabFromUrl();
  }

  @override
  void didUpdateWidget(PackageDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      _updateTabFromUrl();
    }
  }

  void _updateTabFromUrl() {
    if (widget.tab != null) {
      final index = _tabs.indexOf(widget.tab!);
      if (index != -1) {
        _selectedTab = index;
      }
    } else {
      _selectedTab = 0;
    }
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTab = index);
    final tabName = _tabs[index];
    if (tabName == 'readme') {
      context.go('/package/${widget.name}?v=${widget.version}');
    } else {
      context.go('/package/${widget.name}/$tabName?v=${widget.version}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<WebapiDetailView>(
      future: apiClient.getPackageDetail(widget.name, version: widget.version),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final detail = snapshot.data!;
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
                          detail.name,
                          style: theme.typography.h1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Published ${DateFormat.yMMMd().format(detail.createdAt)} (${timeago.format(detail.createdAt)}) • v${detail.version}',
                        ).muted(),
                        if (detail.platforms != null &&
                            detail.platforms!.isNotEmpty) ...[
                          const Gap(8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'PLATFORM',
                                style: theme.typography.xSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              const Gap(8),
                              Wrap(
                                spacing: 8,
                                children: detail.platforms!
                                    .map(
                                      (p) => Text(
                                        p.toUpperCase(),
                                        style: theme.typography.small.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Gap(16),
                  if (detail.isPrivate ?? false)
                    const PrimaryBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(BootstrapIcons.lock, size: 12),
                          Gap(4),
                          Text('Private'),
                        ],
                      ),
                    ),
                ],
              ),
              const Gap(32),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          TabList(
                            index: _selectedTab,
                            onChanged: _onTabChanged,
                            children: [
                              TabItem(child: Text('Readme')),
                              TabItem(child: Text('Changelog')),
                              TabItem(child: Text('Versions')),
                              TabItem(child: Text('Permissions')),
                              TabItem(child: Text('License')),
                            ],
                          ),
                          const Gap(16),
                          Expanded(
                            child: IndexedStack(
                              index: _selectedTab,
                              children: [
                                _MarkdownView(content: detail.readme),
                                _MarkdownView(content: detail.changelog),
                                _VersionsList(
                                  versions: detail.versions,
                                  packageName: widget.name,
                                ),
                                _PermissionsPanel(
                                  packageName: widget.name,
                                  detail: detail,
                                  onUpdate: () => setState(() {}),
                                ),
                                _LicenseView(content: detail.license),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(32),
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: PackageSidebar(detail: detail),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LicenseView extends StatelessWidget {
  final String? content;
  const _LicenseView({this.content});

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return Center(child: const Text('No license available').muted());
    }
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.muted.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(content!, style: const TextStyle(fontFamily: 'monospace')),
      ),
    );
  }
}

class _MarkdownView extends StatelessWidget {
  final String? content;
  const _MarkdownView({this.content});

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return Center(child: const Text('No content available').muted());
    }

    // Register languages if not already done (could be done in main.dart)
    registerLanguages();

    final brightness = Theme.of(context).brightness;
    final baseTheme = brightness == Brightness.dark
        ? draculaTheme
        : githubTheme;
    final theme = Map<String, TextStyle>.from(baseTheme);
    theme['root'] = theme['root']!.copyWith(
      backgroundColor: Colors.transparent,
    );

    final highlighter = CodeSyntaxHighlighter(theme);

    return SingleChildScrollView(
      child: MarkdownBody(
        data: content!,
        selectable: true,
        extensionSet: md.ExtensionSet.gitHubWeb,
        builders: {'pre': CodeBlockBuilder(highlighter: highlighter)},
        //syntaxHighlighter: highlighter,
      ).withPadding(all: 16),
    );
  }
}

class _VersionsList extends StatelessWidget {
  final List<DetailViewVersion> versions;
  final String packageName;

  const _VersionsList({required this.versions, required this.packageName});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: versions.length,
      separatorBuilder: (context, index) => const Gap(8),
      itemBuilder: (context, index) {
        final v = versions[index];
        return GestureDetector(
          onTap: () => context.go('/package/$packageName?v=${v.version}'),
          child: SurfaceCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.version,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(DateFormat.yMMMd().format(v.createdAt)).xSmall,
                      ],
                    ),
                  ),
                  const Icon(BootstrapIcons.chevronRight, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionsPanel extends StatelessWidget {
  final String packageName;
  final WebapiDetailView detail;
  final VoidCallback onUpdate;

  const _PermissionsPanel({
    required this.packageName,
    required this.detail,
    required this.onUpdate,
  });

  Future<void> _addUploader(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Uploader'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the email address of the new uploader.').muted(),
            const Gap(16),
            TextField(
              controller: controller,
              placeholder: const Text('Email Address'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          Button.ghost(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Button.primary(
            onPressed: () async {
              try {
                await apiClient.addUploader(packageName, controller.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  onUpdate();
                  showToast(
                    context: context,
                    builder: (context, overlay) => SurfaceCard(
                      child: Basic(
                        leading: const Icon(
                          BootstrapIcons.checkCircle,
                          color: Colors.green,
                        ),
                        title: const Text('Uploader added successfully'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showToast(
                    context: context,
                    builder: (context, overlay) => SurfaceCard(
                      child: Basic(
                        leading: const Icon(
                          BootstrapIcons.exclamationCircle,
                          color: Colors.red,
                        ),
                        title: Text('Failed to add uploader: $e'),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeUploader(BuildContext context, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Uploader'),
        content: Text('Are you sure you want to remove $email?'),
        actions: [
          Button.ghost(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          Button.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiClient.removeUploader(packageName, email);
        if (context.mounted) {
          onUpdate();
          showToast(
            context: context,
            builder: (context, overlay) => SurfaceCard(
              child: Basic(
                leading: const Icon(
                  BootstrapIcons.checkCircle,
                  color: Colors.green,
                ),
                title: const Text('Uploader removed successfully'),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          showToast(
            context: context,
            builder: (context, overlay) => SurfaceCard(
              child: Basic(
                leading: const Icon(
                  BootstrapIcons.exclamationCircle,
                  color: Colors.red,
                ),
                title: Text('Failed to remove uploader: $e'),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Package Permissions', style: theme.typography.h4),
        const Gap(8),
        const Text(
          'Manage who can read, update, or administer this package.',
        ).muted(),
        const Gap(24),
        SurfaceCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Uploaders', style: theme.typography.large),
                    Button.outline(
                      onPressed: () => _addUploader(context),
                      child: const Row(
                        children: [
                          Icon(BootstrapIcons.plus, size: 16),
                          Gap(8),
                          Text('Add Uploader'),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                if (detail.uploaders.isEmpty)
                  const Text('No uploaders found.').muted()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detail.uploaders.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final uploader = detail.uploaders[index];
                      return Row(
                        children: [
                          Avatar(
                            initials: uploader.substring(0, 1).toUpperCase(),
                          ),
                          const Gap(12),
                          Expanded(child: Text(uploader)),
                          IconButton.ghost(
                            size: ButtonSize.small,
                            onPressed: () => _removeUploader(context, uploader),
                            icon: const Icon(BootstrapIcons.trash, size: 16),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
