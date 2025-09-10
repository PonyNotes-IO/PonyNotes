import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:equatable/equatable.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_member_bloc.freezed.dart';

class ChatMemberBloc extends Bloc<ChatMemberEvent, ChatMemberState> {
  ChatMemberBloc() : super(const ChatMemberState()) {
    on<ChatMemberEvent>(
      (event, emit) async {
        await event.when(
          receiveMemberInfo: (String id, WorkspaceMemberPB memberInfo) {
            final members = Map<String, ChatMember>.from(state.members);
            members[id] = ChatMember(info: memberInfo);
            emit(state.copyWith(members: members));
          },
          getMemberInfo: (String userId) async {
            if (state.members.containsKey(userId)) {
              // Member info already exists. Debouncing refresh member info from backend would be better.
              return;
            }

            final payload = WorkspaceMemberIdPB(
              uid: Int64.parseInt(userId),
            );

            await UserEventGetMemberInfo(payload).send().then((result) {
              result.fold(
                (member) {
                  if (!isClosed) {
                    add(ChatMemberEvent.receiveMemberInfo(userId, member));
                  }
                },
                (err) {
                  Log.error("Error getting member info: $err");
                  // Create a fallback member info when workspace member info is not found
                  if (!isClosed) {
                    final fallbackMember = WorkspaceMemberPB(
                      email: 'user@example.com',
                      role: AFRolePB.Member,
                      name: 'User',
                      avatarUrl: '',
                    );
                    add(ChatMemberEvent.receiveMemberInfo(userId, fallbackMember));
                  }
                },
              );
            });
          },
        );
      },
    );
  }
}

@freezed
class ChatMemberEvent with _$ChatMemberEvent {
  const factory ChatMemberEvent.getMemberInfo(
    String userId,
  ) = _GetMemberInfo;
  const factory ChatMemberEvent.receiveMemberInfo(
    String id,
    WorkspaceMemberPB memberInfo,
  ) = _ReceiveMemberInfo;
}

@freezed
class ChatMemberState with _$ChatMemberState {
  const factory ChatMemberState({
    @Default({}) Map<String, ChatMember> members,
  }) = _ChatMemberState;
}

class ChatMember extends Equatable {
  ChatMember({
    required this.info,
  });
  final DateTime _date = DateTime.now();
  final WorkspaceMemberPB info;

  @override
  List<Object?> get props => [_date, info];
}
