import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/auth/sign_in_screen.dart';
import 'package:esketit_music_app/ui/settings/settings_screen.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class EsketitDrawer extends StatelessWidget {
  const EsketitDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Drawer(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.session?.user;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    UserAccountsDrawerHeader(
                      accountName: Text(
                        user == null
                            ? l10n.guestModeLabel
                            : user.role.name.toUpperCase(),
                      ),
                      accountEmail: Text(
                        user?.email ?? l10n.signInToUnlockProtectedFeatures,
                      ),
                    ),
                    if (user == null)
                      ListTile(
                        leading: const Icon(Icons.login_rounded),
                        title: Text(l10n.signInTitle),
                        onTap: () => _openSignIn(context),
                      ),
                    ListTile(
                      leading: const Icon(Icons.settings_rounded),
                      title: Text(l10n.settingsTitle),
                      onTap: () => _openSettings(context),
                    ),
                    if (user != null)
                      ListTile(
                        leading: const Icon(Icons.logout_rounded),
                        title: Text(l10n.signOutButton),
                        onTap: state.isSubmitting
                            ? null
                            : () => _signOut(context),
                      ),
                  ],
                ),
              ),
              const _AppVersion(),
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

  void _openSettings(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }
}

class _AppVersion extends StatefulWidget {
  const _AppVersion();

  @override
  State<_AppVersion> createState() => _AppVersionState();
}

class _AppVersionState extends State<_AppVersion> {
  late final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: FutureBuilder<PackageInfo>(
        future: _packageInfoFuture,
        builder: (context, snapshot) {
          final info = snapshot.data;
          if (info == null) {
            return const SizedBox(height: 24);
          }

          final version = info.buildNumber.isEmpty
              ? info.version
              : '${info.version}+${info.buildNumber}';

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              l10n.appVersionLabel(version),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
