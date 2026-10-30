import 'package:equatable/equatable.dart';

enum AgentItemType { track, album, author }

enum AgentConversationStatus {
  queued,
  working,
  waitingForItem,
  waitingForAnswer,
  waitingForReview,
  stopping,
  paused,
  completed,
  cancelled,
  failed,
}

enum AgentMessageRole { user, assistant, system }

enum AgentMessageEvent { reviewUpdated, operationFailed }

class AgentAttachment extends Equatable {
  const AgentAttachment({
    required this.type,
    required this.id,
    required this.label,
  });

  final AgentItemType type;
  final int id;
  final String label;

  @override
  List<Object?> get props => [type, id, label];
}

class AgentMessage extends Equatable {
  const AgentMessage({
    required this.id,
    required this.role,
    required this.text,
    this.event,
  });

  final String id;
  final AgentMessageRole role;
  final String text;
  final AgentMessageEvent? event;

  @override
  List<Object?> get props => [id, role, text, event];
}

class AgentQuestion extends Equatable {
  const AgentQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.answer,
  });

  final String id;
  final String text;
  final List<String> options;
  final String? answer;

  @override
  List<Object?> get props => [id, text, options, answer];
}

class AgentSubmission extends Equatable {
  const AgentSubmission({required this.id, required this.status, this.item});

  final int id;
  final AgentReviewStatus status;
  final AgentAttachment? item;

  @override
  List<Object?> get props => [id, status, item];
}

enum AgentReviewStatus {
  pending,
  changesRequested,
  approved,
  rejected,
  cancelled,
}

class AgentConversation extends Equatable {
  const AgentConversation({
    required this.id,
    required this.title,
    required this.status,
    required this.attachments,
    required this.messages,
    required this.questions,
    required this.submissions,
    required this.blockingConversationIds,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final AgentConversationStatus status;
  final List<AgentAttachment> attachments;
  final List<AgentMessage> messages;
  final List<AgentQuestion> questions;
  final List<AgentSubmission> submissions;
  final List<String> blockingConversationIds;
  final DateTime updatedAt;

  AgentQuestion? get pendingQuestion {
    for (final question in questions) {
      if (question.answer == null) return question;
    }

    return null;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    status,
    attachments,
    messages,
    questions,
    submissions,
    blockingConversationIds,
    updatedAt,
  ];
}
