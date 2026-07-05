import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersion extends StatefulWidget {
  const AppVersion({super.key});

  @override
  State<AppVersion> createState() => _AppVersionState();
}

class _AppVersionState extends State<AppVersion> {
  final Future<PackageInfo> _packageInfoFuture = PackageInfo.fromPlatform();

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
