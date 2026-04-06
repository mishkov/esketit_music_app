import 'package:esketit_music_app/ui/auth/sign_in_screen.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EsketitDrawer extends StatelessWidget {
  const EsketitDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.session?.user;

          return ListView(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  user == null ? 'Guest mode' : user.role.name.toUpperCase(),
                ),
                accountEmail: Text(
                  user?.email ?? 'Sign in to unlock protected features',
                ),
              ),
              if (user == null)
                ListTile(
                  leading: const Icon(Icons.login_rounded),
                  title: const Text('Sign in'),
                  onTap: () => _openSignIn(context),
                ),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Settings'),
                onTap: () => Navigator.of(context).pop(),
              ),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: state.isSubmitting ? null : () => _signOut(context),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openSignIn(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    );
  }

  void _signOut(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    context.read<AuthBloc>().add(const AuthSignOutRequested());
  }
}
