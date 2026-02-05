import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dashpub_ui/src/features/auth/auth_bloc.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SurfaceCard(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/dashpub.png',
                            height: 48,
                            width: 48,
                          ),
                        ),
                      ),
                      const Gap(24),
                      Center(
                        child: Text(
                          'Initial Administrator Setup',
                          style: theme.typography.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Gap(12),
                      Center(
                        child: Text(
                          'Welcome to Dashpub. To secure your private registry, please create the first administrator account.',
                          textAlign: TextAlign.center,
                        ).muted(),
                      ),
                      const Gap(40),
                      Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Label(child: Text('Full Name')),
                            const Gap(8),
                            TextField(
                              controller: _nameController,
                              placeholder: const Text('e.g. John Doe'),
                            ),
                            const Gap(24),
                            const Label(child: Text('Admin Email')),
                            const Gap(8),
                            TextField(
                              controller: _emailController,
                              placeholder: const Text('admin@example.com'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const Gap(24),
                            const Label(child: Text('Secure Password')),
                            const Gap(8),
                            TextField(
                              controller: _passwordController,
                              placeholder: const Text('••••••••'),
                              obscureText: true,
                            ),
                            const Gap(40),
                            BlocConsumer<AuthBloc, AuthState>(
                              listener: (context, state) {
                                if (state is Authenticated) {
                                  context.go('/');
                                } else if (state is AuthFailure) {
                                  showToast(
                                    context: context,
                                    builder: (context, overlay) {
                                      final theme = Theme.of(context);
                                      return SurfaceCard(
                                        child: Basic(
                                          leading: Icon(
                                            BootstrapIcons.exclamationCircle,
                                            color:
                                                theme.colorScheme.destructive,
                                          ),
                                          title: const Text('Setup Failed'),
                                          content: Text(state.message),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                              builder: (context, state) {
                                return Button.primary(
                                  onPressed: state is AuthLoading
                                      ? null
                                      : () {
                                          if (_emailController.text.isEmpty ||
                                              _passwordController
                                                  .text
                                                  .isEmpty) {
                                            return;
                                          }
                                          context.read<AuthBloc>().add(
                                            RegisterRequested(
                                              _emailController.text,
                                              _passwordController.text,
                                              _nameController.text,
                                            ),
                                          );
                                        },
                                  child: state is AuthLoading
                                      ? const CircularProgressIndicator()
                                      : const Text('Install & Create Admin'),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(24),
              const Text(
                'This screen will never appear again after initialization.',
              ).xSmall().muted(),
            ],
          ),
        ),
      ),
    );
  }
}
