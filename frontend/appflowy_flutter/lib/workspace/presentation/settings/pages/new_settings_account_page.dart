import 'package:flutter/material.dart';

class NewSettingsAccountPage extends StatelessWidget {
  const NewSettingsAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 724,
      height: 709,
      padding: const EdgeInsets.only(left: 30, top: 30),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            const Text(
              '我的账户',
              style: TextStyle(
                color: Color(0xFF636363),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.375, // 22/16
              ),
            ),
            
            const SizedBox(height: 14),
            
            // 账户类型选择
            Container(
              width: 665,
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAccountTypeCard(
                    '免费账户',
                    '¥0',
                    null,
                    true,
                  ),
                  _buildAccountTypeCard(
                    '标准账户',
                    '¥20.00',
                    '/月',
                  ),
                  _buildAccountTypeCard(
                    '高级账户',
                    '¥35.00',
                    '/月',
                  ),
                  _buildAccountTypeCard(
                    '专业账户',
                    '¥45.00',
                    '/月',
                  ),
                  _buildAccountTypeCard(
                    '超级会员',
                    '¥24.83',
                    '/月',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 获赠权益标题
            const Text(
              '获赠权益',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.43, // 20/14
              ),
            ),
            
            const SizedBox(height: 14),
            
            // 权益图标行
            Container(
              width: 596,
              height: 66,
              margin: const EdgeInsets.only(left: 38),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBenefitItem(
                    'https://lanhu-oss-proxy.lanhuapp.com/SketchPng8b04f8f7776100f13b6114f24c1292d0085413de961eddcef3e99e1eaf698b07',
                    '小马AI',
                  ),
                  _buildBenefitItem(
                    'https://lanhu-oss-proxy.lanhuapp.com/SketchPng8913581a078fd92f3b46df7bd0c9f3ff8a17665a1aa3527a7a76634476868b17',
                    '小马日历',
                  ),
                  _buildBenefitItem(
                    'https://lanhu-oss-proxy.lanhuapp.com/SketchPng5d5c28aaae1b8664fe025914f8b0e9b0a0205e04ed6178a29f43166dcfd4ba05',
                    '小马收藏夹',
                  ),
                  _buildBenefitItem(
                    'https://lanhu-oss-proxy.lanhuapp.com/SketchPng983ccdc2a2eafa5bc59fdbd6992a589dd50d7279df01d3bac2ef16eaef9d854e',
                    '云端同步',
                  ),
                  _buildBenefitItem(
                    'https://lanhu-oss-proxy.lanhuapp.com/SketchPng11039c5cc1c5fe355a6153056f3a2cf4d52dd5b7cf94c743fec023c6b9025142',
                    '100T空间',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 文档光标颜色
            _buildSettingItem(
              '文档光标颜色',
              '购买',
              hasArrow: true,
            ),
            
            const SizedBox(height: 15),
            
            // AI使用次数
            _buildSettingItem(
              'AI使用次数',
              '今日剩余20次升级',
              hasArrow: true,
            ),
            
            const SizedBox(height: 15),
            
            // 个人资料
            Container(
              width: 664,
              height: 51,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '个人资料',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.38, // 18/13
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        '绑定手机',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.38, // 18/13
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Image.network(
                        'https://lanhu-oss-proxy.lanhuapp.com/SketchPngf90d1a100e05e5b8aaf3287edbc0c0aac6635151e651035c1e98b1047ff6317b',
                        width: 6,
                        height: 12,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '修改',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.38, // 18/13
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            // 邮箱
            Container(
              width: 662,
              height: 18,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '邮箱',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.38, // 18/13
                    ),
                  ),
                  Text(
                    '修改',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.38, // 18/13
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 163),
            
            // 退出登录按钮
            Center(
              child: Container(
                width: 503,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFF89575),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '退出登录',
                    style: TextStyle(
                      color: Color(0xFFF89575),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.375, // 22/16
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard(String title, String price, [String? period, bool isSelected = false]) {
    return Container(
      width: 117,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? const Color(0xFFF89575) : const Color(0xFFE9E9E9),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          if (isSelected)
            Positioned(
              left: 1,
              top: 13,
              child: Image.network(
                'https://lanhu-oss-proxy.lanhuapp.com/SketchPng8bd9aa99193216e7160a1e06357090564e26cff5a9e5dabd217e96ec88f741f3',
                width: 58,
                height: 58,
                fit: BoxFit.contain,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 31, top: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.43, // 20/14
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.375, // 22/16
                      ),
                    ),
                    if (period != null)
                      Text(
                        period,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.83, // 22/12
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              right: 10,
              bottom: 0,
              child: Container(
                width: 20,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFF89575),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Image.network(
                    'https://lanhu-oss-proxy.lanhuapp.com/SketchPngab0d26a13715c8a97f969be22f84b3bd8639d34e54ec1fc0a377a78c354a4950',
                    width: 14,
                    height: 14,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String iconUrl, String title) {
    return Column(
      children: [
        Image.network(
          iconUrl,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.38, // 18/13
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String title, String action, {bool hasArrow = false}) {
    return Container(
      width: 664,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.38, // 18/13
            ),
          ),
          Row(
            children: [
              Text(
                action,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.38, // 18/13
                ),
              ),
              if (hasArrow) ...[
                const SizedBox(width: 8),
                Image.network(
                  'https://lanhu-oss-proxy.lanhuapp.com/SketchPngf90d1a100e05e5b8aaf3287edbc0c0aac6635151e651035c1e98b1047ff6317b',
                  width: 6,
                  height: 12,
                  fit: BoxFit.contain,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
