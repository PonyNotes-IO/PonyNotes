import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class QQQRLoginScreen extends StatefulWidget {
  const QQQRLoginScreen({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  State<QQQRLoginScreen> createState() => _QQQRLoginScreenState();
}

class _QQQRLoginScreenState extends State<QQQRLoginScreen> {
  late Timer _qrTimer;
  late String _qrData;
  late DateTime _expireTime;
  bool _isExpired = false;
  bool _isScanned = false;

  // QQ登录配置 - 这些应该从配置中获取
  static const String appId = 'YOUR_QQ_APP_ID'; // 需要替换为实际的QQ AppID
  static const String redirectUri =
      'https://your-domain.com/qq-callback'; // 需要替换为实际的回调地址

  @override
  void initState() {
    super.initState();
    _generateQRCode();
    _startTimer();
  }

  @override
  void dispose() {
    _qrTimer.cancel();
    super.dispose();
  }

  void _generateQRCode() {
    // 生成QQ登录的二维码数据
    // 根据QQ互联文档，二维码包含以下信息
    final state = _generateRandomState();
    final qrUrl = 'https://graph.qq.com/oauth2.0/authorize?'
        'response_type=code&'
        'client_id=$appId&'
        'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
        'scope=get_user_info&'
        'state=$state';

    setState(() {
      _qrData = qrUrl;
      _expireTime =
          DateTime.now().add(const Duration(minutes: 10)); // QQ官方规定10分钟有效期
      _isExpired = false;
      _isScanned = false;
    });
  }

  String _generateRandomState() {
    // 生成随机state参数，用于防止CSRF攻击
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
          32, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  void _startTimer() {
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final now = DateTime.now();
        if (now.isAfter(_expireTime)) {
          setState(() {
            _isExpired = true;
          });
          timer.cancel();
        }
      }
    });
  }

  void _refreshQRCode() {
    _qrTimer.cancel();
    _generateQRCode();
    _startTimer();
  }

  String _getTimeRemaining() {
    if (_isExpired) return '00:00';

    final remaining = _expireTime.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('QQ登录'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QQ Logo
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF12B7F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),

              // 标题
              const Text(
                'QQ扫码登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // 描述
              Text(
                '请使用手机QQ扫描二维码登录',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // 二维码区域
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildQRCodeWidget(),
              ),

              const SizedBox(height: 16),

              // 状态和时间
              _buildStatusWidget(),

              const SizedBox(height: 24),

              // 刷新按钮
              if (_isExpired) ...[
                ElevatedButton(
                  onPressed: _refreshQRCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B7F5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('刷新二维码'),
                ),
                const SizedBox(height: 16),
              ],

              // 取消按钮
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  '取消登录',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeWidget() {
    if (_isExpired) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '二维码已过期',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return QrImageView(
      data: _qrData,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  Widget _buildStatusWidget() {
    if (_isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '二维码已过期',
          style: TextStyle(
            color: Colors.red[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (_isScanned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '请在手机上确认登录',
          style: TextStyle(
            color: Colors.orange[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '有效期：${_getTimeRemaining()}',
        style: TextStyle(
          color: Colors.blue[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
