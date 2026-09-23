part of 'blocked_users_cubit.dart';

enum BlockedUsersStatus { initial, loading, loaded, error }

class BlockedUsersState extends Equatable {
  const BlockedUsersState({
    this.status = BlockedUsersStatus.initial,
    this.blockedUsers = const <BlockedUserEntity>[],
    this.errorMessage,
  });

  final BlockedUsersStatus status;
  final List<BlockedUserEntity> blockedUsers;
  final String? errorMessage;

  BlockedUsersState copyWith({
    BlockedUsersStatus? status,
    List<BlockedUserEntity>? blockedUsers,
    String? errorMessage,
  }) {
    return BlockedUsersState(
      status: status ?? this.status,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, blockedUsers, errorMessage];
}
