import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/auth/douyin_auth_service.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 抖音二维码登录对话框
class DouyinQrLoginDialog extends StatefulWidget {
  const DouyinQrLoginDialog({super.key});

  @override
  State<DouyinQrLoginDialog> createState() => _DouyinQrLoginDialogState();
}

class _DouyinQrLoginDialogState extends State<DouyinQrLoginDialog> {
  late String _qrData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  void _generateQrCode() {
    final authService = DouyinAuthService.instance;
    _qrData = authService.generateAuthUrl();
  }

  Future<void> _openInBrowser() async {
    setState(() {
      _isLoading = true;
    });

    final result = await DouyinAuthService.instance.openAuthUrl();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (result.isSuccess) {
        // 成功打开浏览器后可以关闭对话框
        Navigator.of(context).pop();
      } else {
        // 显示错误信息
        showMessageToast(
          result.fold((success) => '', (error) => error.msg),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '抖音扫码登录',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 二维码
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // 说明文字
            Text(
              '请使用抖音扫描二维码登录',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '或点击下方按钮在浏览器中打开',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // 在浏览器中打开按钮
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FlowyButton(
                      text: FlowyText.medium('在浏览器中打开'),
                      onTap: _openInBrowser,
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.button_cancel.tr()),
        ),
        TextButton(
          onPressed: _generateQrCode,
          child: const Text('刷新二维码'),
        ),
      ],
    );
  }
}
