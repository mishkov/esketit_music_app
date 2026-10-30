import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/agent/agent_localization.dart';
import 'package:esketit_music_app/ui/agent/agent_routes.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_inbox_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgentInboxScreen extends StatelessWidget {
  const AgentInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: BlocBuilder<AgentInboxBloc, AgentInboxState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => openAgentDraft(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(context.l10n.agentNewChat),
                      ),
                      if (state.notificationsAvailable)
                        OutlinedButton.icon(
                          onPressed: () => _enableNotifications(context),
                          icon: const Icon(Icons.notifications_outlined),
                          label: Text(context.l10n.agentEnableNotifications),
                        ),
                    ],
                  ),
                ),
                if (state.hasError)
                  MaterialBanner(
                    content: Text(context.l10n.requestFailedMessage),
                    actions: [
                      TextButton(
                        onPressed: () => _refresh(context),
                        child: Text(context.l10n.agentRetry),
                      ),
                    ],
                  ),
                Expanded(
                  child: state.conversations.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.l10n.agentEmptyTitle,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.l10n.agentEmptyBody,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _refresh(context),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.conversations.length,
                            itemBuilder: (context, index) {
                              final conversation = state.conversations[index];

                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    conversation.pendingQuestion == null
                                        ? Icons.chat_bubble_outline_rounded
                                        : Icons.help_outline_rounded,
                                  ),
                                  title: Text(
                                    conversation.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    agentStatusLabel(
                                      context.l10n,
                                      conversation.status,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => openAgentConversation(
                                    context,
                                    conversation.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _refresh(BuildContext context) =>
      context.read<AgentInboxBloc>().add(const AgentInboxRefreshRequested());

  void _enableNotifications(BuildContext context) =>
      context.read<AgentInboxBloc>().add(
        AgentNotificationsRequested(
          Localizations.localeOf(context).languageCode,
        ),
      );
}
