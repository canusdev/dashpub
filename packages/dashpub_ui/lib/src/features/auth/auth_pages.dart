import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dashpub_ui/src/features/auth/auth_bloc.dart';

import 'package:dashpub_ui/main.dart'; // For apiClient

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _canRegister = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    try {
      final settings = await apiClient.getSettings();
      if (!mounted) return;
      setState(() {
        _canRegister =
            settings.registrationOpen ||
            settings.allowedEmailDomains.isNotEmpty;
      });
    } catch (_) {
      // Ignore errors (e.g. offline), default to false
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Login',
                    style: theme.typography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  const Text(
                    'Enter your details to access your account',
                    textAlign: TextAlign.center,
                  ).muted(),
                  const Gap(32),
                  const Label(child: Text('Email')),
                  const Gap(8),
                  TextField(
                    controller: _emailController,
                    placeholder: const Text('m@example.com'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const Gap(24),
                  const Label(child: Text('Password')),
                  const Gap(8),
                  TextField(
                    controller: _passwordController,
                    placeholder: const Text('••••••••'),
                    obscureText: true,
                  ),
                  const Gap(32),
                  BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is Authenticated) {
                        context.go('/');
                      } else if (state is AuthFailure) {
                        showToast(
                          context: context,
                          builder: (context, overlay) => SurfaceCard(
                            child: Basic(title: Text(state.message)),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      return Button.primary(
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(
                                  LoginRequested(
                                    _emailController.text,
                                    _passwordController.text,
                                  ),
                                );
                              },
                        child: state is AuthLoading
                            ? const CircularProgressIndicator()
                            : const Text('Login'),
                      );
                    },
                  ),
                  if (_canRegister) ...[
                    const Gap(16),
                    Center(
                      child: Button.ghost(
                        onPressed: () => context.go('/register'),
                        child: const Text("Don't have an account? Register"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Register',
                    style: theme.typography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  const Text(
                    'Create a new account',
                    textAlign: TextAlign.center,
                  ).muted(),
                  const Gap(32),
                  const Label(child: Text('Full Name')),
                  const Gap(8),
                  TextField(
                    controller: _nameController,
                    placeholder: const Text('John Doe'),
                  ),
                  const Gap(16),
                  const Label(child: Text('Email')),
                  const Gap(8),
                  TextField(
                    controller: _emailController,
                    placeholder: const Text('m@example.com'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const Gap(16),
                  const Label(child: Text('Password')),
                  const Gap(8),
                  TextField(
                    controller: _passwordController,
                    placeholder: const Text('••••••••'),
                    obscureText: true,
                  ),
                  const Gap(32),
                  BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is Authenticated) {
                        context.go('/');
                      } else if (state is AuthFailure) {
                        showToast(
                          context: context,
                          builder: (context, overlay) => SurfaceCard(
                            child: Basic(title: Text(state.message)),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      return Button.primary(
                        onPressed: state is AuthLoading
                            ? null
                            : () {
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
                            : const Text('Register'),
                      );
                    },
                  ),
                  const Gap(16),
                  Center(
                    child: Button.ghost(
                      onPressed: () => context.go('/login'),
                      child: const Text("Already have an account? Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
