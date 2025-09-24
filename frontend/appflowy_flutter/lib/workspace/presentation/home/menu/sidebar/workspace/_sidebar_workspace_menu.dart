
import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/guest_tag.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import '_sidebar_import_notion.dart';

@visibleForTesting
const createWorkspaceButtonKey = ValueKey('createWorkspaceButton');

@visibleForTesting
const importNotionButtonKey = ValueKey('importNotionButton');

class WorkspacesMenu extends StatefulWidget {
  const WorkspacesMenu({
    super.key,
    required this.userProfile,
    required this.currentWorkspace,
    required this.workspaces,
  });

  final UserProfilePB userProfile;
  final UserWorkspacePB currentWorkspace;
  final List<UserWorkspacePB> workspaces;

  @override
  State<WorkspacesMenu> createState() => _WorkspacesMenuState();
}

class _WorkspacesMenuState extends State<WorkspacesMenu> {
  final popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // user email
        Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 6.0, right: 10.0),
          child: Row(
            children: [
              Expanded(
                child: FlowyText.medium(
                  _getUserInfo(),
                  fontSize: 12.0,
                  overflow: TextOverflow.ellipsis,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const HSpace(4.0),
              WorkspaceMoreButton(
                popoverMutex: popoverMutex,
              ),
              const HSpace(8.0),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
          child: Divider(height: 1.0),
        ),
        // workspace list
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final workspace in widget.workspaces) ...[
                  WorkspaceMenuItem(
                    key: ValueKey(workspace.workspaceId),
                    workspace: workspace,
                    userProfile: widget.userProfile,
                    isSelected: workspace.workspaceId ==
                        widget.currentWorkspace.workspaceId,
                    popoverMutex: popoverMutex,
                  ),
                  const VSpace(6.0),
                ],
              ],
            ),
          ),
        ),
        // add new workspace
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0),
          child: _CreateWorkspaceButton(),
        ),

        if (UniversalPlatform.isDesktop) ...[
          const Padding(
            padding: EdgeInsets.only(left: 6.0, top: 6.0, right: 6.0),
            child: _ImportNotionButton(),
          ),
        ],

        const VSpace(6.0),
      ],
    );
  }

  String _getUserInfo() {
    if (widget.userProfile.email.isNotEmpty) {
      return widget.userProfile.email;
    }

    if (widget.userProfile.name.isNotEmpty) {
      return widget.userProfile.name;
    }

    return LocaleKeys.defaultUsername.tr();
  }
}

class WorkspaceMenuItem extends StatefulWidget {
  const WorkspaceMenuItem({
    super.key,
    required this.workspace,
    required this.userProfile,
    required this.isSelected,
    required this.popoverMutex,
  });

  final UserProfilePB userProfile;
  final UserWorkspacePB workspace;
  final bool isSelected;
  final PopoverMutex popoverMutex;

  @override
  State<WorkspaceMenuItem> createState() => _WorkspaceMenuItemState();
}

