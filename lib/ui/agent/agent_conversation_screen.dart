import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/agent/agent_attachment_chip.dart';
import 'package:esketit_music_app/ui/agent/agent_localization.dart';
import 'package:esketit_music_app/ui/agent/agent_message_card.dart';
import 'package:esketit_music_app/ui/agent/agent_question_card.dart';
import 'package:esketit_music_app/ui/agent/agent_routes.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_conversation_bloc.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_inbox_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgentConversationScreen extends StatefulWidget {
  const AgentConversationScreen({super.key});

  @override
  State<AgentConversationScreen> createState() =>
      _AgentConversationScreenState();
}

class _AgentConversationScreenState extends State<AgentConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastSentMessageCount = 0;
  bool _reportedConversationRoute = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AgentInboxBloc, AgentInboxState, bool>(
      selector: (state) => state.canUseAgent,
      builder: (context, allowed) {
        if (!allowed) {
          return ScreenSkeleton(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.forbiddenActionMessage)),
          );
        }

        return BlocConsumer<AgentConversationBloc, AgentConversationState>(
          listenWhen: (previous, current) =>
              previous.sentMessageCount != current.sentMessageCount ||
              previous.conversation?.messages.length !=
                  current.conversation?.messages.length,
          listener: _onConversationChanged,
          builder: (context, state) {
            final conversation = state.conversation;
            final draftAttachment = context
                .read<AgentConversationBloc>()
                .attachment;
            final attachments = conversation?.attachments ?? [?draftAttachment];
            final question = conversation?.pendingQuestion;
            final cancelled =
                conversation?.status == AgentConversationStatus.cancelled;
            final canSend = !state.isSubmitting && !cancelled;
            final messages = conversation?.messages ?? const <AgentMessage>[];

            return ScreenSkeleton(
              appBar: AppBar(
                title: Text(context.l10n.agentTitle),
                actions: [
                  if (conversation != null && !cancelled)
                    IconButton(
                      tooltip: context.l10n.agentCancelRequest,
                      onPressed: state.isSubmitting ? null : _cancel,
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    children: [
                      if (attachments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: attachments
                                .map(
                                  (attachment) => AgentAttachmentChip(
                                    attachment: attachment,
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      if (conversation != null)
                        _statusBar(context, conversation, state.isSubmitting),
                      if (state.hasError)
                        MaterialBanner(
                          content: Text(context.l10n.requestFailedMessage),
                          actions: [
                            TextButton(
                              onPressed: _retry,
                              child: Text(context.l10n.agentRetry),
                            ),
                          ],
                        ),
                      Expanded(
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                children: [
                                  if (messages.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome_outlined,
                                            size: 44,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            context.l10n.agentEmptyTitle,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            context.l10n.agentDraftHint,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ...messages
                                      .where(
                                        (message) => message.id != question?.id,
                                      )
                                      .map(
                                        (message) =>
                                            AgentMessageCard(message: message),
                                      ),
                                  if (conversation != null)
                                    ...conversation.submissions.map(
                                      (submission) => ListTile(
                                        leading: const Icon(
                                          Icons.fact_check_outlined,
                                        ),
                                        title: Text(
                                          agentReviewLabel(
                                            context.l10n,
                                            submission.status,
                                          ),
                                        ),
                                        subtitle: submission.item == null
                                            ? null
                                            : AgentAttachmentChip(
                                                attachment: submission.item!,
                                              ),
                                      ),
                                    ),
                                  if (question != null && !cancelled)
                                    AgentQuestionCard(
                                      question: question,
                                      isEnabled: canSend,
                                    ),
                                ],
                              ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  minLines: 1,
                                  maxLines: 5,
                                  enabled: canSend,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    hintText: question == null
                                        ? context.l10n.agentMessageHint
                                        : context.l10n.agentAnswerHint,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                tooltip: context.l10n.agentSend,
                                onPressed: canSend ? _send : null,
                                icon: state.isSubmitting
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_upward_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusBar(
    BuildContext context,
    AgentConversation conversation,
    bool submitting,
  ) {
    final status = conversation.status;
    final paused = status == AgentConversationStatus.paused;
    final active = !const [
      AgentConversationStatus.completed,
      AgentConversationStatus.cancelled,
      AgentConversationStatus.stopping,
    ].contains(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  agentStatusLabel(context.l10n, status),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (active)
                TextButton.icon(
                  onPressed: submitting
                      ? null
                      : () => _control(
                          paused ? AgentControl.resume : AgentControl.stop,
                        ),
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.stop_rounded,
                  ),
                  label: Text(
                    paused ? context.l10n.agentResume : context.l10n.agentStop,
                  ),
                ),
            ],
          ),
          if (paused) Text(context.l10n.agentPausedHint),
          if (status == AgentConversationStatus.waitingForItem)
            Text(context.l10n.agentQueueHint),
          for (final identifier in conversation.blockingConversationIds)
            TextButton(
              onPressed: () => openAgentConversation(context, identifier),
              child: Text(context.l10n.agentEarlierChat),
            ),
        ],
      ),
    );
  }

  void _onConversationChanged(
    BuildContext context,
    AgentConversationState state,
  ) {
    final conversation = state.conversation;
    if (!_reportedConversationRoute &&
        conversation != null &&
        ModalRoute.of(context)?.settings.name == agentNewChatRoute) {
      _reportedConversationRoute = true;
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse(agentConversationRoute(conversation.id)),
        replace: true,
      );
    }
    final sentMessage = state.sentMessageCount > _lastSentMessageCount;
    _lastSentMessageCount = state.sentMessageCount;
    if (sentMessage) _messageController.clear();
    final shouldScroll =
        sentMessage ||
        !_scrollController.hasClients ||
        _scrollController.position.extentAfter < 120;
    context.read<AgentInboxBloc>().add(const AgentInboxRefreshRequested());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && shouldScroll && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final bloc = context.read<AgentConversationBloc>();
    final question = bloc.state.conversation?.pendingQuestion;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final resuming =
        bloc.state.conversation?.status == AgentConversationStatus.paused &&
        const [
          'resume',
          'continue',
          'продолжить',
          'продолжай',
        ].contains(text.toLowerCase());
    bloc.add(
      question == null || resuming
          ? AgentMessageSent(text, Localizations.localeOf(context).languageCode)
          : AgentAnswerSent(question.id, text),
    );
  }

  void _control(AgentControl control) =>
      context.read<AgentConversationBloc>().add(AgentControlRequested(control));

  void _retry() => context.read<AgentConversationBloc>().add(
    const AgentConversationRefreshRequested(),
  );

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.agentCancelTitle),
        content: Text(context.l10n.agentCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.agentCancelRequest),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _control(AgentControl.cancel);
  }
}
