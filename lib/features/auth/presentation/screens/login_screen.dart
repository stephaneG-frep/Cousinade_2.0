import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/help_action.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        actions: const [HelpAction()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Heureux de te revoir',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Connecte-toi pour retrouver ta famille.'),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  validator: Validators.password,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: const Text('Mot de passe oublie ?'),
                  ),
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: 'Se connecter',
                  isLoading: authState.isLoading,
                  icon: Icons.login,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('Pas encore de compte ? Creer un compte'),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.userGuide),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Besoin d\'aide ? Ouvrir le guide'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