class _WorkspaceMenuItemState extends State<WorkspaceMenuItem> {
  final ValueNotifier<bool> isHovered = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkspaceMemberBloc(
        userProfile: widget.userProfile,
        workspace: widget.workspace,
      )..add(const WorkspaceMemberEvent.initial()),
      child: BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
        builder: (context, state) {
          // settings right icon inside the flowy button will
          //  cause the popover dismiss intermediately when click the right icon.
          // so using the stack to put the right icon on the flowy button.
          return SizedBox(
            height: 44,
            child: MouseRegion(
              onEnter: (_) => isHovered.value = true,
              onExit: (_) => isHovered.value = false,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _WorkspaceInfo(
                    isSelected: widget.isSelected,
                    workspace: widget.workspace,
                  ),
                  Positioned(left: 4, child: _buildLeftIcon(context)),
                  Positioned(
                    right: 4.0,
                    child: Align(child: _buildRightIcon(context, isHovered)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftIcon(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.document_plugins_cover_changeIcon.tr(),
      child: WorkspaceIcon(
        workspaceName: widget.workspace.name,
        workspaceIcon: widget.workspace.icon,
        iconSize: 36,
        emojiSize: 24.0,
        fontSize: 18.0,
        figmaLineHeight: 26.0,
        borderRadius: 12.0,
        isEditable: true,
        onSelected: (result) => context.read<UserWorkspaceBloc>().add(
              UserWorkspaceEvent.updateWorkspaceIcon(
                workspaceId: widget.workspace.workspaceId,
                icon: result.emoji,
              ),
            ),
      ),
    );
  }

  Widget _buildRightIcon(BuildContext context, ValueNotifier<bool> isHovered) {
    return Row(
      children: [
        // only the owner can update or delete workspace.
        if (!context.read<WorkspaceMemberBloc>().state.isLoading)
          ValueListenableBuilder(
            valueListenable: isHovered,
            builder: (context, value, child) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Opacity(
                  opacity: value ? 1.0 : 0.0,
                  child: child,
                ),
              );
            },
            child: WorkspaceMoreActionList(
              workspace: widget.workspace,
              popoverMutex: widget.popoverMutex,
            ),
          ),
        const HSpace(8.0),
        if (widget.isSelected) ...[
          const Padding(
            padding: EdgeInsets.all(5.0),
            child: FlowySvg(
              FlowySvgs.workspace_selected_s,
              blendMode: null,
              size: Size.square(14.0),
            ),
          ),
          const HSpace(8.0),
        ],
      ],
    );
  }
}

class _WorkspaceInfo extends StatelessWidget {
  const _WorkspaceInfo({
    required this.isSelected,
    required this.workspace,
  });

  final bool isSelected;
  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    final memberCount = workspace.memberCount.toInt();
    return FlowyButton(
      onTap: () => _openWorkspace(context),
      iconPadding: 10.0,
      leftIconSize: const Size.square(32),
      leftIcon: const SizedBox.square(dimension: 32),
      rightIcon: const HSpace(32.0),
      text: Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // workspace name
                FlowyText.medium(
                  workspace.name,
                  fontSize: 14.0,
                  figmaLineHeight: 17.0,
                  overflow: TextOverflow.ellipsis,
                  withTooltip: true,
                ),
                if (workspace.role != AFRolePB.Guest) ...[
                  // workspace members count
                  FlowyText.regular(
                    memberCount == 0
                        ? ''
                        : LocaleKeys.settings_appearance_members_membersCount
                            .plural(
                            memberCount,
                          ),
                    fontSize: 10.0,
                    figmaLineHeight: 12.0,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ],
            ),
          ),
          if (workspace.role == AFRolePB.Guest) ...[
            const HSpace(6.0),
            GuestTag(),
          ],
        ],
      ),
    );
  }

  void _openWorkspace(BuildContext context) {
    if (!isSelected) {
      Log.info('open workspace: ${workspace.workspaceId}');

      // Only trigger workspace opening - TabsBloc will be handled in UserWorkspaceBloc
      context.read<UserWorkspaceBloc>().add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: workspace.workspaceId,
              workspaceType: workspace.workspaceType,
            ),
          );

      PopoverContainer.of(context).closeAll();
    }
  }
}

class CreateWorkspaceDialog extends StatefulWidget {
  const CreateWorkspaceDialog({
    super.key,
    required this.onConfirm,
  });

  final void Function(String name) onConfirm;

  @override
  State<CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends State<CreateWorkspaceDialog> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<UserWorkspaceBloc, UserWorkspaceState>(
      listenWhen: (previous, current) {
        return previous.actionResult?.actionType != current.actionResult?.actionType ||
            previous.actionResult?.isLoading != current.actionResult?.isLoading;
      },
      listener: (context, state) {
        final actionResult = state.actionResult;
        if (actionResult != null && 
            actionResult.actionType == WorkspaceActionType.create && 
            !actionResult.isLoading) {
          // 工作空间创建完成，检查context是否仍然mounted
          if (context.mounted) {
            // 使用SchedulerBinding确保在下一帧执行，避免Navigator状态冲突
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
          
          // 如果创建失败，记录错误信息
          actionResult.result?.fold(
            (success) {
              Log.info('Workspace created successfully');
            },
            (error) {
              Log.error('Failed to create workspace: ${error.msg}');
            },
          );
        }
      },
      child: _WorkspaceDialogContent(
        onConfirm: widget.onConfirm,
      ),
    );
  }
}

