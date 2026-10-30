import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';

String agentStatusLabel(
  AppLocalizations localization,
  AgentConversationStatus status,
) => switch (status) {
  AgentConversationStatus.queued => localization.agentQueued,
  AgentConversationStatus.working => localization.agentWorking,
  AgentConversationStatus.waitingForItem => localization.agentWaitingForItem,
  AgentConversationStatus.waitingForAnswer =>
    localization.agentWaitingForAnswer,
  AgentConversationStatus.waitingForReview =>
    localization.agentWaitingForReview,
  AgentConversationStatus.stopping => localization.agentStopping,
  AgentConversationStatus.paused => localization.agentPaused,
  AgentConversationStatus.completed => localization.agentCompleted,
  AgentConversationStatus.cancelled => localization.agentCancelled,
  AgentConversationStatus.failed => localization.agentFailed,
};

String agentItemLabel(AppLocalizations localization, AgentItemType type) =>
    switch (type) {
      AgentItemType.track => localization.agentTrackLabel,
      AgentItemType.album => localization.agentAlbumLabel,
      AgentItemType.author => localization.agentAuthorLabel,
    };

String agentReviewLabel(
  AppLocalizations localization,
  AgentReviewStatus status,
) => switch (status) {
  AgentReviewStatus.pending => localization.agentReviewPending,
  AgentReviewStatus.changesRequested => localization.agentReviewChanges,
  AgentReviewStatus.approved => localization.agentReviewApproved,
  AgentReviewStatus.rejected => localization.agentReviewRejected,
  AgentReviewStatus.cancelled => localization.agentReviewCancelled,
};
