import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_ui/main.dart';
import 'package:go_router/go_router.dart';

class TeamDetailPage extends StatefulWidget {
  final String teamId;

  const TeamDetailPage({super.key, required this.teamId});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  late Future<Team> _teamFuture;

  @override
  void initState() {
    super.initState();
    _fetchTeam();
  }

  void _fetchTeam() {
    setState(() {
      _teamFuture = apiClient.getTeam(widget.teamId);
    });
  }

  Future<void> _addMember() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the email address of the new member.').muted(),
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
                await apiClient.addTeamMember(widget.teamId, controller.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _fetchTeam();
                  showToast(
                    context: context,
                    builder: (context, overlay) => SurfaceCard(
                      child: Basic(
                        leading: const Icon(
                          BootstrapIcons.checkCircle,
                          color: Colors.green,
                        ),
                        title: const Text('Member added successfully'),
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
                        title: Text('Failed to add member: $e'),
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

  Future<void> _removeMember(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member?'),
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
        await apiClient.removeTeamMember(widget.teamId, userId);
        if (!mounted) return;
        _fetchTeam();
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(
              leading: const Icon(
                BootstrapIcons.checkCircle,
                color: Colors.green,
              ),
              title: const Text('Member removed successfully'),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(
              leading: const Icon(
                BootstrapIcons.exclamationCircle,
                color: Colors.red,
              ),
              title: Text('Failed to remove member: $e'),
            ),
          ),
        );
      }
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
            children: [
              Button.ghost(
                onPressed: () => context.pop(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(BootstrapIcons.arrowLeft, size: 16),
                    Gap(8),
                    Text('Back'),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          FutureBuilder<Team>(
            future: _teamFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}').muted());
              }
              final team = snapshot.data!;
              return Expanded(
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
                              team.name,
                              style: theme.typography.h2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Button.outline(
                          onPressed: _addMember,
                          child: const Row(
                            children: [
                              Icon(BootstrapIcons.plus, size: 16),
                              Gap(8),
                              Text('Add Member'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(32),
                    Text('Members', style: theme.typography.h4),
                    const Gap(16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: team.members.length,
                        separatorBuilder: (context, index) => const Gap(8),
                        itemBuilder: (context, index) {
                          final member = team.members[index];
                          return SurfaceCard(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Avatar(
                                    initials: member
                                        .substring(0, 1)
                                        .toUpperCase(),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member,
                                          style: theme.typography.base.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Role info not available in this simple list
                                  IconButton.ghost(
                                    size: ButtonSize.small,
                                    onPressed: () => _removeMember(member),
                                    icon: const Icon(
                                      BootstrapIcons.trash,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
