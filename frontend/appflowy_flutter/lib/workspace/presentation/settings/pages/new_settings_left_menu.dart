import 'package:flutter/material.dart';
import 'package:appflowy/workspace/presentation/settings/pages/new_settings_page.dart';

class NewSettingsLeftMenu extends StatelessWidget {
  const NewSettingsLeftMenu({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
  });

  final NewSettingsPageType selectedPage;
  final Function(NewSettingsPageType) onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 709,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
        border: Border(
          right: BorderSide(
            color: Color(0x24000000),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Padding(
            padding: EdgeInsets.only(left: 25, top: 30),
            child: Text(
              '账号',
              style: TextStyle(
                color: Color(0xFF636363),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.375, // 22/16
              ),
            ),
          ),
          
          // 用户信息卡片
          Padding(
            padding: const EdgeInsets.only(left: 25, top: 16),
            child: Container(
              width: 270,
              height: 38,
              child: Row(
                children: [
                  // 头像
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF979797),
                        width: 0.6,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage('https://lanhu-dds-backend.oss-cn-beijing.aliyuncs.com/merge_image/imgs/ac59033c6cd94451b8b1db2983bc1bc4_mergeImage.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // 用户信息
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '小马笔记的笔记',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.43, // 20/14
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          '免费账户',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.42, // 17/12
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 升级按钮
                  Container(
                    width: 52,
                    height: 28,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF89575),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        '升级',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.42, // 17/12
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 权益图标
          Container(
            width: 264,
            height: 21,
            margin: const EdgeInsets.only(left: 28, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBenefitIcon('https://lanhu-oss-proxy.lanhuapp.com/SketchPng623a156161cd1ca930174a1900b90e715385bf5ed59ba7702d19c6a811344e77'),
                _buildBenefitIcon('https://lanhu-oss-proxy.lanhuapp.com/SketchPnge0848ce657ffc0f876a5886d3f061222fff2f5805c176af219bb473b8cc74251'),
                _buildBenefitIcon('https://lanhu-oss-proxy.lanhuapp.com/SketchPngc48701cb65d3a42cba3c0eb013ea07fcd010aade1a1121d8817311a93fe3ee6b'),
                _buildBenefitIcon('https://lanhu-oss-proxy.lanhuapp.com/SketchPng84111b0474f85af3f3aa0562fb136e58a6d80bd893e27619cc7c990912f0376b'),
                _buildBenefitIcon('https://lanhu-oss-proxy.lanhuapp.com/SketchPng7b450a127524e639632a23bbb7e64ec9072869d75ca0637d811888fa2cd7648d'),
              ],
            ),
          ),
          
          // 权益文字
          Container(
            width: 270,
            height: 17,
            margin: const EdgeInsets.only(left: 25, top: 6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '权益一',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.42,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '权益二',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.42,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '权益三',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.42,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '权益四',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.42,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '权益五',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.42,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 我的账户信息
          Container(
            width: 270,
            height: 20,
            margin: const EdgeInsets.only(left: 25, top: 21),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '我的账户',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.43, // 20/14
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    '剩余流量60M/100M',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.42, // 17/12
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 13),
          
          // 菜单项列表
          Expanded(
            child: Column(
              children: [
                _buildMenuItem(
                  '通用设置',
                  NewSettingsPageType.general,
                  isSelected: selectedPage == NewSettingsPageType.general,
                  isFirst: true,
                ),
                _buildMenuItem(
                  '空间管理',
                  NewSettingsPageType.spaceManagement,
                  isSelected: selectedPage == NewSettingsPageType.spaceManagement,
                ),
                _buildMenuItem(
                  '人员管理',
                  NewSettingsPageType.memberManagement,
                  isSelected: selectedPage == NewSettingsPageType.memberManagement,
                ),
                _buildMenuItem(
                  '共享发布',
                  NewSettingsPageType.sharePublish,
                  isSelected: selectedPage == NewSettingsPageType.sharePublish,
                ),
                _buildMenuItem(
                  '通知设置',
                  NewSettingsPageType.notifications,
                  isSelected: selectedPage == NewSettingsPageType.notifications,
                ),
                _buildMenuItem(
                  '存储设置',
                  NewSettingsPageType.storage,
                  isSelected: selectedPage == NewSettingsPageType.storage,
                ),
                _buildMenuItem(
                  '关于小马',
                  NewSettingsPageType.aboutPony,
                  isSelected: selectedPage == NewSettingsPageType.aboutPony,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitIcon(String url) {
    return Image.network(
      url,
      width: 30,
      height: 21,
      fit: BoxFit.contain,
    );
  }

  Widget _buildMenuItem(
    String title, 
    NewSettingsPageType pageType, {
    bool isSelected = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: () => onPageSelected(pageType),
      child: Container(
        width: isSelected ? 296 : 270,
        height: isSelected ? 34 : 20,
        margin: EdgeInsets.only(
          left: isSelected ? 12 : 25,
          bottom: isLast ? 222 : (isSelected ? 13 : 20),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEEEEE) : Colors.transparent,
          borderRadius: isSelected ? BorderRadius.circular(4) : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 13 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(top: isSelected ? 7 : 3),
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    height: 1.43, // 20/14
                  ),
                ),
              ),
              if (!isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Image.network(
                    'https://lanhu-oss-proxy.lanhuapp.com/SketchPng8283a97af2a15e095e15ccef046b66de6ca731371e6cd03272913b62cdf9cd62',
                    width: 14,
                    height: 14,
                    fit: BoxFit.contain,
                  ),
                ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.network(
                    'https://lanhu-oss-proxy.lanhuapp.com/SketchPng8283a97af2a15e095e15ccef046b66de6ca731371e6cd03272913b62cdf9cd62',
                    width: 14,
                    height: 14,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
