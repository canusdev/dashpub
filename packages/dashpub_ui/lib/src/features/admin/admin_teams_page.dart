import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_ui/main.dart';
import 'package:go_router/go_router.dart';

class AdminTeamsPage extends StatefulWidget {
  const AdminTeamsPage({super.key});

  @override
  State<AdminTeamsPage> createState() => _AdminTeamsPageState();
}

class _AdminTeamsPageState extends State<AdminTeamsPage> {
  late Future<List<Team>> _teamsFuture;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _fetchTeams() {
    setState(() {
      _teamsFuture = apiClient.adminGetTeams();
    });
  }

  Future<void> _createTeam() async {
    if (_nameController.text.isEmpty) return;

    try {
      await apiClient.createTeam(_nameController.text);
      _nameController.clear();
      _fetchTeams();
      if (!mounted) return;
      showToast(
        context: context,
        builder: (context, overlay) {
          final theme = Theme.of(context);
          return SurfaceCard(
            child: Basic(
              leading: Icon(
                BootstrapIcons.checkCircle,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Team created successfully'),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      showToast(
        context: context,
        builder: (context, overlay) {
          final theme = Theme.of(context);
          return SurfaceCard(
            child: Basic(
              leading: Icon(
                BootstrapIcons.exclamationCircle,
                color: theme.colorScheme.destructive,
              ),
              title: Text('Failed to create team: $e'),
            ),
          );
        },
      );
    }
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
                    'Teams Management',
                    style: theme.typography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Manage collaborative teams and permissions',
                  ).muted(),
                ],
              ),
              Button.primary(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Create New Team'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Enter the name of the new team to be created.',
                          ).muted(),
                          const Gap(16),
                          TextField(
                            controller: _nameController,
                            placeholder: const Text('Team Name'),
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
                          onPressed: () {
                            _createTeam();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(BootstrapIcons.plus, size: 20),
                    Gap(8),
                    Text('New Team'),
                  ],
                ),
              ),
            ],
          ),
          const Gap(32),
          Expanded(
            child: FutureBuilder<List<Team>>(
              future: _teamsFuture,
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
                final teams = snapshot.data!;
                if (teams.isEmpty) {
                  return Center(child: const Text('No teams found').muted());
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    team.name,
                                    style: theme.typography.h4.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton.ghost(
                                  size: ButtonSize.small,
                                  onPressed: () =>
                                      context.go('/teams/${team.id}'),
                                  icon: const Icon(
                                    BootstrapIcons.pencil,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            Text('${team.members.length} Members').muted(),
                            const Spacer(),
                            Button(
                              onPressed: () {},
                              style: ButtonStyle.ghost(size: ButtonSize.small),
                              child: const Text('Manage Members'),
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
