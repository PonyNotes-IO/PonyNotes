import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/launch_settings_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/anonymous_sign_in_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/user/presentation/widgets/flowy_logo_title.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:appflowy_ui/src/theme/definition/theme_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileSignInScreen extends StatelessWidget {
  const MobileSignInScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) async {
        final successOrFail = state.successOrFail;
        if (successOrFail != null) {
          if (successOrFail.isSuccess) {
            successOrFail.onSuccess((userProfile) async {
              // 匿名登录成功，启动应用
              if (userProfile != null) {
                await runAppFlowy();
              }
            });
          } else {
            // 显示错误Toast
            successOrFail.onFailure((error) {
              showToastNotification(
                message: error.msg,
                type: ToastificationType.error,
              );
            });
          }
        }
      },
      child: BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) {
          final theme = AppFlowyTheme.of(context);

          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.surfaceColorScheme.primary,
                    theme.surfaceColorScheme.primary.withOpacity(0.95),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 顶部区域 - Logo和标题
                    Expanded(
                      flex: 2,
                      child: _buildTopSection(context, theme),
                    ),

                    // 中间区域 - 登录表单
                    Expanded(
                      flex: 3,
                      child: _buildLoginSection(context, theme),
                    ),

                    // 底部区域 - 设置和匿名登录
                    Expanded(
                      flex: 1,
                      child: _buildBottomSection(context, theme),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, AppFlowyThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo和标题
          FlowyLogoTitle(
            title: LocaleKeys.welcomeText.tr(),
            logoSize: const Size.square(48),
          ),
          VSpace(theme.spacing.l),

          // 欢迎文字
          Text(
            LocaleKeys.welcomeTo.tr(),
            style: theme.textStyle.body.standard(
              color: theme.textColorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),

          VSpace(theme.spacing.l),

          // 快速开始按钮
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            child: AFOutlinedTextButton.normal(
              text: LocaleKeys.signIn_quickStart.tr(),
              size: AFButtonSize.l,
              onTap: () {
                // 直接调用匿名登录
                context
                    .read<SignInBloc>()
                    .add(const SignInEvent.signInAsGuest());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginSection(BuildContext context, AppFlowyThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 主要登录方式
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            child: isLocalAuthEnabled
                ? const SignInAnonymousButtonV3()
                : const ContinueWithEmailAndPassword(),
          ),

          VSpace(theme.spacing.xl),

          // 第三方登录
          if (isAuthEnabled) ...[
            _buildThirdPartySignInButtons(context),
            VSpace(theme.spacing.l),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, AppFlowyThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 设置和匿名登录按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSettingsButton(context),
              if (!isLocalAuthEnabled) const SignInAnonymousButtonV2(),
            ],
          ),

          VSpace(theme.spacing.m),

          // 版本信息或其他底部信息
          Text(
            '小马笔记 v1.0.0',
            style: theme.textStyle.caption.standard(
              color: theme.textColorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPartySignInButtons(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Column(
      children: [
        // 分割线
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: theme.textColorScheme.secondary.withOpacity(0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                LocaleKeys.signIn_or.tr(),
                style: theme.textStyle.body.standard(
                  color: theme.textColorScheme.secondary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: theme.textColorScheme.secondary.withOpacity(0.3),
              ),
            ),
          ],
        ),

        VSpace(theme.spacing.l),

        // 第三方登录按钮
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          child: ThirdPartySignInButtons(
            expanded: Platform.isAndroid,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.textColorScheme.secondary.withOpacity(0.2),
        ),
      ),
      child: AFGhostIconTextButton(
        text: LocaleKeys.signIn_settings.tr(),
        textColor: (context, isHovering, disabled) {
          return theme.textColorScheme.secondary;
        },
        size: AFButtonSize.s,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        onTap: () => context.push(MobileLaunchSettingsPage.routeName),
        iconBuilder: (context, isHovering, disabled) {
          return FlowySvg(
            FlowySvgs.settings_s,
            size: const Size.square(18),
            color: theme.textColorScheme.secondary,
          );
        },
      ),
    );
  }
}
