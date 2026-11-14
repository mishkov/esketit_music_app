import 'dart:async';

import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error_level.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentRichText extends StatelessWidget {
  const AgentRichText({required this.text, this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SelectionArea(
      child: MarkdownBody(
        data: text,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: style ?? theme.textTheme.bodyMedium,
          a: TextStyle(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
        // Research output must not fetch arbitrary remote or local images.
        imageBuilder: _hideImage,
        onTapLink: (_, destination, _) =>
            unawaited(_openSource(context, destination)),
      ),
    );
  }

  static Widget _hideImage(Uri uri, String? title, String? alternateText) =>
      const SizedBox.shrink();

  Future<void> _openSource(BuildContext context, String? destination) async {
    final uri = destination == null ? null : Uri.tryParse(destination);
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return;
    }
    final errorReporter = context.read<ErrorReporter>();
    unawaited(
      errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'Open agent research source',
          category: Category.uiClick,
          data: {'host': uri.host},
        ),
      ),
    );
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_, stackTrace) {
      unawaited(
        errorReporter.reportError(
          AppError(
            'Could not open agent research source',
            level: const AppErrorLevel.regular(),
            stackTrace: stackTrace,
          ),
        ),
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.requestFailedMessage)));
  }
}
