import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'presentation/file_library_page.dart';

class FileLibraryPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return FileLibraryPlugin();
  }

  @override
  String get menuName => "File Library";

  @override
  FlowySvgData get icon => FlowySvgs.icon_file_library_s;

  @override
  PluginType get pluginType => PluginType.fileLibrary;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Document;
}

class FileLibraryPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class FileLibraryPlugin extends Plugin {
  @override
  PluginWidgetBuilder get widgetBuilder => FileLibraryPluginWidgetBuilder();

  @override
  PluginId get id => "file_library";

  @override
  PluginType get pluginType => PluginType.fileLibrary;
}

class FileLibraryPluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  @override
  String? get viewName => "文件库";

  @override
  Widget get leftBarItem => const Text("文件库");

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) => leftBarItem;

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) =>
      const FileLibraryPage();

  @override
  List<NavigationItem> get navigationItems => [this];
} 