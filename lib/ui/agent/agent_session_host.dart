import 'dart:async';

import 'package:esketit_music_app/ui/agent/agent_routes.dart';
import 'package:esketit_music_app/ui/agent/agent_access_scope.dart';
import 'package:esketit_music_app/ui/esketit_app.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_inbox_bloc.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgentSessionHost extends StatefulWidget {
  const AgentSessionHost({required this.child, super.key});

  final Widget child;

  @override
  State<AgentSessionHost> createState() => _AgentSessionHostState();
}

class _AgentSessionHostState extends State<AgentSessionHost> {
  StreamSubscription<String>? _notificationSubscription;
  String? _pendingConversation;

  @override
  void initState() {
    super.initState();
    final inbox = context.read<AgentInboxBloc>();
    inbox.add(
      AgentAccountChanged(context.read<AuthBloc>().state.session?.user.id),
    );
    _notificationSubscription = inbox.openedConversations.listen(
      _onNotification,
    );
  }

  void _onNotification(String identifier) {
    _pendingConversation = identifier;
    _openPending();
  }

  void _openPending() {
    final identifier = _pendingConversation;
    if (identifier == null ||
        !context.read<AgentInboxBloc>().state.canUseAgent) {
      return;
    }
    final navigator = EsketitApp.navigatorKey.currentState;
    if (navigator == null) return;
    _pendingConversation = null;
    navigator.pushNamed(agentConversationRoute(identifier));
  }

  @override
  void dispose() {
    unawaited(_notificationSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AgentInboxBloc, AgentInboxState, bool>(
      selector: (state) => state.canUseAgent,
      builder: (context, allowed) => AgentAccessScope(
        allowed: allowed,
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  previous.session != current.session,
              listener: (context, state) => context.read<AgentInboxBloc>().add(
                AgentAccountChanged(state.session?.user.id),
              ),
            ),
            BlocListener<AgentInboxBloc, AgentInboxState>(
              listenWhen: (previous, current) =>
                  previous.canUseAgent != current.canUseAgent,
              listener: (context, state) => _openPending(),
            ),
          ],
          child: widget.child,
        ),
      ),
    );
  }
}
