import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dashpub_ui/src/features/auth/auth_bloc.dart';
import 'package:dashpub_ui/main.dart'; // for apiClient

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  Future<void> _createTeam(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a name for your new team.').muted(),
            const Gap(16),
            TextField(
              controller: controller,
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
            onPressed: () async {
              try {
                await apiClient.createTeam(controller.text);
                if (context.mounted) {
                  final updatedUser = await apiClient.getMe();
                  if (context.mounted) {
                    context.read<AuthBloc>().add(UpdateUser(updatedUser));
                    Navigator.of(context).pop();
                    showToast(
                      context: context,
                      builder: (context, overlay) => const SurfaceCard(
                        child: Basic(
                          title: Text('Success'),
                          content: Text('Team created successfully'),
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  showToast(
                    context: context,
                    builder: (context, overlay) => SurfaceCard(
                      child: Basic(
                        title: const Text('Error'),
                        content: Text('Failed to create team: $e'),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Center(child: Text('Login to view your teams'));
        }
        return Padding(
          padding: const EdgeInsets.all(32),
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
                        'Teams',
                        style: theme.typography.h2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Collaborate with others on private packages',
                      ).muted(),
                    ],
                  ),
                  Button.primary(
                    onPressed: () => _createTeam(context),
                    child: const Row(
                      children: [
                        Icon(BootstrapIcons.plus, size: 20),
                        Gap(8),
                        Text('Create Team'),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(48),
              if (state.user.teams.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        BootstrapIcons.people,
                        size: 64,
                        color: theme.colorScheme.muted,
                      ),
                      const Gap(16),
                      const Text('You are not a member of any teams.').muted(),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: state.user.teams.length,
                    separatorBuilder: (context, index) => const Gap(8),
                    itemBuilder: (context, index) {
                      final teamId = state.user.teams[index];
                      return GestureDetector(
                        onTap: () => context.go('/teams/$teamId'),
                        child: SurfaceCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Team $teamId',
                                        style: theme.typography.h4,
                                      ),
                                      Text('ID: $teamId').xSmall(),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  BootstrapIcons.chevronRight,
                                  size: 16,
                                ),
                              ],
                            ),
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
    );
  }
}
