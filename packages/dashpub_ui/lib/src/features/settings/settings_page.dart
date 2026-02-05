import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dashpub_ui/src/features/auth/auth_bloc.dart';
import 'package:dashpub_ui/main.dart';
import 'package:dashpub_api/dashpub_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _cliToken;
  bool _publicAccess = false;
  bool _defaultPrivate = true;
  bool _registrationOpen = true;
  bool _isLoadingSettings = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _siteTitleController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _faviconUrlController = TextEditingController();
  final TextEditingController _allowedEmailDomainsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSettings();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _nameController.text = authState.user.name ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _siteTitleController.dispose();
    _logoUrlController.dispose();
    _faviconUrlController.dispose();
    _allowedEmailDomainsController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    try {
      final settings = await apiClient.getSettings();
      if (!mounted) return;
      setState(() {
        _publicAccess = settings.publicAccess;
        _defaultPrivate = settings.defaultPrivate;
        _registrationOpen = settings.registrationOpen;
        _siteTitleController.text = settings.siteTitle ?? '';
        _logoUrlController.text = settings.logoUrl ?? '';
        _faviconUrlController.text = settings.faviconUrl ?? '';
        _allowedEmailDomainsController.text = settings.allowedEmailDomains.join(
          ', ',
        );
        _isLoadingSettings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSettings = false;
      });
      // Error is expected if user is not authorized or system not fully set up
    }
  }

  Future<void> _saveGlobalSettings() async {
    try {
      await apiClient.updateSettings(
        GlobalSettings(
          _publicAccess,
          _defaultPrivate,
          siteTitle: _siteTitleController.text,
          logoUrl: _logoUrlController.text,
          faviconUrl: _faviconUrlController.text.isEmpty
              ? null
              : _faviconUrlController.text,
          registrationOpen: _registrationOpen,
          allowedEmailDomains: _allowedEmailDomainsController.text.isEmpty
              ? []
              : _allowedEmailDomainsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
        ),
      );
      if (!mounted) return;
      showToast(
        context: context,
        builder: (context, overlay) => const SurfaceCard(
          child: Basic(
            title: Text('Success'),
            content: Text('Global settings updated'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showToast(
        context: context,
        builder: (context, overlay) => SurfaceCard(
          child: Basic(title: const Text('Error'), content: Text('$e')),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      final updatedUser = await apiClient.updateMe(name: _nameController.text);
      if (!mounted) return;
      context.read<AuthBloc>().add(UpdateUser(updatedUser));
      showToast(
        context: context,
        builder: (context, overlay) => const SurfaceCard(
          child: Basic(
            title: Text('Success'),
            content: Text('Profile updated'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showToast(
        context: context,
        builder: (context, overlay) => SurfaceCard(
          child: Basic(title: const Text('Error'), content: Text('$e')),
        ),
      );
    }
  }

  void _generateToken() async {
    try {
      final token = await apiClient.generateToken();
      if (!mounted) return;
      setState(() {
        _cliToken = token;
      });
      showToast(
        context: context,
        builder: (context, overlay) => const SurfaceCard(
          child: Basic(
            title: Text('Success'),
            content: Text('Token generated successfully'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showToast(
        context: context,
        builder: (context, overlay) => SurfaceCard(
          child: Basic(title: const Text('Error'), content: Text('$e')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Center(child: Text('Login to view settings'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: theme.typography.h2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(32),
              _section(
                context,
                title: 'CLI Authentication',
                description: 'Generate a token to use with the dashpub CLI.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_cliToken != null) ...[
                      const Gap(16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _cliToken!,
                                style: theme.typography.mono,
                              ),
                            ),
                            const Gap(8),
                            Button(
                              style: ButtonStyle.ghost(size: ButtonSize.small),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _cliToken!),
                                );
                                if (!mounted) return;
                                showToast(
                                  context: context,
                                  builder: (context, overlay) =>
                                      const SurfaceCard(
                                        child: Basic(
                                          title: Text('Copied'),
                                          content: Text('Copied to clipboard'),
                                        ),
                                      ),
                                );
                              },
                              child: const Icon(BootstrapIcons.copy, size: 14),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Keep this token secret. Anyone with it can upload packages on your behalf.',
                      ).muted().small(),
                    ],
                    const Gap(16),
                    Button.outline(
                      onPressed: _generateToken,
                      child: Text(
                        _cliToken == null
                            ? 'Generate CLI Token'
                            : 'Regenerate Token',
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(48),
              if (!_isLoadingSettings && state.user.isAdmin) ...[
                _section(
                  context,
                  title: 'Global Settings',
                  description: 'Manage registry-wide configuration.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Site Branding').medium(),
                      const Gap(16),
                      const Label(child: Text('Site Title')),
                      const Gap(8),
                      TextField(
                        controller: _siteTitleController,
                        placeholder: const Text('Dashpub'),
                      ),
                      const Gap(16),
                      const Label(child: Text('Logo URL')),
                      const Gap(8),
                      TextField(
                        controller: _logoUrlController,
                        placeholder: const Text('https://example.com/logo.png'),
                      ),
                      const Gap(16),
                      const Label(child: Text('Favicon URL')),
                      const Gap(8),
                      TextField(
                        controller: _faviconUrlController,
                        placeholder: const Text(
                          'https://example.com/favicon.ico',
                        ),
                      ),
                      const Gap(24),
                      const Divider(),
                      const Gap(24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Public Access').medium(),
                                const Text(
                                  'Allow anyone to browse and download packages without authentication.',
                                ).muted().small(),
                              ],
                            ),
                          ),
                          Switch(
                            value: _publicAccess,
                            onChanged: (value) {
                              setState(() {
                                _publicAccess = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const Gap(24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Default Private').medium(),
                                const Text(
                                  'New packages are private by default.',
                                ).muted().small(),
                              ],
                            ),
                          ),
                          Switch(
                            value: _defaultPrivate,
                            onChanged: (value) {
                              setState(() {
                                _defaultPrivate = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const Gap(24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Registration Open').medium(),
                                const Text(
                                  'Allow new users to register.',
                                ).muted().small(),
                              ],
                            ),
                          ),
                          Switch(
                            value: _registrationOpen,
                            onChanged: (value) {
                              setState(() {
                                _registrationOpen = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const Gap(24),
                      const Label(child: Text('Allowed Email Domains')),
                      const Gap(8),
                      TextField(
                        controller: _allowedEmailDomainsController,
                        placeholder: const Text(
                          'example.com, company.net (leave empty for all)',
                        ),
                      ),
                      const Gap(4),
                      const Text(
                        'Comma separated list of allowed email domains for registration.',
                      ).muted().small(),
                      const Gap(32),
                      Button.primary(
                        onPressed: _saveGlobalSettings,
                        child: const Text('Update Global Settings'),
                      ),
                    ],
                  ),
                ),
                const Gap(48),
              ],
              _section(
                context,
                title: 'User Profile',
                description: 'Update your account details.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Label(child: Text('Full Name')),
                    const Gap(8),
                    TextField(
                      controller: _nameController,
                      placeholder: const Text('John Doe'),
                    ),
                    const Gap(24),
                    const Label(child: Text('Login Email')),
                    const Gap(8),
                    TextField(initialValue: state.user.email, enabled: false),
                    const Gap(32),
                    Button.primary(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
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

  Widget _section(
    BuildContext context, {
    required String title,
    required String description,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.typography.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(description).muted(),
        const Gap(24),
        child,
      ],
    );
  }
}
