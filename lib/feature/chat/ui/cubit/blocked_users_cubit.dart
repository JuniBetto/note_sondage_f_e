import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/chat/domain/entities/blocked_user_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';

part 'blocked_users_state.dart';

/// Backs the "Blocked users" settings screen — independent of [ChatBloc]
/// (which owns the open-conversation concern) since managing the block list
/// from Settings is a separate, narrower concern. Mirrors the granularity of
/// `WorkflowAiPreferencesCubit`, a small satellite cubit alongside the chat
/// feature's main bloc.
class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  BlockedUsersCubit(this._chatUseCase) : super(const BlockedUsersState());

  final ChatUseCase _chatUseCase;

  Future<void> load() async {
    if (state.status == BlockedUsersStatus.loading) {
      return;
    }
    emit(
      state.copyWith(status: BlockedUsersStatus.loading, errorMessage: null),
    );
    try {
      final blockedUsers = await _chatUseCase.getBlockedUsers();
      emit(
        state.copyWith(
          status: BlockedUsersStatus.loaded,
          blockedUsers: blockedUsers,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: BlockedUsersStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> unblock(String userId) async {
    final previousBlockedUsers = state.blockedUsers;
    final optimisticBlockedUsers = previousBlockedUsers
        .where((user) => user.userId != userId)
        .toList();
    emit(
      state.copyWith(blockedUsers: optimisticBlockedUsers, errorMessage: null),
    );
    try {
      await _chatUseCase.unblockUser(userId);
    } catch (error) {
      emit(
        state.copyWith(
          blockedUsers: previousBlockedUsers,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
