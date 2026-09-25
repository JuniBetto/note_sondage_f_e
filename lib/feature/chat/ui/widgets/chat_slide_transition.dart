import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared slide used when moving between the chat list and a conversation on
/// both mobile (a routed page) and web (an in-place switch): the conversation
/// enters from the right and leaves to the right; the list does the opposite.
const Duration chatSlideDuration = Duration(milliseconds: 280);

/// Passed as `extra` when pushing the mobile conversation route so only the
/// list → conversation path animates; other entry points (dashboard,
/// notifications, deep links) keep opening it without a transition.
const String chatSlideRouteExtra = 'chat-slide';

CustomTransitionPage<void> chatSlideRoutePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: chatSlideDuration,
    reverseTransitionDuration: chatSlideDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
        child: child,
      );
    },
  );
}

/// Key that marks the conversation child of a [ChatSlideSwitcher].
const ValueKey<String> chatConversationSlideKey = ValueKey<String>(
  'chat-conversation-slide',
);

/// Swaps between the chat list and a conversation with a horizontal slide.
/// The conversation child must use [chatConversationSlideKey]; any other key
/// is treated as the list. Keeping the conversation key constant means moving
/// from one conversation straight to another updates it in place (no slide).
class ChatSlideSwitcher extends StatelessWidget {
  const ChatSlideSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: animate ? chatSlideDuration : Duration.zero,
        reverseDuration: animate ? chatSlideDuration : Duration.zero,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final fromRight = child.key == chatConversationSlideKey;
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(fromRight ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        // Keep the parent's tight constraints so pages lay out exactly as they
        // did before the switcher was introduced.
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.passthrough,
          alignment: Alignment.topLeft,
          children: [...previousChildren, if (currentChild != null) currentChild],
        ),
        child: child,
      ),
    );
  }
}
