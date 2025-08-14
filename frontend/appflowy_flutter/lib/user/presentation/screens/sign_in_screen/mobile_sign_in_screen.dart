import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/anonymous_sign_in_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/logo/logo.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            // 移除这里的 runAppFlowy 调用，让外层的 SignInScreen 处理导航
            // successOrFail.onSuccess((userProfile) async {
            //   if (userProfile != null) {
            //     await runAppFlowy();
            //   }
            // });
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
            backgroundColor: Colors.white,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF8F6), // 与桌面端保持一致的浅色渐变背景
                    Colors.white,
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 
                                 MediaQuery.of(context).padding.top - 
                                 MediaQuery.of(context).padding.bottom - 80,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo部分 - 恢复小马原始图标
                        const AFLogo(
                          size: Size.square(80),
                        ),
                        const VSpace(30),

                        // 标题 - 减小字体大小
                        const Text(
                          "欢迎使用小马笔记",
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 24,
                            fontFamily: 'DingTalk-JinBuTi',
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const VSpace(40),

                        // 快速开始按钮
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: GestureDetector(
                            onTap: () {
                              context
                                  .read<SignInBloc>()
                                  .add(const SignInEvent.signInAsGuest());
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4F0),
                                border: Border.all(color: const Color(0xFFF89575)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: const Text(
                                "快速开始",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFF89575),
                                  fontSize: 20,
                                  fontFamily: 'PingFangSC-Medium',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const VSpace(20),

                        // 分割线
                        const _MobileOrDivider(),
                        const VSpace(20),

                        // 邮箱登录部分
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: isLocalAuthEnabled
                              ? const SignInAnonymousButtonV3()
                              : const ContinueWithEmailAndPassword(),
                        ),

                        // 第三方登录部分
                        if (isAuthEnabled) ...[
                          const VSpace(40),
                          const _MobileCustomOrDivider(text: "其他登录方式"),
                          const VSpace(40),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: const ThirdPartySignInButtons(),
                          ),
                        ],

                        const VSpace(60),

                        // 底部版本信息
                        Text(
                          '小马笔记 v1.0.0',
                          style: theme.textStyle.caption.standard(
                            color: theme.textColorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MobileOrDivider extends StatelessWidget {
  const _MobileOrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Text(
            "或",
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 18,
              fontFamily: 'PingFangSC-Regular',
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }
}

class _MobileCustomOrDivider extends StatelessWidget {
  const _MobileCustomOrDivider({required this.text});
  
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 18,
              fontFamily: 'PingFangSC-Regular',
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }
}