class _WorkspaceDialogContent extends StatelessWidget {
  const _WorkspaceDialogContent({
    required this.onConfirm,
  });

  final void Function(String) onConfirm;

  @override
  Widget build(BuildContext context) {
    return NavigatorTextFieldDialog(
      title: LocaleKeys.workspace_create.tr(),
      value: '',
      hintText: '',
      autoSelectAllText: true,
      onConfirm: (name, _) => onConfirm(name),
    );
  }
}

class _CreateWorkspaceButton extends StatelessWidget {
  const _CreateWorkspaceButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FlowyButton(
        key: createWorkspaceButtonKey,
        onTap: () async {
          Log.info('Create workspace button clicked');
          PopoverContainer.of(context).closeAll();
          // 等待一个微任务，确保 popover 关闭完成
          await Future.delayed(Duration.zero);
          if (context.mounted) {
            await _showCreateWorkspaceDialog(context);
          }
        },
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        text: Row(
          children: [
            _buildLeftIcon(context),
            const HSpace(8.0),
            FlowyText.regular(
              LocaleKeys.workspace_create.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftIcon(BuildContext context) {
    return Container(
      width: 36.0,
      height: 36.0,
      padding: const EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x01717171).withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: const FlowySvg(FlowySvgs.add_workspace_s),
    );
  }

  Future<void> _showCreateWorkspaceDialog(BuildContext context) async {
    if (!context.mounted) {
      Log.warn('Context is not mounted when trying to show create workspace dialog');
      return;
    }
    
    try {
      final workspaceBloc = context.read<UserWorkspaceBloc>();
      final userProfile = workspaceBloc.state.userProfile;
      
      Log.info('Showing create workspace dialog for user: ${userProfile.email}, auth type: ${userProfile.userAuthType}');
      
      final dialog = CreateWorkspaceDialog(
        onConfirm: (name) {
          // DEBUG BREAKPOINT 3: onConfirm 回调被调用
          Log.info('=== DEBUG BREAKPOINT 3 === onConfirm 回调被调用，工作空间名称: $name');
          
          if (name.trim().isEmpty) {
            Log.warn('Workspace name is empty, cannot create workspace');
            return;
          }
          
          // 智能选择工作空间类型：
          // 1. 如果用户是本地认证类型，创建本地工作空间
          // 2. 如果用户是服务器认证类型，优先创建本地工作空间（桌面端常用场景）
          final workspaceType = userProfile.userAuthType == AuthTypePB.Local 
              ? WorkspaceTypePB.LocalW 
              : WorkspaceTypePB.LocalW; // 桌面端默认创建本地工作空间
          
          Log.info('Creating workspace: name="$name", type=$workspaceType');
          
          // DEBUG BREAKPOINT 4: 即将发送创建工作空间事件
          Log.info('=== DEBUG BREAKPOINT 4 === 即将发送创建工作空间事件到 BLoC');
          
          workspaceBloc.add(
            UserWorkspaceEvent.createWorkspace(
              name: name,
              workspaceType: workspaceType,
            ),
          );
          
          // DEBUG BREAKPOINT 5: 创建工作空间事件已发送
          Log.info('=== DEBUG BREAKPOINT 5 === 创建工作空间事件已发送到 BLoC');
        },
      );
      
      Log.info('About to show dialog...');
      
      // 确保键盘状态清理以避免输入问题
      FocusScope.of(context).unfocus();
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider.value(
            value: workspaceBloc,
            child: dialog,
          ),
        );
      }
      Log.info('Dialog shown successfully');
    } catch (e, stackTrace) {
      Log.error('Failed to show create workspace dialog: $e');
      Log.error('Stack trace: $stackTrace');
      
      // 如果对话框显示失败，尝试使用Flutter原生的showDialog作为后备方案
      if (context.mounted) {
        try {
          Log.info('Trying fallback dialog approach...');
          await showDialog(
            context: context,
            builder: (dialogContext) => BlocProvider.value(
              value: context.read<UserWorkspaceBloc>(),
              child: CreateWorkspaceDialog(
              onConfirm: (name) {
                if (name.trim().isEmpty) {
                  Log.warn('Workspace name is empty, cannot create workspace');
                  return;
                }
                
                final workspaceBloc = context.read<UserWorkspaceBloc>();
                final userProfile = workspaceBloc.state.userProfile;
                final workspaceType = userProfile.userAuthType == AuthTypePB.Local 
                    ? WorkspaceTypePB.LocalW 
                    : WorkspaceTypePB.LocalW;
                
                Log.info('Creating workspace via fallback: name="$name", type=$workspaceType');
                
                workspaceBloc.add(
                  UserWorkspaceEvent.createWorkspace(
                    name: name,
                    workspaceType: workspaceType,
                  ),
                );
              },
            ),
            ),
          );
          Log.info('Fallback dialog worked');
        } catch (fallbackError) {
          Log.error('Fallback dialog also failed: $fallbackError');
        }
      }
    }
  }
}

class _ImportNotionButton extends StatelessWidget {
  const _ImportNotionButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FlowyButton(
        key: importNotionButtonKey,
        onTap: () {
          _showImportNotinoDialog(context);
        },
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        text: Row(
          children: [
            _buildLeftIcon(context),
            const HSpace(8.0),
            FlowyText.regular(
              LocaleKeys.workspace_importFromNotion.tr(),
            ),
          ],
        ),
        rightIcon: FlowyTooltip(
          message: LocaleKeys.workspace_learnMore.tr(),
          preferBelow: true,
          child: FlowyIconButton(
            icon: const FlowySvg(
              FlowySvgs.information_s,
            ),
            onPressed: () {
              afLaunchUrlString(
                'https://docs.appflowy.io/docs/guides/import-from-notion',
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLeftIcon(BuildContext context) {
    return Container(
      width: 36.0,
      height: 36.0,
      padding: const EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x01717171).withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: const FlowySvg(FlowySvgs.add_workspace_s),
    );
  }

  Future<void> _showImportNotinoDialog(BuildContext context) async {
    final result = await getIt<FilePickerService>().pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.first.path;
    if (path == null) {
      return;
    }

    if (context.mounted) {
      PopoverContainer.of(context).closeAll();
      await showDialog(
        context: context,
        builder: (context) => NavigatorCustomDialog(
          hideCancelButton: true,
          confirm: () {},
          child: NotionImporter(
            filePath: path,
          ),
        ),
      );
    } else {
      Log.error('context is not mounted when showing import notion dialog');
    }
  }
}

@visibleForTesting
class WorkspaceMoreButton extends StatelessWidget {
  const WorkspaceMoreButton({
    super.key,
    required this.popoverMutex,
  });

  final PopoverMutex popoverMutex;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 6),
      mutex: popoverMutex,
      asBarrier: true,
      popupBuilder: (_) => FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 7.0),
        leftIcon: const FlowySvg(FlowySvgs.workspace_logout_s),
        iconPadding: 10.0,
        text: FlowyText.regular(LocaleKeys.button_logout.tr()),
        onTap: () async {
          await getIt<AuthService>().signOut();
          await runAppFlowy();
        },
      ),
      child: SizedBox.square(
        dimension: 24.0,
        child: FlowyButton(
          useIntrinsicWidth: true,
          margin: EdgeInsets.zero,
          text: const FlowySvg(
            FlowySvgs.workspace_three_dots_s,
            size: Size.square(16.0),
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
