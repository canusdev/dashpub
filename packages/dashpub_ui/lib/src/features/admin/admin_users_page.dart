import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_ui/main.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    setState(() {
      _usersFuture = apiClient.adminGetUsers();
    });
  }

  Future<void> _editUser(User user) async {
    bool isAdmin = user.isAdmin;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Editing user ${user.email}').muted(),
                  const Gap(16),
                  Row(
                    children: [
                      Switch(
                        value: isAdmin,
                        onChanged: (value) => setState(() => isAdmin = value),
                      ),
                      const Gap(12),
                      const Text('Is Admin'),
                    ],
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
                      await apiClient.adminUpdateUser(
                        user.id,
                        isAdmin: isAdmin,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        _fetchUsers();
                        showToast(
                          context: context,
                          builder: (context, overlay) {
                            return const SurfaceCard(
                              child: Basic(
                                leading: Icon(
                                  BootstrapIcons.checkCircle,
                                  color: Colors.green,
                                ),
                                title: Text('User updated successfully'),
                              ),
                            );
                          },
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showToast(
                          context: context,
                          builder: (context, overlay) {
                            return SurfaceCard(
                              child: Basic(
                                leading: const Icon(
                                  BootstrapIcons.exclamationCircle,
                                  color: Colors.red,
                                ),
                                title: Text('Failed to update user: $e'),
                              ),
                            );
                          },
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createUser() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isAdmin = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter user details').muted(),
                  const Gap(16),
                  TextField(
                    controller: emailController,
                    placeholder: const Text('Email'),
                  ),
                  const Gap(12),
                  TextField(
                    controller: nameController,
                    placeholder: const Text('Name (Optional)'),
                  ),
                  const Gap(12),
                  TextField(
                    controller: passwordController,
                    placeholder: const Text('Password'),
                    obscureText: true,
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Switch(
                        value: isAdmin,
                        onChanged: (value) => setState(() => isAdmin = value),
                      ),
                      const Gap(12),
                      const Text('Is Admin'),
                    ],
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
                    if (emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      return;
                    }
                    try {
                      await apiClient.adminCreateUser(
                        email: emailController.text,
                        password: passwordController.text,
                        name: nameController.text.isEmpty
                            ? null
                            : nameController.text,
                        isAdmin: isAdmin,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        _fetchUsers();
                        showToast(
                          context: context,
                          builder: (context, overlay) {
                            return const SurfaceCard(
                              child: Basic(
                                leading: Icon(
                                  BootstrapIcons.checkCircle,
                                  color: Colors.green,
                                ),
                                title: Text('User created successfully'),
                              ),
                            );
                          },
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showToast(
                          context: context,
                          builder: (context, overlay) {
                            return SurfaceCard(
                              child: Basic(
                                leading: const Icon(
                                  BootstrapIcons.exclamationCircle,
                                  color: Colors.red,
                                ),
                                title: Text('Failed to create user: $e'),
                              ),
                            );
                          },
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
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
                    'Users Management',
                    style: theme.typography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Manage all users registered in the system',
                  ).muted(),
                ],
              ),
              Row(
                children: [
                  Button.primary(
                    onPressed: _createUser,
                    child: const Row(
                      children: [
                        Icon(BootstrapIcons.plus, size: 16),
                        Gap(8),
                        Text('Create User'),
                      ],
                    ),
                  ),
                  const Gap(12),
                  Button.outline(
                    onPressed: _fetchUsers,
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
            ],
          ),
          const Gap(32),
          Expanded(
            child: FutureBuilder<List<User>>(
              future: _usersFuture,
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
                final users = snapshot.data!;
                if (users.isEmpty) {
                  return Center(child: const Text('No users found').muted());
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return SurfaceCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Avatar(
                              initials: user.name?.isNotEmpty == true
                                  ? user.name!.substring(0, 1).toUpperCase()
                                  : user.email.substring(0, 1).toUpperCase(),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name ?? 'No Name',
                                    style: theme.typography.base.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(user.email).muted(),
                                ],
                              ),
                            ),
                            const Gap(16),
                            if (user.isAdmin)
                              const PrimaryBadge(child: Text('Admin'))
                            else
                              const SecondaryBadge(child: Text('User')),
                            const Gap(16),
                            IconButton.ghost(
                              size: ButtonSize.small,
                              onPressed: () => _editUser(user),
                              icon: const Icon(BootstrapIcons.pencil, size: 14),
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
