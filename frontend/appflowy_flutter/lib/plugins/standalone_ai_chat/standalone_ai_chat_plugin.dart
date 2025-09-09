import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

import 'standalone_ai_chat_page.dart';

class StandaloneAiChatPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    String? initialText;
    AIModelPB? selectedModel;
    
    if (data is String) {
      initialText = data;
    } else if (data is Map<String, dynamic>) {
      initialText = data['initialText'] as String?;
      selectedModel = data['selectedModel'] as AIModelPB?;
    }
    
    return StandaloneAiChatPlugin(
      pluginType: pluginType,
      initialText: initialText,
      selectedModel: selectedModel,
    );
  }

  @override
  String get menuName => "StandaloneAiChatPB";

  @override
  FlowySvgData get icon => FlowySvgs.m_home_ai_chat_icon_m;

  @override
  PluginType get pluginType => PluginType.standaloneAiChat;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Document;
}

class StandaloneAiChatPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class StandaloneAiChatPlugin extends Plugin {
  StandaloneAiChatPlugin({
    required PluginType pluginType,
    this.initialText,
    this.selectedModel,
  }) : _pluginType = pluginType;

  final PluginType _pluginType;
  final String? initialText;
  final AIModelPB? selectedModel;

  @override
  PluginWidgetBuilder get widgetBuilder => StandaloneAiChatPluginDisplay(
    initialText: initialText,
    selectedModel: selectedModel,
  );

  @override
  PluginId get id => "StandaloneAiChatStack";

  @override
  PluginType get pluginType => _pluginType;
}

class StandaloneAiChatPluginDisplay extends PluginWidgetBuilder {
  StandaloneAiChatPluginDisplay({this.initialText, this.selectedModel});
  
  final String? initialText;
  final AIModelPB? selectedModel;

  @override
  String? get viewName => '问AI';

  @override
  Widget get leftBarItem => const FlowyText.medium('问AI');

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) => leftBarItem;

  @override
  Widget? get rightBarItem => null;

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    final userProfile = context.userProfile;

    if (userProfile == null) {
      return const Center(
        child: Text('用户信息未加载'),
      );
    }

    return StandaloneAiChatPage(
      key: const ValueKey('StandaloneAiChatPage'),
      userProfile: userProfile,
      initialText: initialText,
      selectedModel: selectedModel,
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}
