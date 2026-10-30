import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_conversation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgentQuestionCard extends StatelessWidget {
  const AgentQuestionCard({
    required this.question,
    required this.isEnabled,
    super.key,
  });

  final AgentQuestion question;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              question.text,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.options
                  .map(
                    (option) => OutlinedButton(
                      onPressed: isEnabled
                          ? () => _answer(context, option)
                          : null,
                      child: Text(option),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  void _answer(BuildContext context, String answer) => context
      .read<AgentConversationBloc>()
      .add(AgentAnswerSent(question.id, answer));
}
