import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'import_page_widgets.dart';
import 'package:appflowy/plugins/import_page/import_service.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/settings/share/import_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'dart:typed_data';
import 'package:html2md/html2md.dart' as html2md;
import 'package:archive/archive.dart';
import 'enhanced_pdf_import_dialog.dart';
import 'professional_html_parser.dart';
import 'html_import_dialog.dart';

class ImportPageScreen extends StatefulWidget {
  const ImportPageScreen({super.key});

  @override
  State<ImportPageScreen> createState() => _ImportPageScreenState();
}

class _ImportPageScreenState extends State<ImportPageScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(45.0, 68.0, 45.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),
            
            // Separator line
            Container(
              height: 1,
              width: double.infinity,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: 17),
            
            // Description
            _buildDescription(),
            const SizedBox(height: 30),
            
            // File-based import section
            _buildFileImportSection(),
            const SizedBox(height: 30),
            
            // Third-party import section  
            _buildThirdPartyImportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        FlowyText.semibold(
          "导入或者迁移",
          fontSize: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Row(
      children: [
        Expanded(
          child: FlowyText(
            "从其他应用和文件导入数据到 小马笔记",
            fontSize: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        // const SizedBox(width: 10),
        // GestureDetector(
        //   onTap: () {
        //     // TODO: Show details
        //   },
        //   child: FlowyText(
        //     "了解详情",
        //     fontSize: 20,
        //     color: const Color(0xFFF89575), // Orange color from design
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildFileImportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText(
          "基于文件导入",
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 20),
        
        // First row: CSV, PDF, Markdown
        Row(
          children: [
            Expanded(
              child: ImportFileCard(
                icon: Icons.table_chart,
                title: "CSV",
                onTap: () => _handleFileImport('csv'),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: ImportFileCard(
                icon: Icons.picture_as_pdf,
                title: "PDF",
                onTap: () => _handleFileImport('pdf'),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: ImportFileCard(
                icon: Icons.text_snippet,
                title: "文本与 Markdown",
                onTap: () => _handleFileImport('markdown'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        // Second row: HTML, Word
        Row(
          children: [
            Expanded(
              child: ImportFileCard(
                icon: Icons.code,
                title: "HTML", 
                onTap: () => _handleFileImport('html'),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: ImportFileCard(
                icon: Icons.description,
                title: "Word",
                onTap: () => _handleFileImport('word'),
              ),
            ),
            const SizedBox(width: 30),
            const Expanded(child: SizedBox()), // Empty space for alignment
          ],
        ),
      ],
    );
  }

  Widget _buildThirdPartyImportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText(
          "第三方导入",
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: ImportServiceCard(
                iconPath: 'assets/images/notion_icon.png', // You'll need to add this asset
                title: "Notion",
                subtitle: "你的笔记和笔记本",
                onTap: () => _handleServiceImport('notion'),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: ImportServiceCard(
                iconPath: 'assets/images/evernote_icon.png', // You'll need to add this asset
                title: "Evernote",
                subtitle: "引入你的笔记和笔记本",
                onTap: () => _handleServiceImport('evernote'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleFileImport(String type) async {
    try {
      if (type == 'csv') {
        await _handleCsvImport();
      } else if (type == 'markdown') {
        await _handleMarkdownImport();
      } else if (type == 'pdf') {
        await _handlePdfImport();
      } else if (type == 'html') {
        await _handleHtmlImport();
      } else if (type == 'word') {
        await _handleWordImport();
      } else {
        final result = await ImportService.pickAndImportFile(type);
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功导入 ${result.fileName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCsvImport() async {
    try {
      // 获取当前工作空间
      final workspaceResult = await FolderEventReadCurrentWorkspace().send();
      final workspace = workspaceResult.fold(
        (workspace) => workspace,
        (error) => throw Exception('获取当前工作空间失败: $error'),
      );

      // 直接在工作空间根目录下检查或创建"外部导入"项目
      Log.info('在工作空间根目录下检查或创建"外部导入"项目');
      final externalImportView = await _getOrCreateExternalImportView(workspace.id);
      
      // 使用现有的导入面板逻辑导入CSV文件
      final result = await ImportService.pickAndImportFile('csv');
      if (result != null) {
        // 创建导入项目
        final importValues = <ImportItemPayloadPB>[
          ImportItemPayloadPB.create()
            ..name = p.basenameWithoutExtension(result.fileName)
            ..data = utf8.encode(result.content)
            ..viewLayout = ViewLayoutPB.Grid
            ..importType = ImportTypePB.CSV,
        ];

        // 导入到"外部导入"子项目下
        final importResult = await ImportBackendService.importPages(
          externalImportView.id,
          importValues,
        );

        importResult.fold(
          (views) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('成功将 ${result.fileName} 导入到外部导入项目'),
                  backgroundColor: Colors.green,
                ),
              );

              // 如果有导入的视图，打开第一个
              if (views.items.isNotEmpty) {
                context.read<TabsBloc>().openPlugin(views.items.first);
              }
            }
          },
          (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('导入失败: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMarkdownImport() async {
    try {
      // 获取当前工作空间
      final workspaceResult = await FolderEventReadCurrentWorkspace().send();
      final workspace = workspaceResult.fold(
        (workspace) => workspace,
        (error) => throw Exception('获取当前工作空间失败: $error'),
      );

      // 直接在工作空间根目录下检查或创建"外部导入"项目
      Log.info('在工作空间根目录下检查或创建"外部导入"项目');
      final externalImportView = await _getOrCreateExternalImportView(workspace.id);
      
      // 选择并读取文本/Markdown文件
      final result = await getIt<FilePickerService>().pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final importValues = <ImportItemPayloadPB>[];
        
        for (final file in result.files) {
          final path = file.path;
          if (path == null) continue;
          
          final fileName = file.name;
          final name = p.basenameWithoutExtension(fileName);
          
          // 读取文件内容
          final data = await File(path).readAsString();
          
          // 将Markdown/文本转换为Document格式
          final document = customMarkdownToDocument(data);
          final bytes = DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
          
          if (bytes != null) {
            importValues.add(
              ImportItemPayloadPB.create()
                ..name = name
                ..data = bytes
                ..viewLayout = ViewLayoutPB.Document
                ..importType = ImportTypePB.Markdown,
            );
          }
        }

        if (importValues.isNotEmpty) {
          // 导入到"外部导入"子项目下
          final importResult = await ImportBackendService.importPages(
            externalImportView.id,
            importValues,
          );

          importResult.fold(
            (views) {
              if (mounted) {
                final fileCount = importValues.length;
                final fileNames = result.files.map((f) => f.name).join(', ');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('成功导入 $fileCount 个文件到外部导入项目：$fileNames'),
                    backgroundColor: Colors.green,
                  ),
                );

                // 如果有导入的视图，打开第一个
                if (views.items.isNotEmpty) {
                  context.read<TabsBloc>().openPlugin(views.items.first);
                }
              }
            },
            (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('导入失败: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文本与Markdown导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<ViewPB> _getOrCreateExternalImportView(String workspaceId) async {
    const externalImportName = '外部导入';
    
    // 获取工作空间根目录下的所有公共视图
    final workspaceService = WorkspaceService(
      workspaceId: workspaceId,
      userId: fixnum.Int64(1),
    );
    
    final publicViewsResult = await workspaceService.getPublicViews();
    final publicViews = publicViewsResult.fold(
      (views) => views,
      (error) => throw Exception('获取工作空间视图失败: $error'),
    );
    
    // 检查是否已在工作空间根目录下存在"外部导入"项目
    Log.info('检查工作空间根目录下是否已存在"外部导入"，当前视图: ${publicViews.map((v) => v.name).toList()}');
    final existingView = publicViews.firstWhere(
      (view) => view.name == externalImportName,
      orElse: () => ViewPB(),
    );

    if (existingView.id.isNotEmpty) {
      Log.info('找到已存在的"外部导入"视图，ID: ${existingView.id}');
      return existingView;
    }

    // 在工作空间根目录下创建"外部导入"项目
    Log.info('在工作空间根目录下创建新的"外部导入"项目');
    final result = await ViewBackendService.createView(
      parentViewId: workspaceId,
      name: externalImportName,
      layoutType: ViewLayoutPB.Document,
    );

    return result.fold(
      (view) => view,
      (error) => throw Exception('创建外部导入项目失败: $error'),
    );
  }

  Future<void> _handlePdfImport() async {
    try {
      // 获取当前工作空间
      final workspaceResult = await FolderEventReadCurrentWorkspace().send();
      final workspace = workspaceResult.fold(
        (workspace) => workspace,
        (error) => throw Exception('获取当前工作空间失败: $error'),
      );

      // 直接在工作空间根目录下检查或创建"外部导入"项目
      Log.info('在工作空间根目录下检查或创建"外部导入"项目');
      final externalImportView = await _getOrCreateExternalImportView(workspace.id);

      // 显示增强的PDF导入对话框
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => EnhancedPdfImportDialog(
            parentViewId: externalImportView.id,
            onImportSuccess: () {
              // 刷新页面或显示成功提示
              if (mounted) {
                setState(() {
                  // 触发页面刷新
                });
              }
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _handleServiceImport(String service) async {
    try {
      await ImportService.importFromService(service);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('正在从 $service 导入数据...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  
  Future<void> _handleHtmlImport() async {
    try {
      // 先显示导入选项对话框
      final selectedMode = await showDialog<HtmlImportMode>(
        context: context,
        builder: (context) => const HtmlImportDialog(),
      );

      // 用户取消了对话框
      if (selectedMode == null) return;

      // 获取当前工作空间
      final workspaceResult = await FolderEventReadCurrentWorkspace().send();
      final workspace = workspaceResult.fold(
        (workspace) => workspace,
        (error) => throw Exception('获取当前工作空间失败: $error'),
      );

      // 直接在工作空间根目录下检查或创建"外部导入"项目
      Log.info('在工作空间根目录下检查或创建"外部导入"项目');
      final externalImportView = await _getOrCreateExternalImportView(workspace.id);

      // 选择HTML文件
      final result = await getIt<FilePickerService>().pickFiles(
        type: FileType.custom,
        allowedExtensions: ['html', 'htm'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final importValues = <ImportItemPayloadPB>[];
        
        for (final file in result.files) {
          final path = file.path;
          if (path == null) continue;
          
          final fileName = file.name;
          final name = p.basenameWithoutExtension(fileName);
          
          // 读取HTML文件内容
          Log.info('📄 开始HTML导入处理: $name (模式: ${selectedMode.name})');
          final htmlContent = await File(path).readAsString();
          
          // 根据选择的模式处理HTML
          String markdownContent;
          switch (selectedMode) {
            case HtmlImportMode.smartParse:
              markdownContent = ProfessionalHtmlParser.convertHtmlToMarkdown(htmlContent, name);
              Log.info('✅ 智能HTML解析完成，内容长度: ${markdownContent.length}');
              break;
              
            case HtmlImportMode.showSource:
              markdownContent = ProfessionalHtmlParser.createHtmlViewerContent(name, htmlContent);
              Log.info('✅ HTML源代码显示内容创建完成，内容长度: ${markdownContent.length}');
              break;
              
            case HtmlImportMode.legacyParse:
              try {
                markdownContent = html2md.convert(htmlContent);
                Log.info('✅ 传统HTML转Markdown成功，内容长度: ${markdownContent.length}');
              } catch (e) {
                Log.error('❌ 传统HTML转Markdown失败: $e');
                // 回退方案：直接清理HTML标签
                markdownContent = _cleanHtmlToText(htmlContent, name);
              }
              break;
          }
          
          // 优化Markdown内容（除了源代码显示模式）
          if (selectedMode != HtmlImportMode.showSource) {
            markdownContent = _optimizeMarkdownContent(markdownContent, name);
          }
          
          Log.info('📋 最终Markdown内容 (前500字符): ${markdownContent.substring(0, markdownContent.length > 500 ? 500 : markdownContent.length)}...');
          
          // 将Markdown转换为Document格式
          final document = customMarkdownToDocument(markdownContent);
          Log.info('📄 Document转换完成，节点数量: ${document.root.children.length}');
          
          final documentBytes = DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
          
          if (documentBytes != null) {
            Log.info('✅ 创建导入项目: $name (HTML -> Markdown -> Document)');
            importValues.add(
              ImportItemPayloadPB.create()
                ..name = name
                ..data = documentBytes
                ..viewLayout = ViewLayoutPB.Document
                ..importType = ImportTypePB.Markdown,
            );
          } else {
            Log.error('❌ Document序列化失败！');
          }
        }

        if (importValues.isNotEmpty) {
          // 导入到"外部导入"子项目下
          final importResult = await ImportBackendService.importPages(
            externalImportView.id,
            importValues,
          );

          importResult.fold(
            (views) {
              if (mounted) {
                final fileCount = importValues.length;
                final fileNames = result.files.map((f) => f.name).join(', ');
                final modeDescription = _getImportModeDescription(selectedMode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('成功使用$modeDescription导入 $fileCount 个HTML文件到外部导入项目：$fileNames'),
                    backgroundColor: Colors.green,
                  ),
                );

                // 如果有导入的视图，打开第一个
                if (views.items.isNotEmpty) {
                  context.read<TabsBloc>().openPlugin(views.items.first);
                }
              }
            },
            (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('导入失败: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        }
      }
    } catch (e) {
      Log.error('❌ HTML导入失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTML导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getImportModeDescription(HtmlImportMode mode) {
    switch (mode) {
      case HtmlImportMode.smartParse:
        return '智能解析';
      case HtmlImportMode.showSource:
        return 'HTML源代码显示';
      case HtmlImportMode.legacyParse:
        return '传统解析';
    }
  }

  /// 清理HTML标签并转换为纯文本（回退方案）
  String _cleanHtmlToText(String htmlContent, String fileName) {
    Log.info('⚠️ 使用回退方案清理HTML内容');
    
    // 移除HTML标签
    String cleanedContent = htmlContent
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '') // 移除脚本
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '') // 移除样式
        .replaceAll(RegExp(r'<[^>]*>'), '') // 移除所有HTML标签
        .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), '') // 移除HTML实体
        .replaceAll(RegExp(r'\s+'), ' ') // 规范化空格
        .trim();
    
    // 如果清理后内容为空或太短，使用默认内容
    if (cleanedContent.isEmpty || cleanedContent.length < 10) {
      cleanedContent = '# $fileName\n\n导入的HTML内容需要手动处理。\n\n原始内容可能包含复杂格式或JavaScript。';
    } else {
      cleanedContent = '# $fileName\n\n$cleanedContent';
    }
    
    return cleanedContent;
  }

  /// 优化Markdown内容
  String _optimizeMarkdownContent(String markdown, String fileName) {
    // 添加标题如果没有的话
    if (!markdown.trimLeft().startsWith('#')) {
      markdown = '# $fileName\n\n$markdown';
    }
    
    // 清理多余的空行
    markdown = markdown.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // 确保内容不为空
    if (markdown.trim().isEmpty) {
      markdown = '# $fileName\n\n导入的HTML文件内容为空。';
    }
    
    return markdown.trim();
  }


  Future<void> _handleWordImport() async {
    try {
      // 获取当前工作空间
      final workspaceResult = await FolderEventReadCurrentWorkspace().send();
      final workspace = workspaceResult.fold(
        (workspace) => workspace,
        (error) => throw Exception('获取当前工作空间失败: $error'),
      );

      // 直接在工作空间根目录下检查或创建"外部导入"项目
      Log.info('在工作空间根目录下检查或创建"外部导入"项目');
      final externalImportView = await _getOrCreateExternalImportView(workspace.id);

      // 选择Word文件
      final result = await getIt<FilePickerService>().pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'doc'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final importValues = <ImportItemPayloadPB>[];
        
        for (final file in result.files) {
          final path = file.path;
          if (path == null) continue;
          
          final fileName = file.name;
          final name = p.basenameWithoutExtension(fileName);
          
          // 读取Word文件内容
          Log.info('📄 开始Word导入处理: $name');
          
          String markdownContent;
          try {
            final wordFile = File(path);
            final bytes = await wordFile.readAsBytes();
            
            // 检查文件扩展名
            final extension = p.extension(fileName).toLowerCase();
            
            if (extension == '.docx') {
              // 处理.docx文件
              markdownContent = await _extractTextFromDocx(bytes, name);
              Log.info('✅ DOCX解析成功，内容长度: ${markdownContent.length}');
            } else if (extension == '.doc') {
              // .doc文件暂时不支持，提供友好提示
              markdownContent = _createDocNotSupportedContent(name);
              Log.info('⚠️ DOC文件暂不支持，使用默认内容');
            } else {
              throw Exception('不支持的文件格式: $extension');
            }
          } catch (e) {
            Log.error('❌ Word文件解析失败: $e');
            // 回退方案：创建包含错误信息的文档
            markdownContent = _createErrorContent(name, e.toString());
          }
          
          Log.info('📋 最终Markdown内容 (前500字符): ${markdownContent.substring(0, markdownContent.length > 500 ? 500 : markdownContent.length)}...');
          
          // 将Markdown转换为Document格式
          final document = customMarkdownToDocument(markdownContent);
          Log.info('📄 Document转换完成，节点数量: ${document.root.children.length}');
          
          final documentBytes = DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
          
          if (documentBytes != null) {
            Log.info('✅ 创建导入项目: $name (Word -> Markdown -> Document)');
            importValues.add(
              ImportItemPayloadPB.create()
                ..name = name
                ..data = documentBytes
                ..viewLayout = ViewLayoutPB.Document
                ..importType = ImportTypePB.Markdown,
            );
          } else {
            Log.error('❌ Document序列化失败！');
          }
        }

        if (importValues.isNotEmpty) {
          // 导入到"外部导入"子项目下
          final importResult = await ImportBackendService.importPages(
            externalImportView.id,
            importValues,
          );

          importResult.fold(
            (views) {
              if (mounted) {
                final fileCount = importValues.length;
                final fileNames = result.files.map((f) => f.name).join(', ');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('成功导入 $fileCount 个Word文件到外部导入项目：$fileNames'),
                    backgroundColor: Colors.green,
                  ),
                );

                // 如果有导入的视图，打开第一个
                if (views.items.isNotEmpty) {
                  context.read<TabsBloc>().openPlugin(views.items.first);
                }
              }
            },
            (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('导入失败: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        }
      }
    } catch (e) {
      Log.error('❌ Word导入失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Word导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 从DOCX文件提取文本并转换为Markdown
  Future<String> _extractTextFromDocx(Uint8List bytes, String fileName) async {
    try {
      // 使用archive库解析DOCX文件（DOCX是ZIP格式）
      final text = await _parseDocxContent(bytes);
      
      if (text.trim().isEmpty) {
        return _createEmptyDocumentContent(fileName);
      }
      
      // 将纯文本转换为Markdown格式
      return _convertTextToMarkdown(text, fileName);
    } catch (e) {
      Log.error('DOCX解析失败: $e');
      throw Exception('无法解析DOCX文件: $e');
    }
  }

  /// 解析DOCX文件内容（DOCX是ZIP格式，主要内容在word/document.xml）
  Future<String> _parseDocxContent(Uint8List bytes) async {
    try {
      // 解压DOCX文件（DOCX实际上是一个ZIP文件）
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // 查找word/document.xml文件，这里包含主要的文档内容
      ArchiveFile? documentXml;
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          documentXml = file;
          break;
        }
      }
      
      if (documentXml == null) {
        throw Exception('无法找到document.xml文件');
      }
      
      // 读取XML内容，使用正确的UTF-8解码
      final xmlContent = utf8.decode(documentXml.content as List<int>, allowMalformed: true);
      
      // 从XML中提取文本内容
      return _extractTextFromDocumentXml(xmlContent);
    } catch (e) {
      Log.error('DOCX文件解压失败: $e');
      throw Exception('DOCX文件可能损坏或格式不正确: $e');
    }
  }

  /// 从document.xml中提取纯文本
  String _extractTextFromDocumentXml(String xmlContent) {
    try {
      // 改进的XML文本提取：处理更多的文本标签和编码问题
      final textBuffer = StringBuffer();
      
      // 1. 提取<w:t>标签中的内容（主要文本内容）
      final RegExp textPattern = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
      final matches = textPattern.allMatches(xmlContent);
      
      for (final match in matches) {
        final text = match.group(1);
        if (text != null && text.trim().isNotEmpty) {
          // 解码XML实体
          final decodedText = _decodeXmlEntities(text);
          textBuffer.write(decodedText);
          textBuffer.write(' '); // 在文本片段之间添加空格
        }
      }
      
      // 2. 如果没有找到<w:t>标签，尝试提取其他可能的文本标签
      if (textBuffer.isEmpty) {
        // 尝试提取<w:instrText>标签（域代码文本）
        final RegExp instrTextPattern = RegExp(r'<w:instrText[^>]*>([^<]*)</w:instrText>');
        final instrMatches = instrTextPattern.allMatches(xmlContent);
        
        for (final match in instrMatches) {
          final text = match.group(1);
          if (text != null && text.trim().isNotEmpty) {
            final decodedText = _decodeXmlEntities(text);
            textBuffer.write(decodedText);
            textBuffer.write(' ');
          }
        }
      }
      
      // 改进的段落处理：基于XML结构重建文本
      String result = _reconstructTextWithStructure(xmlContent, textBuffer.toString());
      
      // 如果结构化重建失败，使用简单的文本处理
      if (result.trim().isEmpty) {
        result = textBuffer.toString();
        
        // 规范化空格和换行
        result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
        
        // 简单的段落分割：基于句号和长度
        if (result.length > 100) {
          final sentences = result.split(RegExp(r'[。！？]'));
          final paragraphs = <String>[];
          String currentParagraph = '';
          
          for (final sentence in sentences) {
            final trimmed = sentence.trim();
            if (trimmed.isEmpty) continue;
            
            if (currentParagraph.length + trimmed.length > 200) {
              if (currentParagraph.isNotEmpty) {
                paragraphs.add(currentParagraph.trim());
                currentParagraph = trimmed;
              }
            } else {
              currentParagraph += trimmed;
              if (sentence != sentences.last) {
                currentParagraph += sentence.endsWith('。') ? '。' : 
                                   sentence.endsWith('！') ? '！' : 
                                   sentence.endsWith('？') ? '？' : '。';
              }
            }
          }
          
          if (currentParagraph.trim().isNotEmpty) {
            paragraphs.add(currentParagraph.trim());
          }
          
          result = paragraphs.join('\n\n');
        }
      }
      
      return result.trim();
    } catch (e) {
      Log.error('XML文本提取失败: $e');
      throw Exception('无法从DOCX XML中提取文本: $e');
    }
  }

  /// 将纯文本转换为结构化的Markdown
  String _convertTextToMarkdown(String text, String fileName) {
    final lines = text.split('\n');
    final markdownLines = <String>[];
    
    // 添加文档标题
    markdownLines.add('# $fileName');
    markdownLines.add('');
    
    // 处理每一行，识别可能的结构
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        // 保持空行，但不要连续太多空行
        if (markdownLines.isNotEmpty && markdownLines.last.isNotEmpty) {
          markdownLines.add('');
        }
        continue;
      }
      
      // 识别可能的标题（短行、全大写、或者数字开头）
      if (_isLikelyTitle(line)) {
        // 确保标题前有空行
        if (markdownLines.isNotEmpty && markdownLines.last.isNotEmpty) {
          markdownLines.add('');
        }
        markdownLines.add('## $line');
        markdownLines.add('');
      } else if (_isLikelyListItem(line)) {
        // 识别列表项
        final listItem = _formatAsListItem(line);
        markdownLines.add(listItem);
      } else {
        // 普通段落
        markdownLines.add(line);
      }
    }
    
    // 清理多余的空行
    final cleanedLines = <String>[];
    String? lastLine;
    
    for (final line in markdownLines) {
      if (line.isEmpty && lastLine?.isEmpty == true) {
        continue; // 跳过连续的空行
      }
      cleanedLines.add(line);
      lastLine = line;
    }
    
    return cleanedLines.join('\n').trim();
  }

  /// 判断是否可能是标题
  bool _isLikelyTitle(String line) {
    // 长度较短且不包含句号
    if (line.length <= 60 && !line.contains('。') && !line.contains('.')) {
      // 全大写
      if (line == line.toUpperCase()) return true;
      
      // 数字编号开头
      if (RegExp(r'^\d+[\.、\s]').hasMatch(line)) return true;
      
      // 常见标题词汇
      final titleKeywords = ['第', '章', '节', '部分', '摘要', '总结', '介绍', '概述'];
      for (final keyword in titleKeywords) {
        if (line.contains(keyword)) return true;
      }
    }
    
    return false;
  }

  /// 判断是否可能是列表项
  bool _isLikelyListItem(String line) {
    // 数字编号
    if (RegExp(r'^\d+[\.、）]\s*').hasMatch(line)) return true;
    
    // 字母编号
    if (RegExp(r'^[a-zA-Z][\.、）]\s*').hasMatch(line)) return true;
    
    // 括号编号
    if (RegExp(r'^\([a-zA-Z0-9]+\)\s*').hasMatch(line)) return true;
    
    // 中文编号
    if (RegExp(r'^[一二三四五六七八九十][、．]\s*').hasMatch(line)) return true;
    
    return false;
  }

  /// 格式化为列表项
  String _formatAsListItem(String line) {
    // 移除原有的编号并添加Markdown列表标记
    final cleaned = line.replaceFirst(RegExp(r'^[0-9a-zA-Z一二三四五六七八九十\(\)\.、）]+\s*'), '');
    return '- $cleaned';
  }

  /// 创建空文档内容
  String _createEmptyDocumentContent(String fileName) {
    return '''# $fileName

此Word文档似乎没有可提取的文本内容。

**可能的原因：**
- 文档主要包含图片或图表
- 文档是扫描版PDF转换而成
- 文档内容被加密或保护

**建议：**
- 请检查原始文档是否包含文本内容
- 如果文档包含重要信息，请考虑手动复制粘贴
''';
  }

  /// 创建DOC文件不支持的内容
  String _createDocNotSupportedContent(String fileName) {
    return '''# $fileName

**暂不支持.doc格式文件**

目前系统仅支持.docx格式的Word文档导入。

**解决方案：**
1. 使用Microsoft Word打开此文件
2. 选择"文件" → "另存为"
3. 将格式改为"Word文档(.docx)"
4. 重新导入转换后的文件

**为什么不支持.doc格式？**
.doc是较老的二进制格式，解析复杂且容易出错。
.docx是基于XML的现代格式，更容易处理且兼容性更好。

**导入时间：** ${DateTime.now().toString().split('.')[0]}
''';
  }

  /// 创建错误内容
  String _createErrorContent(String fileName, String error) {
    return '''# $fileName - 导入失败

**导入过程中发生错误**

**错误信息：** $error

**可能的解决方案：**
1. 确保文件没有损坏
2. 检查文件是否被密码保护
3. 尝试用Microsoft Word打开并重新保存
4. 确保文件格式正确（支持.docx格式）

**技术信息：**
- 文件名：$fileName
- 导入时间：${DateTime.now().toString().split('.')[0]}
- 错误类型：文档解析失败

如果问题持续，请联系技术支持。
''';
  }

  /// 基于XML结构重建文本，保持段落和格式
  String _reconstructTextWithStructure(String xmlContent, String extractedText) {
    try {
      final paragraphs = <String>[];
      
      // 找到所有段落<w:p>
      final RegExp paragraphPattern = RegExp(r'<w:p[^>]*>(.*?)</w:p>', dotAll: true);
      final paragraphMatches = paragraphPattern.allMatches(xmlContent);
      
      for (final paragraphMatch in paragraphMatches) {
        final paragraphXml = paragraphMatch.group(1) ?? '';
        
        // 从段落中提取文本
        final RegExp textPattern = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
        final textMatches = textPattern.allMatches(paragraphXml);
        
        final paragraphBuffer = StringBuffer();
        for (final textMatch in textMatches) {
          final text = textMatch.group(1);
          if (text != null && text.trim().isNotEmpty) {
            final decodedText = _decodeXmlEntities(text);
            paragraphBuffer.write(decodedText);
          }
        }
        
        final paragraphText = paragraphBuffer.toString().trim();
        if (paragraphText.isNotEmpty) {
          // 检查是否是表格行
          if (paragraphXml.contains('<w:tbl>') || paragraphXml.contains('<w:tc>')) {
            // 表格内容，添加特殊格式
            paragraphs.add('| $paragraphText |');
          } else if (_isLikelyListItem(paragraphText)) {
            // 列表项
            paragraphs.add(_formatAsListItem(paragraphText));
          } else {
            // 普通段落
            paragraphs.add(paragraphText);
          }
        }
      }
      
      // 如果没有找到段落，返回空字符串让调用者使用备用方法
      if (paragraphs.isEmpty) {
        return '';
      }
      
      return paragraphs.join('\n\n');
    } catch (e) {
      Log.error('结构化文本重建失败: $e');
      return ''; // 返回空字符串，让调用者使用备用方法
    }
  }

  /// 解码XML实体
  String _decodeXmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        // 处理数字字符引用
        .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
          final codePoint = int.tryParse(match.group(1)!);
          if (codePoint != null && codePoint > 0 && codePoint <= 0x10FFFF) {
            return String.fromCharCode(codePoint);
          }
          return match.group(0)!;
        })
        // 处理十六进制字符引用
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
          final codePoint = int.tryParse(match.group(1)!, radix: 16);
          if (codePoint != null && codePoint > 0 && codePoint <= 0x10FFFF) {
            return String.fromCharCode(codePoint);
          }
          return match.group(0)!;
        });
  }
  
}
