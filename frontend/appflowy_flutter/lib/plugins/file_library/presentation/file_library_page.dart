import 'package:flutter/material.dart';

class FileLibraryPage extends StatefulWidget {
  const FileLibraryPage({super.key});

  @override
  State<FileLibraryPage> createState() => _FileLibraryPageState();
}

class _FileLibraryPageState extends State<FileLibraryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件库'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '文件库',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '这里将显示您的文件',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 