import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'import_page_widgets.dart';
import 'package:appflowy/plugins/import_page/import_service.dart';

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
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            // TODO: Show details
          },
          child: FlowyText(
            "了解详情",
            fontSize: 20,
            color: const Color(0xFFF89575), // Orange color from design
            fontWeight: FontWeight.w500,
          ),
        ),
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
      final result = await ImportService.pickAndImportFile(type);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导入 ${result.fileName}'),
            backgroundColor: Colors.green,
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
}
